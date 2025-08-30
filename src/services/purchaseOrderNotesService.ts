import { PurchaseOrderStatus, UserRole } from '../types/models';
import { CreatePurchaseOrderNoteRequest, PurchaseOrderNoteResponse } from '../types/notes';
import * as poRepo from '../repositories/purchaseOrderRepository';
import * as notesRepo from '../repositories/purchaseOrderNotesRepository';
import { AppError } from '../middlewares/errorMiddleware';
import { createAuditLog } from './auditService';

function isPoUnderRole(poStatus: PurchaseOrderStatus, role: UserRole): boolean {
  if (role === UserRole.GENERAL_MANAGER) return poStatus === PurchaseOrderStatus.UNDER_GENERAL_MANAGER_REVIEW;
  if (role === UserRole.FINANCE_MANAGER) return poStatus === PurchaseOrderStatus.UNDER_FINANCE_REVIEW;
  return false;
}

function canReadNotes(role: UserRole, poStatus: PurchaseOrderStatus): boolean {
  if (role === UserRole.EMPLOYEE) return false;
  if (role === UserRole.MANAGER || role === UserRole.ASSISTANT_MANAGER) return true;
  if (role === UserRole.GENERAL_MANAGER || role === UserRole.FINANCE_MANAGER) return isPoUnderRole(poStatus, role);
  if (role === UserRole.AUDITOR) return poStatus === PurchaseOrderStatus.COMPLETED;
  return false;
}

function canAddNote(role: UserRole, poStatus: PurchaseOrderStatus): boolean {
  if (role === UserRole.AUDITOR) return poStatus === PurchaseOrderStatus.COMPLETED;
  if (role === UserRole.GENERAL_MANAGER || role === UserRole.FINANCE_MANAGER) return isPoUnderRole(poStatus, role);
  return false;
}

export async function addNote(purchaseOrderId: string, userId: string, role: UserRole, body: CreatePurchaseOrderNoteRequest): Promise<PurchaseOrderNoteResponse> {
  if (!body?.note || typeof body.note !== 'string' || !body.note.trim()) {
    throw new AppError('Note is required', 400);
  }
  const po = await poRepo.getById(purchaseOrderId);
  if (!po) throw new AppError('Purchase order not found', 404);

  if (!canAddNote(role, po.status)) {
    throw new AppError('You do not have permission to add a note for this purchase order', 403);
  }

  const note = await notesRepo.insertNote(purchaseOrderId, userId, body.note.trim());

  await createAuditLog(
    userId,
    'add_purchase_order_note',
    'purchase_order',
    purchaseOrderId,
    { purchase_order: { id: purchaseOrderId, number: po.number, status: po.status }, note: body.note.trim() }
  );

  return note;
}

export async function getNotes(purchaseOrderId: string, userId: string, role: UserRole): Promise<PurchaseOrderNoteResponse[]> {
  const po = await poRepo.getById(purchaseOrderId);
  if (!po) throw new AppError('Purchase order not found', 404);

  if (!canReadNotes(role, po.status)) {
    throw new AppError('You do not have permission to view notes for this purchase order', 403);
  }

  const notes = await notesRepo.listNotes(purchaseOrderId);
  return notes;
}