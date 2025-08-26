import { PurchaseOrderStatus, UserRole } from '../types/models';
import { CreatePurchaseOrderRequest, PurchaseOrderResponse, UpdatePurchaseOrderRequest, PurchaseOrderItemResponse } from '../types/purchaseOrder';
import { createAuditLog } from './auditService';
import { AppError } from '../middlewares/errorMiddleware';
import * as poRepo from '../repositories/purchaseOrderRepository';
import { withTx } from '../repositories/tx';
import { NotificationOrchestrator } from './notificationOrchestrator';
import { PurchaseOrderNotifier } from './notif-purchars_order_action';
import { tl } from '../utils/i18n';

/**
 * Generate a unique purchase order number
 */
const generatePurchaseOrderNumber = async (): Promise<string> => {
  const date = new Date();
  const year = date.getFullYear().toString().slice(-2);
  const month = (date.getMonth() + 1).toString().padStart(2, '0');

  // Get the count of purchase orders for this month
  const count = await poRepo.countForMonth(date.getFullYear(), date.getMonth());

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

  // If user is an employee, only show their own purchase orders
  if (userRole === UserRole.EMPLOYEE) {
    where.created_by = userId;
  }

  if (status) {
    where.status = status;
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
    employeeOnly: userRole === UserRole.EMPLOYEE,
    status,
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
  return purchaseOrder;
};

/**
 * Create a purchase order
 */
export const createPurchaseOrder = async (
  data: CreatePurchaseOrderRequest,
  userId: string,
  userRole: UserRole
): Promise<PurchaseOrderResponse> => {
  // Generate a unique purchase order number
  const number = await generatePurchaseOrderNumber();

  // Determine the initial status based on user role
  let initialStatus: PurchaseOrderStatus;

  if (userRole === UserRole.MANAGER) {
    // Managers can create purchase orders directly in progress
    initialStatus = PurchaseOrderStatus.IN_PROGRESS;
  } else if (userRole === UserRole.ASSISTANT_MANAGER) {
    // Assistant managers' orders go to manager review
    initialStatus = PurchaseOrderStatus.UNDER_MANAGER_REVIEW;
  } else {
    // Employee orders go to assistant manager review
    initialStatus = PurchaseOrderStatus.UNDER_ASSISTANT_REVIEW;
  }

  // Create the purchase order with items in a transaction
  const purchaseOrder = await withTx(async (client) => {
    const inserted = await poRepo.insert(
      {
        // id: '', // ignored
        number,
        request_date: data.request_date,
        department: data.department,
        request_type: data.request_type,
        requester_name: data.requester_name,
        status: initialStatus,
        notes: data.notes ?? '',
        supplier_id: data.supplier_id ?? null,
        execution_date: data.execution_date ?? null,
        attachment_url: data.attachment_url ?? null,
        total_amount: data.total_amount ?? null,
        currency: data.currency ?? null,
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
      inserted.id,
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
    await orchestrator.onPurchaseOrderCreated(purchaseOrder);
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
    purchaseOrder.status !== PurchaseOrderStatus.IN_PROGRESS
  ) {
    throw new AppError(tl(language, 'purchaseOrder.updateOnlyDraftOrInProgress', { ns: 'errors' }), 400);
  }
  // Update the purchase order with items in a transaction
  const updatedPurchaseOrder = await withTx(async (client) => {
    const updated = await (await import('../repositories/purchaseOrderMutations')).updateDraft(
      id,
      {
        request_date: data.request_date,
        department: data.department,
        request_type: data.request_type,
        requester_name: data.requester_name,
        notes: data.notes,
        supplier_id: data.supplier_id,
        execution_date: data.execution_date,
        attachment_url: data.attachment_url,
        total_amount: data.total_amount,
        currency: data.currency,
      },
      data.items,
      client
    );

    await createAuditLog(
      userId,
      'update_purchase_order',
      'purchase_order',
      updated.id,
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
  userRole: UserRole
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
      updated.id,
      { purchase_order: { id: updated.id, number: updated.number, status: updated.status } }
    );

    return updated;
  });

  // Notify creator about status change
  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updatedPurchaseOrder, purchaseOrder.status,nextStatus);
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
  userId: string
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
      updated.id,
      { purchase_order: { id: updated.id, number: updated.number, status: updated.status } }
    );

    return updated;
  });

  // Notify creator about status change
  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updatedPurchaseOrder, purchaseOrder.status,PurchaseOrderStatus.UNDER_MANAGER_REVIEW);
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
  reason?: string
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
      updated.id,
      { purchase_order: { id: updated.id, number: updated.number, status: updated.status }, reason }
    );

    return updated;
  });

  // Notify creator about status change
  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updatedPurchaseOrder, purchaseOrder.status,PurchaseOrderStatus.REJECTED_BY_ASSISTANT);
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
  userId: string
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
      PurchaseOrderStatus.IN_PROGRESS,
      undefined,
      client
    );

    await createAuditLog(
      userId,
      'manager_approve_purchase_order',
      'purchase_order',
      updated.id,
      { purchase_order: { id: updated.id, number: updated.number, status: updated.status } }
    );

    return updated;
  });

  // Notify creator about status change
  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updatedPurchaseOrder, purchaseOrder.status,PurchaseOrderStatus.IN_PROGRESS);
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
  reason?: string
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
      updated.id,
      { purchase_order: { id: updated.id, number: updated.number, status: updated.status }, reason }
    );

    return updated;
  });

  // Notify creator about status change
  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updatedPurchaseOrder, purchaseOrder.status,PurchaseOrderStatus.REJECTED_BY_MANAGER);
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
  userId: string
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
      updated.id,
      { purchase_order: { id: updated.id, number: updated.number, status: updated.status } }
    );

    return updated;
  });

  // Notify creator about status change
  try {
    const orchestrator = new NotificationOrchestrator(new PurchaseOrderNotifier());
    await orchestrator.onStatusChanged(updatedPurchaseOrder, purchaseOrder.status,PurchaseOrderStatus.COMPLETED);
  } catch (e) {
    console.error('Notification error on completePurchaseOrder:', e);
  }

  return updatedPurchaseOrder;
};