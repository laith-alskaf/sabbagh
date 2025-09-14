import { PurchaseOrderStatus, UserRole } from '../types/models';
import { CreatePurchaseOrderRequest, PurchaseOrderResponse, UpdatePurchaseOrderRequest, PurchaseOrderItemResponse, AttachmentInfo } from '../types/purchaseOrder';
import { createAuditLog, getAuditLogs } from './auditService';
import { AppError } from '../middlewares/errorMiddleware';
import * as poRepo from '../repositories/purchaseOrderRepository';
import * as userRepo from '../repositories/userRepository';
import { withTx } from '../repositories/tx';
import { NotificationOrchestrator } from './notificationOrchestrator';
import { PurchaseOrderNotifier } from './notif-purchars_order_action';
import { tl } from '../utils/i18n';
import { handlerExtractImage } from '../utils/handle-extract-image';
import { Request } from "express";
import { CloudImageService } from './cloud-image.service';
/**
 * Generate a unique purchase order number
 */
const generatePurchaseOrderNumber = async (): Promise<string> => {
  const damascusDate = new Date().toLocaleString("en-US", { timeZone: "Asia/Damascus" });
  const date = new Date(damascusDate);
  const year = date.getUTCFullYear().toString().slice(-2);
  const month = (date.getUTCMonth() + 1).toString().padStart(2, '0');

  // Get the count of purchase orders for this month
  const count = await poRepo.countForMonth(date.getUTCFullYear(), date.getUTCMonth());

  // Generate the number in format: PO-YY-MM-XXXX
  const sequence = (count + 1).toString().padStart(4, '0');
  return `PO-${year}-${month}-${sequence}`;
};

/**
 * Map a purchase order to a response object
 */
const mapPurchaseOrderToResponse = async (
  purchaseOrder: any & {
    items: PurchaseOrderItemResponse[];
    creator: { name: string; email: string };
    supplier?: { name: string } | null;
  }
): Promise<PurchaseOrderResponse> => {
  return {
    id: purchaseOrder.id,
    number: purchaseOrder.number,
    request_date: purchaseOrder.request_date,
    department: purchaseOrder.department,
    request_type: purchaseOrder.request_type,
    requester_name: purchaseOrder.requester_name,
    status: purchaseOrder.status,
    notes: purchaseOrder.notes,
    supplier_id: purchaseOrder.supplier_id,
    supplier_name: purchaseOrder.supplier?.name || null,
    execution_date: purchaseOrder.execution_date,
    attachment_url: purchaseOrder.attachment_url,
    total_amount: purchaseOrder.total_amount,
    currency: purchaseOrder.currency,
    created_by: purchaseOrder.created_by,
    creator_name: purchaseOrder.creator.name,
    creator_email: purchaseOrder.creator.email,
    created_at: purchaseOrder.created_at,
    updated_at: purchaseOrder.updated_at,
    items: purchaseOrder.items.map((item: PurchaseOrderItemResponse) => ({
      id: item.id,
      purchase_order_id: item.purchase_order_id,
      item_id: item.item_id,
      item_code: item.item_code,
      item_name: item.item_name,
      quantity: item.quantity,
      unit: item.unit,
      received_quantity: item.received_quantity,
      price: item.price,
      line_total: item.line_total,
      currency: item.currency,
    })),
  };
};

/**
 * Get all purchase orders with optional filters
 */
export const getPurchaseOrders = async (
  userId: string,
  userRole: UserRole,
  status?: PurchaseOrderStatus,
  supplier_id?: string,
  department?: string,
  start_date?: Date,
  end_date?: Date,
  limit = 50,
  offset = 0
): Promise<PurchaseOrderResponse[]> => {
  const where: any = {};
  var underMe: PurchaseOrderStatus | null = null;
  if (userRole === UserRole.EMPLOYEE || userRole === UserRole.FINANCE_MANAGER || userRole === UserRole.GENERAL_MANAGER || userRole === UserRole.PROCUREMENT_OFFICER) {
    where.created_by = userId;
  }
  if (userRole === UserRole.FINANCE_MANAGER) {
    underMe = PurchaseOrderStatus.UNDER_FINANCE_REVIEW
  }
  if (userRole === UserRole.GENERAL_MANAGER) {
    underMe = PurchaseOrderStatus.UNDER_GENERAL_MANAGER_REVIEW
  }
  if (userRole === UserRole.PROCUREMENT_OFFICER) {
    underMe = PurchaseOrderStatus.PENDING_PROCUREMENT;
  }
  if (status) {
    status = status;
  }

  if (supplier_id) {
    where.supplier_id = supplier_id;
  }

  if (department) {
    where.department = department;
  }

  if (start_date && end_date) {
    where.request_date = {
      gte: start_date,
      lte: end_date,
    };
  } else if (start_date) {
    where.request_date = {
      gte: start_date,
    };
  } else if (end_date) {
    where.request_date = {
      lte: end_date,
    };
  }

  const purchaseOrders = await poRepo.list({
    userId,
    employeeOnly: true,
    status,
    under_me: underMe,
    supplier_id,
    department,
    start_date,
    end_date,
    limit,
    offset,
  });
  return purchaseOrders;
};

/**
 * Get purchase orders pending assistant manager review
 */
export const getPurchaseOrdersPendingAssistantReview = async (
  limit = 50,
  offset = 0
): Promise<PurchaseOrderResponse[]> => {
  const purchaseOrders = await poRepo.list({
    status: PurchaseOrderStatus.UNDER_ASSISTANT_REVIEW,
    limit,
    offset,
  });
  return purchaseOrders;
};

/**
 * Get purchase orders pending manager review
 */
export const getPurchaseOrdersPendingManagerReview = async (
  limit = 50,
  offset = 0
): Promise<PurchaseOrderResponse[]> => {
  const purchaseOrders = await poRepo.list({
    status: PurchaseOrderStatus.UNDER_MANAGER_REVIEW,
    limit,
    offset,
  });
  return purchaseOrders;
};

const CLOUD_FOLDER_PO = 'purchase-orders';

function extractFromUrl(url: string, folderName: string = CLOUD_FOLDER_PO): { userId?: string; uuid?: string; uploadedAt?: Date } {
  try {
    const segments = url.split('/').filter(Boolean);
    const folderIdx = segments.findIndex(s => s === folderName);
    const vSeg = segments.find(s => /^v\d+$/.test(s));
    const uploadedAt = vSeg ? new Date(parseInt(vSeg.slice(1), 10) * 1000) : undefined;
    if (folderIdx >= 0) {
      const userId = segments[folderIdx + 1];
      const uuid = segments[folderIdx + 2];
      return { userId, uuid, uploadedAt };
    }
    return { uploadedAt };
  } catch {
    return {};
  }
}

async function buildAttachments(po: PurchaseOrderResponse): Promise<AttachmentInfo[]> {
  const urls = po.attachment_url ?? [];
  const parsed = urls.map(url => ({ url, ...extractFromUrl(url) }));
  const uniqueUserIds = Array.from(new Set(parsed.map(p => p.userId).filter(Boolean))) as string[];
  const users = await Promise.all(uniqueUserIds.map(id => userRepo.findById(id)));
  const byId = new Map<string, { name?: string }>();
  uniqueUserIds.forEach((id, i) => byId.set(id, { name: users[i]?.name }));
  const attachments: AttachmentInfo[] = parsed.map(p => ({
    url: p.url,
    user_id: p.userId,
    user_name: p.userId ? byId.get(p.userId)?.name : undefined,
    uploaded_at: p.uploadedAt,
  }));
  return attachments;
}

async function filterAttachmentsByRole(attachments: AttachmentInfo[], po: PurchaseOrderResponse, currentUserId: string, role: UserRole): Promise<AttachmentInfo[]> {
  // Managers, assistants, general manager see all
  if (role === UserRole.MANAGER || role === UserRole.ASSISTANT_MANAGER || role === UserRole.GENERAL_MANAGER || role === UserRole.FINANCE_MANAGER) {
    return attachments;
  }
  if (role === UserRole.PROCUREMENT_OFFICER) {
    // Find when the PO was routed to procurement
    const logs = await getAuditLogs('purchase_order', po.id);
    const routed = logs
      .filter(l => l.action === 'route_purchase_order' && l.details?.to_status === 'pending_procurement')
      .sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime())[0];
    const routedAt = routed ? new Date(routed.created_at) : undefined;
    return attachments.filter(a => {
      const isOwn = a.user_id === currentUserId;
      if (!routedAt) return isOwn || true; // if no route time, default allow
      if (!a.uploaded_at) return isOwn;    // no timestamp, only allow own
      return a.uploaded_at <= routedAt || isOwn;
    });
  }
  // Employees and others: default to only their own attachments
  return attachments.filter(a => a.user_id === currentUserId);
}

/**
 * Get a purchase order by ID
 */
export const getPurchaseOrderById = async (
  id: string,
  userId: string,
  userRole: UserRole
): Promise<PurchaseOrderResponse | null> => {
  const where: any = { id };

  // If user is an employee, only allow access to their own purchase orders
  if (userRole === UserRole.EMPLOYEE) {
    where.created_by = userId;
  }

  const purchaseOrder = await poRepo.getById(id, userRole === UserRole.EMPLOYEE ? { userId } : undefined);
  if (!purchaseOrder) return null;

  const allAttachments = await buildAttachments(purchaseOrder);
  const visibleAttachments = await filterAttachmentsByRole(allAttachments, purchaseOrder, userId, userRole);
  return { ...purchaseOrder, attachments: visibleAttachments };
};

/**
 * Get workflow (timeline) for a completed Purchase Order
 */
export const getPurchaseOrderWorkflow = async (
  id: string
): Promise<Array<{
  action: string;
  step: string;
  status: 'approved' | 'rejected' | 'pending' | 'routed' | 'updated' | 'created' | 'completed';
  actor: { id: string; name?: string; email?: string };
  timestamp: Date;
  details?: Record<string, any> | null;
}>> => {
  const po = await poRepo.getById(id);
  if (!po) throw new Error('Purchase order not found');
  if (po.status !== PurchaseOrderStatus.COMPLETED) {
    throw new AppError('Workflow is available only for completed purchase orders', 400);
  }

  const logs = await getAuditLogs('purchase_order', po.number);
  // Order ascending (oldest first)
  const ordered = logs.sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());

  const mapActionToStep = (action: string, details?: any): { step: string; status: 'approved' | 'rejected' | 'pending' | 'routed' | 'updated' | 'created' | 'completed' } => {
    switch (action) {
      case 'create_purchase_order':
        return { step: 'created', status: 'created' };
      case 'submit_purchase_order':
        return { step: 'submitted', status: 'pending' };
      case 'assistant_approve_purchase_order':
        return { step: 'assistant_review', status: 'approved' };
      case 'assistant_reject_purchase_order':
        return { step: 'assistant_review', status: 'rejected' };
      case 'manager_approve_purchase_order':
        return { step: 'manager_review', status: 'approved' };
      case 'manager_reject_purchase_order':
        return { step: 'manager_review', status: 'rejected' };
      case 'gm_approve_purchase_order':
        return { step: 'general_manager_review', status: 'approved' };
      case 'gm_reject_purchase_order':
        return { step: 'general_manager_review', status: 'rejected' };
      case 'finance_approve_purchase_order':
        return { step: 'finance_review', status: 'approved' };
      case 'finance_reject_purchase_order':
        return { step: 'finance_review', status: 'rejected' };
      case 'route_purchase_order':
        if (details?.to_status === 'pending_procurement') {
          return { step: 'routed_to_procurement', status: 'routed' };
        }
        return { step: 'routed', status: 'routed' };
      case 'procurement_update_purchase_order':
        return { step: 'procurement_update', status: 'updated' };
      case 'complete_purchase_order':
        return { step: 'completed', status: 'completed' };
      default:
        return { step: action, status: 'updated' };
    }
  };

  return ordered.map(l => {
    const mapped = mapActionToStep(l.action, l.details);
    return {
      action: l.action,
      step: mapped.step,
      status: mapped.status,
      actor: { id: l.actor_id, name: l.actor_name, email: l.actor_email },
      timestamp: l.created_at,
      details: l.details ?? null,
    };
  });
};

/**
 * Create a purchase order
 */
export const createPurchaseOrder = async (
  req: Request,
  data: CreatePurchaseOrderRequest,
  userId: string,
  userRole: UserRole,
  language: string = 'ar'
): Promise<PurchaseOrderResponse> => {
  // Generate a unique purchase order number
  const number = await generatePurchaseOrderNumber();

  // Determine the initial status based on user role
  let initialStatus: PurchaseOrderStatus;

  if (userRole === UserRole.MANAGER) {
    // Managers can create purchase orders directly in progress
    initialStatus = PurchaseOrderStatus.UNDER_MANAGER_REVIEW;
  } else if (userRole === UserRole.ASSISTANT_MANAGER) {
    // Assistant managers' orders go to manager review
    initialStatus = PurchaseOrderStatus.UNDER_MANAGER_REVIEW;
  } else {
    // Employee orders go to assistant manager review
    initialStatus = PurchaseOrderStatus.UNDER_ASSISTANT_REVIEW;
  }
  const uploudImageService = new CloudImageService();
  const urlsImages = await handlerExtractImage({
    req: req,
    uuid: number,
    folderName: 'purchase-orders',
    userId: userId,
    uploadToCloudinary: uploudImageService
  });

  const itemsWithTotals = data.items.map((item) => {
    const price = item.price ?? 0;
    const quantity = item.quantity ?? 0;
    // في بعض الحالات قد تكون line_total مُقدّماً، إذا كان موجوداً استخدمه؛ وإلا احسبه
    const lineTotalFromItem = item.line_total != null ? item.line_total : price * quantity;
    item.line_total = lineTotalFromItem;
    return {
      ...item,
      price: price,
      quantity: quantity,
      line_total: lineTotalFromItem,
    };
  });

  // ثم اجمع جميع line_totals للحصول على total_amount النهائي
  const totalAmountCalculated = itemsWithTotals.reduce((acc, cur) => acc + (Number(cur.line_total) || 0), 0);
  // Create the purchase order with items in a transaction
  const purchaseOrder = await withTx(async (client) => {
    const inserted = await poRepo.insert(
      {
        number,
        request_date: data.request_date,
        department: data.department,
        request_type: data.request_type,
        requester_name: data.requester_name,
        status: initialStatus,
        notes: data.notes ?? '',
        supplier_id: data.supplier_id ?? null,
        execution_date: data.execution_date ?? null,
        attachment_url: urlsImages ?? null,
        total_amount: totalAmountCalculated ?? data.total_amount,
        currency: data.currency ?? 'USD',
        created_by: userId,
      } as any,
      data.items.map((item) => ({
        id: '', // ignored
        purchase_order_id: null, // set in repo
        item_id: item.item_id ?? null,
        item_code: item.item_code ?? null,
        item_name: item.item_name,
        quantity: item.quantity,
        unit: item.unit,
        received_quantity: item.received_quantity ?? null,
        price: item.price ?? null,
        line_total: item.line_total ?? null,
        currency: item.currency ?? null,
      })) as any,
      client
    );

    await createAuditLog(
      userId,
      'create_purchase_order',
      'purchase_order',
      inserted.number,
      {
        purchase_order: { id: inserted.id, number: inserted.number, status: inserted.status },
        items_count: inserted.items.length,
      }
    );

    return inserted;
  });

  // Notify assistant & manager about new PO
  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onPurchaseOrderCreated(purchaseOrder, language);
  } catch (e) {
    console.error('Notification error on createPurchaseOrder:', e);
  }

  return purchaseOrder;
};

/**
 * Update a purchase order
 * Only draft purchase orders can be updated
 */
export const updatePurchaseOrder = async (
  req: Request,
  id: string,
  data: UpdatePurchaseOrderRequest,
  userId: string,
  userRole: UserRole,
  language: string = 'ar'
): Promise<PurchaseOrderResponse> => {
  // Get the purchase order
  const purchaseOrder = await poRepo.getById(id);

  if (!purchaseOrder) {
    throw new Error('Purchase order not found');
  }

  // Check if the user has permission to update this purchase order
  if (userRole === UserRole.EMPLOYEE && purchaseOrder.created_by !== userId) {
    throw new AppError('You do not have permission to update this purchase order', 403);
  }

  // Only draft and IN_PROGRESS purchase orders can be updated
  if (
    purchaseOrder.status !== PurchaseOrderStatus.DRAFT &&
    purchaseOrder.status !== PurchaseOrderStatus.IN_PROGRESS &&
    purchaseOrder.status !== PurchaseOrderStatus.UNDER_ASSISTANT_REVIEW &&
    purchaseOrder.status !== PurchaseOrderStatus.UNDER_MANAGER_REVIEW &&
    purchaseOrder.status !== PurchaseOrderStatus.RETURNED_TO_MANAGER_REVIEW
  ) {
    throw new AppError(tl(language, 'purchaseOrder.updateOnlyDraftOrInProgress', { ns: 'errors' }), 400);
  }


  const uploudImageService = new CloudImageService();
  var urlsImages = await handlerExtractImage({
    req: req,
    uuid: purchaseOrder.number,
    folderName: 'purchase-orders',
    userId: userId,
    uploadToCloudinary: uploudImageService
  });
  if (urlsImages && urlsImages.length > 0) {
    if (purchaseOrder.attachment_url && purchaseOrder.attachment_url.length > 0) {
      urlsImages = urlsImages.concat(purchaseOrder.attachment_url);
    }
  }

  let computedTotalAmount: number | null = null;
  if (data.items != null && data.items.length > 0) {
    const itemsWithTotals = data.items.map((item) => {
      const price = item.price ?? 0;
      const quantity = item.quantity ?? 0;
      // في بعض الحالات قد تكون line_total مُقدّماً، إذا كان موجوداً استخدمه؛ وإلا احسبه
      const lineTotalFromItem = item.line_total != null ? item.line_total : price * quantity;
      item.line_total = lineTotalFromItem;
      return {
        ...item,
        price: price,
        quantity: quantity,
        line_total: lineTotalFromItem,
      };
    });
    computedTotalAmount = itemsWithTotals.reduce((acc, cur) => acc + (cur.line_total || 0), 0);

  }

  // Update the purchase order with items in a transaction
  const updatedPurchaseOrder = await withTx(async (client) => {
    const updated = await (await import('../repositories/purchaseOrderMutations')).updateDraft(
      id,
      {
        request_date: data.request_date ?? purchaseOrder.request_date,
        department: data.department ?? purchaseOrder.department,
        request_type: data.request_type ?? purchaseOrder.request_type,
        requester_name: data.requester_name ?? purchaseOrder.requester_name,
        notes: data.notes ?? purchaseOrder.notes,
        supplier_id: data.supplier_id ?? purchaseOrder.supplier_id,
        execution_date: data.execution_date,
        attachment_url: urlsImages ?? purchaseOrder.attachment_url,
        total_amount: computedTotalAmount ?? data.total_amount ?? purchaseOrder.total_amount,
        currency: data.currency ?? purchaseOrder.currency ?? 'USD',
      },
      data.items,
      client
    );

    await createAuditLog(
      userId,
      'update_purchase_order',
      'purchase_order',
      purchaseOrder.number,
      {
        purchase_order: { id: updated.id, number: updated.number, status: updated.status },
        items_count: updated.items.length,
      }
    );

    return updated;
  });

  if (!updatedPurchaseOrder) {
    throw new Error('Failed to update purchase order');
  }

  return updatedPurchaseOrder;
};

/**
 * Submit a draft purchase order for review
 */
export const submitPurchaseOrder = async (
  id: string,
  userId: string,
  userRole: UserRole,
  language: string = 'ar'
): Promise<PurchaseOrderResponse> => {
  // Get the purchase order
  const purchaseOrder = await poRepo.getById(id);

  if (!purchaseOrder) {
    throw new Error('Purchase order not found');
  }

  if (userRole === UserRole.EMPLOYEE && purchaseOrder.created_by !== userId) {
    throw new AppError('You do not have permission to submit this purchase order', 403);
  }

  if (purchaseOrder.status !== PurchaseOrderStatus.DRAFT) {
    throw new AppError('Only draft purchase orders can be submitted', 400);
  }

  let nextStatus: PurchaseOrderStatus;
  if (userRole === UserRole.MANAGER) nextStatus = PurchaseOrderStatus.IN_PROGRESS;
  else if (userRole === UserRole.ASSISTANT_MANAGER) nextStatus = PurchaseOrderStatus.UNDER_MANAGER_REVIEW;
  else nextStatus = PurchaseOrderStatus.UNDER_ASSISTANT_REVIEW;

  const updatedPurchaseOrder = await withTx(async (client) => {
    const updated = await (await import('../repositories/purchaseOrderMutations')).updateStatus(
      id,
      nextStatus,
      undefined,
      client
    );

    await createAuditLog(
      userId,
      'submit_purchase_order',
      'purchase_order',
      purchaseOrder.number,
      { purchase_order: { id: updated.id, number: updated.number, status: updated.status } }
    );

    return updated;
  });

  // Notify creator about status change
  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updatedPurchaseOrder, purchaseOrder.status, nextStatus, language);
  } catch (e) {
    console.error('Notification error on submitPurchaseOrder:', e);
  }

  return updatedPurchaseOrder;
};

/**
 * Assistant manager approves a purchase order
 */
export const assistantApprove = async (
  id: string,
  userId: string,
  language: string = 'ar'

): Promise<PurchaseOrderResponse> => {
  // Get the purchase order
  const purchaseOrder = await poRepo.getById(id);
  if (!purchaseOrder) throw new Error('Purchase order not found');
  if (purchaseOrder.status !== PurchaseOrderStatus.UNDER_ASSISTANT_REVIEW) {
    throw new AppError('Only purchase orders under assistant review can be approved', 400);
  }

  const updatedPurchaseOrder = await withTx(async (client) => {
    const updated = await (await import('../repositories/purchaseOrderMutations')).updateStatus(
      id,
      PurchaseOrderStatus.UNDER_MANAGER_REVIEW,
      undefined,
      client
    );

    await createAuditLog(
      userId,
      'assistant_approve_purchase_order',
      'purchase_order',
      updated.number,
      { purchase_order: { id: updated.id, number: updated.number, status: updated.status } }
    );

    return updated;
  });

  // Notify creator about status change
  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updatedPurchaseOrder, purchaseOrder.status, PurchaseOrderStatus.UNDER_MANAGER_REVIEW, language);
  } catch (e) {
    console.error('Notification error on assistantApprove:', e);
  }

  return updatedPurchaseOrder;
};

/**
 * Assistant manager rejects a purchase order
 */
export const assistantReject = async (
  id: string,
  userId: string,
  reason?: string,
  language: string = 'ar'
): Promise<PurchaseOrderResponse> => {
  // Get the purchase order
  const purchaseOrder = await poRepo.getById(id);
  if (!purchaseOrder) throw new Error('Purchase order not found');
  if (purchaseOrder.status !== PurchaseOrderStatus.UNDER_ASSISTANT_REVIEW) {
    throw new AppError('Only purchase orders under assistant review can be rejected', 400);
  }

  const updatedPurchaseOrder = await withTx(async (client) => {
    const updated = await (await import('../repositories/purchaseOrderMutations')).updateStatus(
      id,
      PurchaseOrderStatus.REJECTED_BY_ASSISTANT,
      { notesAppend: reason ? `Rejection reason: ${reason}` : undefined },
      client
    );

    await createAuditLog(
      userId,
      'assistant_reject_purchase_order',
      'purchase_order',
      updated.number,
      { purchase_order: { id: updated.id, number: updated.number, status: updated.status }, reason }
    );

    return updated;
  });

  // Notify creator about status change
  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updatedPurchaseOrder, purchaseOrder.status, PurchaseOrderStatus.REJECTED_BY_ASSISTANT, language);
  } catch (e) {
    console.error('Notification error on assistantReject:', e);
  }

  return updatedPurchaseOrder;
};

/**
 * Manager approves a purchase order
 */
export const managerApprove = async (
  id: string,
  userId: string,
  language: string = 'ar'
): Promise<PurchaseOrderResponse> => {
  // Get the purchase order
  const purchaseOrder = await poRepo.getById(id);
  if (!purchaseOrder) throw new Error('Purchase order not found');
  if (purchaseOrder.status !== PurchaseOrderStatus.UNDER_MANAGER_REVIEW) {
    throw new AppError('Only purchase orders under manager review can be approved', 400);
  }

  const updatedPurchaseOrder = await withTx(async (client) => {
    const updated = await (await import('../repositories/purchaseOrderMutations')).updateStatus(
      id,
      PurchaseOrderStatus.COMPLETED,
      undefined,
      client
    );

    await createAuditLog(
      userId,
      'manager_approve_purchase_order',
      'purchase_order',
      updated.number,
      { purchase_order: { id: updated.id, number: updated.number, status: updated.status } }
    );

    return updated;
  });

  // Notify creator about status change
  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updatedPurchaseOrder, purchaseOrder.status, PurchaseOrderStatus.IN_PROGRESS, language);
  } catch (e) {
    console.error('Notification error on managerApprove:', e);
  }

  return updatedPurchaseOrder;
};

/**
 * Manager rejects a purchase order
 */
export const managerReject = async (
  id: string,
  userId: string,
  reason?: string,
  language: string = 'ar'
): Promise<PurchaseOrderResponse> => {
  // Get the purchase order
  const purchaseOrder = await poRepo.getById(id);
  if (!purchaseOrder) throw new Error('Purchase order not found');
  if (purchaseOrder.status !== PurchaseOrderStatus.UNDER_MANAGER_REVIEW) {
    throw new AppError('purchaseOrder.notUnderManagerReview', 400);
  }

  const updatedPurchaseOrder = await withTx(async (client) => {
    const updated = await (await import('../repositories/purchaseOrderMutations')).updateStatus(
      id,
      PurchaseOrderStatus.REJECTED_BY_MANAGER,
      { notesAppend: reason ? `Rejection reason: ${reason}` : undefined },
      client
    );

    await createAuditLog(
      userId,
      'manager_reject_purchase_order',
      'purchase_order',
      purchaseOrder.number,
      { purchase_order: { id: updated.id, number: updated.number, status: updated.status }, reason }
    );

    return updated;
  });

  // Notify creator about status change
  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updatedPurchaseOrder, purchaseOrder.status, PurchaseOrderStatus.REJECTED_BY_MANAGER, language);
  } catch (e) {
    console.error('Notification error on managerReject:', e);
  }

  return updatedPurchaseOrder;
};

/**
 * Mark a purchase order as completed
 * Only managers can mark a purchase order as completed
 */
export const completePurchaseOrder = async (
  id: string,
  userId: string,
  language: string = 'ar'
): Promise<PurchaseOrderResponse> => {
  const purchaseOrder = await poRepo.getById(id);
  if (!purchaseOrder) throw new Error('Purchase order not found');

  if (purchaseOrder.status !== PurchaseOrderStatus.IN_PROGRESS) {
    throw new AppError('Only in-progress purchase orders can be completed', 400);
  }

  const updatedPurchaseOrder = await withTx(async (client) => {
    const updated = await (await import('../repositories/purchaseOrderMutations')).updateStatus(
      id,
      PurchaseOrderStatus.COMPLETED,
      undefined,
      client
    );

    await createAuditLog(
      userId,
      'complete_purchase_order',
      'purchase_order',
      purchaseOrder.number,
      { purchase_order: { id: updated.id, number: updated.number, status: updated.status } }
    );

    return updated;
  });

  // Notify creator about status change
  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updatedPurchaseOrder, purchaseOrder.status, PurchaseOrderStatus.COMPLETED, language);
  } catch (e) {
    console.error('Notification error on completePurchaseOrder:', e);
  }

  return updatedPurchaseOrder;
};

/**
 * Route purchase order to Finance, GM, or Procurement
 */
export const routePurchaseOrder = async (
  id: string,
  userId: string,
  userRole: UserRole,
  next: 'finance' | 'gm' | 'procurement',
  notes?: string,
  language: string = 'ar'
): Promise<PurchaseOrderResponse> => {
  const po = await poRepo.getById(id);
  if (!po) throw new Error('Purchase order not found');

  // Manager can route when under manager review
  const canManager = userRole === UserRole.MANAGER && po.status === PurchaseOrderStatus.UNDER_MANAGER_REVIEW;
  if (!canManager) {
    throw new AppError('Invalid state for routing', 400);
  }

  const previous = po.status;
  let to: PurchaseOrderStatus;
  if (next === 'finance') to = PurchaseOrderStatus.UNDER_FINANCE_REVIEW;
  else if (next === 'gm') to = PurchaseOrderStatus.UNDER_GENERAL_MANAGER_REVIEW;
  else to = PurchaseOrderStatus.PENDING_PROCUREMENT;

  const updated = await withTx(async (client) => {
    const res = await (await import('../repositories/purchaseOrderMutations')).updateStatus(
      id,
      to,
      { notesAppend: notes },
      client
    );
    await createAuditLog(userId, 'route_purchase_order', 'purchase_order', po.number, {
      from_status: previous,
      to_status: to,
      next,
      notes: notes ?? null,
    });
    return res;
  });

  // Notifications
  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updated, previous, to, language);
  } catch (e) {
    console.error('Notification error on routePurchaseOrder:', e);
  }

  return updated;
};

/**
 * Finance Manager approve
 */
export const financeApprove = async (
  id: string,
  userId: string,
  language: string = 'ar'
): Promise<PurchaseOrderResponse> => {
  const po = await poRepo.getById(id);
  if (!po) throw new Error('Purchase order not found');
  if (po.status !== PurchaseOrderStatus.UNDER_FINANCE_REVIEW) throw new AppError('Not under finance review', 400);

  const previous = po.status;
  const to = PurchaseOrderStatus.UNDER_MANAGER_REVIEW;

  const updated = await withTx(async (client) => {
    const res = await (await import('../repositories/purchaseOrderMutations')).updateStatus(id, to, undefined, client);
    await createAuditLog(userId, 'finance_approve_purchase_order', 'purchase_order', po.number, { from_status: previous, to_status: to });
    return res;
  });

  try {

    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updated, previous, to, language);

  } catch (e) {
    console.error('Notification error on financeApprove:', e);
  }

  return updated;
};

export const financeReject = async (
  id: string,
  userId: string,
  reason?: string,
  language: string = 'ar'
): Promise<PurchaseOrderResponse> => {
  const po = await poRepo.getById(id);
  if (!po) throw new Error('Purchase order not found');
  if (po.status !== PurchaseOrderStatus.UNDER_FINANCE_REVIEW) throw new AppError('Not under finance review', 400);

  const previous = po.status;
  const to = PurchaseOrderStatus.REJECTED_BY_FINANCE;

  const updated = await withTx(async (client) => {
    const res = await (await import('../repositories/purchaseOrderMutations')).updateStatus(id, to, { notesAppend: reason }, client);
    await createAuditLog(userId, 'finance_reject_purchase_order', 'purchase_order', po.number, { from_status: previous, to_status: to, reason });
    return res;
  });

  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updated, previous, to, language);
  } catch (e) {
    console.error('Notification error on financeReject:', e);
  }

  return updated;
};

/**
 * General Manager approve/reject
 */
export const generalManagerApprove = async (
  id: string,
  userId: string,
  language: string = 'ar'
): Promise<PurchaseOrderResponse> => {
  const po = await poRepo.getById(id);
  if (!po) throw new Error('Purchase order not found');
  if (po.status !== PurchaseOrderStatus.UNDER_GENERAL_MANAGER_REVIEW) throw new AppError('Not under general manager review', 400);

  const previous = po.status;
  const to = PurchaseOrderStatus.UNDER_MANAGER_REVIEW;

  const updated = await withTx(async (client) => {
    const res = await (await import('../repositories/purchaseOrderMutations')).updateStatus(id, to, undefined, client);
    await createAuditLog(userId, 'gm_approve_purchase_order', 'purchase_order', po.number, { from_status: previous, to_status: to });
    return res;
  });

  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updated, previous, to, language);
  } catch (e) {
    console.error('Notification error on generalManagerApprove:', e);
  }

  return updated;
};

export const generalManagerReject = async (
  id: string,
  userId: string,
  reason?: string,
  language: string = 'ar'
): Promise<PurchaseOrderResponse> => {
  const po = await poRepo.getById(id);
  if (!po) throw new Error('Purchase order not found');
  if (po.status !== PurchaseOrderStatus.UNDER_GENERAL_MANAGER_REVIEW) throw new AppError('Not under general manager review', 400);

  const previous = po.status;
  const to = PurchaseOrderStatus.REJECTED_BY_GENERAL_MANAGER;

  const updated = await withTx(async (client) => {
    const res = await (await import('../repositories/purchaseOrderMutations')).updateStatus(id, to, { notesAppend: reason }, client);
    await createAuditLog(userId, 'gm_reject_purchase_order', 'purchase_order', po.number, { from_status: previous, to_status: to, reason });
    return res;
  });

  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updated, previous, to, language);
  } catch (e) {
    console.error('Notification error on generalManagerReject:', e);
  }

  return updated;
};

/**
 * Procurement updates execution fields and optionally moves to IN_PROGRESS
 */
export const procurementUpdate = async (
  req: Request,
  id: string,
  userId: string,
  body: { items: Array<{ id?: string; received_quantity?: number | null; price?: number | null; line_total?: number | null; supplier_name?: string | null; }> },
  language: string = 'ar'
): Promise<PurchaseOrderResponse> => {
  const po = await poRepo.getById(id);
  if (!po) throw new Error('Purchase order not found');

  if (po.status !== PurchaseOrderStatus.PENDING_PROCUREMENT && po.status !== PurchaseOrderStatus.IN_PROGRESS) {
    throw new AppError('Invalid state for procurement update', 400);
  }

  const uploudImageService = new CloudImageService();
  var urlsImages = await handlerExtractImage({
    req: req,
    uuid: po.number,
    folderName: 'purchase-orders',
    userId: userId,
    uploadToCloudinary: uploudImageService
  });
  if (urlsImages && urlsImages.length > 0) {
    if (po.attachment_url && po.attachment_url.length > 0) {
      urlsImages = urlsImages.concat(po.attachment_url);
    }
  }

  let computedTotalAmount: number | null = null;
  if (body.items != null && body.items.length > 0) {
    const itemsWithTotals = body.items.map((item) => {
      const price = item.price ?? 0;
      const receivedQuantity = item.received_quantity ?? 0;
      // في بعض الحالات قد تكون line_total مُقدّماً، إذا كان موجوداً استخدمه؛ وإلا احسبه
      const lineTotalFromItem = item.line_total != null ? item.line_total : price * receivedQuantity;
      item.line_total = lineTotalFromItem;
      return {
        ...item,
        price: price,
        received_quantity: receivedQuantity,
        line_total: lineTotalFromItem,
      };
    });
    computedTotalAmount = itemsWithTotals.reduce((acc, cur) => acc + (cur.line_total || 0), 0);

  }
  // Merge item updates onto existing items
  const updatesById = new Map<string, { received_quantity?: number | null; price?: number | null; line_total?: number | null; supplier_name?: string | null; }>();
  for (const it of body.items || []) {
    if (it.id) updatesById.set(it.id, { received_quantity: it.received_quantity, price: it.price, line_total: it.line_total, supplier_name: it.supplier_name });
  }

  const mergedItems = (po.items || []).map((item) => {
    const upd = item.id ? updatesById.get(item.id) : undefined;
    return {
      id: item.id,
      item_id: item.item_id ?? null,
      item_code: item.item_code ?? null,
      item_name: item.item_name ?? null,
      quantity: item.quantity,
      supplier_name: upd?.supplier_name ?? po.supplier_name ?? null,
      unit: item.unit,
      received_quantity: upd?.received_quantity ?? item.received_quantity ?? null,
      price: upd?.price ?? item.price ?? null,
      line_total: upd?.line_total ?? item.line_total ?? null,
      currency: po.currency ?? item.currency ?? "USD",
    } as any;
  });

  const previous = po.status;
  const nextStatus = po.status === PurchaseOrderStatus.PENDING_PROCUREMENT ? PurchaseOrderStatus.UNDER_MANAGER_REVIEW : po.status;

  const updated = await withTx(async (client) => {
    // Update attachment and items using existing draft updater (works for core fields)
    const res = await (await import('../repositories/purchaseOrderMutations')).updateDraft(
      id,
      {
        attachment_url: urlsImages ?? po.attachment_url,
        total_amount: computedTotalAmount ?? po.total_amount
      } as any,
      mergedItems,
      client
    );
    // If status needs to move to IN_PROGRESS, do it now
    const finalRes = nextStatus !== previous
      ? await (await import('../repositories/purchaseOrderMutations')).updateStatus(id, nextStatus, undefined, client)
      : res;

    await createAuditLog(userId, 'procurement_update_purchase_order', 'purchase_order', po.number, {
      from_status: previous,
      to_status: finalRes.status,
      items_updated: body.items?.length ?? 0,
    });

    return finalRes;
  });

  try {
    if (nextStatus !== previous) {
      const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
      await orchestrator.onStatusChanged(updated, previous, nextStatus, language);
    }
  } catch (e) {
    console.error('Notification error on procurementUpdate:', e);
  }

  return updated;
};

export const returnToManagerForFinalReview = async (
  id: string,
  userId: string,
  language: string = 'ar'
): Promise<PurchaseOrderResponse> => {
  const po = await poRepo.getById(id);
  if (!po) throw new Error('Purchase order not found');
  if (po.status !== PurchaseOrderStatus.IN_PROGRESS && po.status !== PurchaseOrderStatus.PENDING_PROCUREMENT) {
    throw new AppError('Invalid state for returning to manager', 400);
  }

  const previous = po.status;
  const to = PurchaseOrderStatus.RETURNED_TO_MANAGER_REVIEW;

  const updated = await withTx(async (client) => {
    const res = await (await import('../repositories/purchaseOrderMutations')).updateStatus(id, to, undefined, client);
    await createAuditLog(userId, 'return_to_manager_for_final_review', 'purchase_order', po.number, { from_status: previous, to_status: to });
    return res;
  });

  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updated, previous, to, language);
  } catch (e) {
    console.error('Notification error on returnToManagerForFinalReview:', e);
  }

  return updated;
};

export const managerFinalApprove = async (
  id: string,
  userId: string,
  language: string = 'ar'
): Promise<PurchaseOrderResponse> => {
  const po = await poRepo.getById(id);
  if (!po) throw new Error('Purchase order not found');
  if (po.status !== PurchaseOrderStatus.RETURNED_TO_MANAGER_REVIEW) {
    throw new AppError('Invalid state for final approve', 400);
  }

  const previous = po.status;
  const to = PurchaseOrderStatus.COMPLETED;

  const updated = await withTx(async (client) => {
    const res = await (await import('../repositories/purchaseOrderMutations')).updateStatus(id, to, undefined, client);
    await createAuditLog(userId, 'manager_final_approve_purchase_order', 'purchase_order', po.number, { from_status: previous, to_status: to });
    return res;
  });

  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updated, previous, to, language);
  } catch (e) {
    console.error('Notification error on managerFinalApprove:', e);
  }

  return updated;
};

export const managerFinalReject = async (
  id: string,
  userId: string,
  reason?: string,
  language: string = 'ar'
): Promise<PurchaseOrderResponse> => {
  const po = await poRepo.getById(id);
  if (!po) throw new Error('Purchase order not found');
  if (po.status !== PurchaseOrderStatus.RETURNED_TO_MANAGER_REVIEW) {
    throw new AppError('Invalid state for final reject', 400);
  }

  const previous = po.status;
  const to = PurchaseOrderStatus.REJECTED_BY_MANAGER;

  const updated = await withTx(async (client) => {
    const res = await (await import('../repositories/purchaseOrderMutations')).updateStatus(id, to, { notesAppend: reason }, client);
    await createAuditLog(userId, 'manager_final_reject_purchase_order', 'purchase_order', po.number, { from_status: previous, to_status: to, reason });
    return res;
  });

  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updated, previous, to, language);
  } catch (e) {
    console.error('Notification error on managerFinalReject:', e);
  }

  return updated;
};