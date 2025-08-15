import { EntityType, OperationType, ChangeRequestStatus } from '../types/models';
import { CreateItemRequest, UpdateItemRequest, ItemResponse } from '../types/item';
import { createAuditLog } from './auditService';
import { AppError } from '../middlewares/errorMiddleware';
import * as itemRepo from '../repositories/itemRepository';
import * as crRepo from '../repositories/changeRequestRepository';
import { withTx } from '../repositories/tx';

/**
 * Get all items with optional filters
 */
export const getItems = async (
  name?: string,
  code?: string,
  status?: string,
  limit = 50,
  offset = 0
): Promise<ItemResponse[]> => {
  const where: any = {};

  if (name) {
    where.name = {
      contains: name,
      mode: 'insensitive',
    };
  }

  if (code) {
    where.code = code;
  }

  if (status) {
    where.status = status;
  }

  const items = await itemRepo.findItems({
    name,
    code,
    status,
    limit,
    offset,
  });
  return items;
};

/**
 * Get an item by ID
 */
export const getItemById = async (id: string): Promise<ItemResponse | null> => {
  const item = await itemRepo.findItemById(id);
  return item;
};

/**
 * Create an item directly (for managers)
 */
export const createItem = async (
  data: CreateItemRequest,
  userId: string
): Promise<ItemResponse> => {
  try {
    const existing = await itemRepo.findItemByCode(data.code);
    if (existing) {
      throw new AppError(`An item with this code already exists`, 400);
    }
    const item = await itemRepo.createItem({
      name: data.name,
      description: data.description ?? null,
      unit: data.unit,
      code: data.code,
      status: data.status,
    });

    // Create audit log
    await createAuditLog(
      userId,
      'create',
      'item',
      item.id,
      { item }
    );

    return item;
  } catch (error) {
    // Surface duplicate code constraint errors from the database
    if (error instanceof Error && /items.*code/i.test(error.message)) {
      throw new AppError(`An item with this code already exists`, 400);
    }
    throw error;
  }
};

/**
 * Update an item directly (for managers)
 */
export const updateItem = async (
  id: string,
  data: UpdateItemRequest,
  userId: string
): Promise<ItemResponse> => {
  try {
    // Get the item before update for audit log
    const itemBefore = await itemRepo.findItemById(id);

    if (!itemBefore) {
      throw new Error('Item not found');
    }

    const item = await itemRepo.updateItem(id, data as any);

    // Create audit log
    await createAuditLog(
      userId,
      'update',
      'item',
      item.id,
      { before: itemBefore, after: item }
    );

    return item;
  } catch (error) {
    // Surface duplicate code constraint errors from the database
    if (error instanceof Error && /items.*code/i.test(error.message)) {
      throw new AppError(`An item with this code already exists`, 400);
    }
    throw error;
  }
};

/**
 * Delete an item directly (for managers)
 */
export const deleteItem = async (
  id: string,
  userId: string
): Promise<ItemResponse> => {
  // Get the item before delete for audit log
  const itemBefore = await itemRepo.findItemById(id);

  if (!itemBefore) {
    throw new Error('Item not found');
  }

  const item = await itemRepo.deleteItem(id);

  // Create audit log
  await createAuditLog(
    userId,
    'delete',
    'item',
    item.id,
    { item: itemBefore }
  );

  return item;
};

/**
 * Create a change request for an item (for employees)
 */
export const createItemChangeRequest = async (
  operation: OperationType,
  data: CreateItemRequest | UpdateItemRequest,
  targetId: string | null,
  userId: string
): Promise<any> => {
  const changeRequest = await crRepo.create({
    entity_type: EntityType.ITEM,
    operation,
    payload: data as any,
    target_id: targetId,
    requested_by: userId,
  } as any);
  return changeRequest;
};

/**
 * Execute an item change request after approval
 */
export const executeItemChangeRequest = async (
  changeRequest: any,
  reviewerId: string
): Promise<ItemResponse> => {
  let result;

  // Use a transaction to ensure atomicity
  try {
    result = await withTx(async (client) => {
      switch (changeRequest.operation) {
        case OperationType.CREATE: {
          // Check unique code if provided
          if (changeRequest.payload.code) {
            const { rows: exists } = await client.query(
              'SELECT 1 FROM items WHERE code = $1',
              [changeRequest.payload.code]
            );
            if (exists[0]) {
              throw new AppError(`An item with code ${changeRequest.payload.code} already exists`, 400);
            }
          }

          const payload = changeRequest.payload;
          const { rows } = await client.query(
            `INSERT INTO items (name, description, unit, code, status)
             VALUES ($1,$2,$3,$4,$5)
             RETURNING id, name, description, unit, code, status, created_at, updated_at`,
            [payload.name, payload.description ?? null, payload.unit, payload.code, payload.status]
          );
          const createdItem = rows[0];

          await createAuditLog(
            reviewerId,
            'create_approved',
            'item',
            createdItem.id,
            { item: createdItem, change_request_id: changeRequest.id }
          );
          return createdItem;
        }
        case OperationType.UPDATE: {
          if (!changeRequest.target_id) throw new Error('Target ID is required for update operation');
          const before = await itemRepo.findItemById(changeRequest.target_id);
          if (!before) throw new Error('Item not found');

          if (changeRequest.payload.code && changeRequest.payload.code !== before.code) {
            const { rows: exists } = await client.query(
              'SELECT 1 FROM items WHERE code = $1',
              [changeRequest.payload.code]
            );
            if (exists[0]) {
              throw new AppError(`An item with code ${changeRequest.payload.code} already exists`, 400);
            }
          }

          const updated = await itemRepo.updateItem(changeRequest.target_id, changeRequest.payload);

          await createAuditLog(
            reviewerId,
            'update_approved',
            'item',
            updated.id,
            { before, after: updated, change_request_id: changeRequest.id }
          );
          return updated;
        }
        case OperationType.DELETE: {
          if (!changeRequest.target_id) throw new Error('Target ID is required for delete operation');
          const before = await itemRepo.findItemById(changeRequest.target_id);
          if (!before) throw new Error('Item not found');

          const deleted = await itemRepo.deleteItem(changeRequest.target_id);

          await createAuditLog(
            reviewerId,
            'delete_approved',
            'item',
            deleted.id,
            { item: deleted, change_request_id: changeRequest.id }
          );
          return deleted;
        }
        default:
          throw new Error(`Unsupported operation: ${changeRequest.operation}`);
      }
    });
  } catch (error) {
    throw error;
  }

  return result;
};