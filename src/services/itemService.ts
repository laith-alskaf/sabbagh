import { PrismaClient, Prisma, EntityType, OperationType, ChangeRequestStatus, UserRole } from '@prisma/client';
import { CreateItemRequest, UpdateItemRequest, ItemResponse } from '../types/item';
import { createAuditLog } from './auditService';
import { AppError } from '../middlewares/errorMiddleware';

const prisma = new PrismaClient();

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

  const items = await prisma.item.findMany({
    where,
    orderBy: {
      name: 'asc',
    },
    take: limit,
    skip: offset,
  });

  return items;
};

/**
 * Get an item by ID
 */
export const getItemById = async (id: string): Promise<ItemResponse | null> => {
  const item = await prisma.item.findUnique({
    where: { id },
  });

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
    const item = await prisma.item.create({
      data,
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
    if (error instanceof Prisma.PrismaClientKnownRequestError) {
      // Handle unique constraint violations
      if (error.code === 'P2002') {
        throw new AppError(`An item with this code already exists`, 400);
      }
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
    const itemBefore = await prisma.item.findUnique({
      where: { id },
    });

    if (!itemBefore) {
      throw new Error('Item not found');
    }

    const item = await prisma.item.update({
      where: { id },
      data,
    });

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
    if (error instanceof Prisma.PrismaClientKnownRequestError) {
      // Handle unique constraint violations
      if (error.code === 'P2002') {
        throw new AppError(`An item with this code already exists`, 400);
      }
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
  const itemBefore = await prisma.item.findUnique({
    where: { id },
  });

  if (!itemBefore) {
    throw new Error('Item not found');
  }

  const item = await prisma.item.delete({
    where: { id },
  });

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
  const changeRequest = await prisma.changeRequest.create({
    data: {
      entity_type: EntityType.item,
      operation,
      payload: data as any,
      target_id: targetId,
      status: ChangeRequestStatus.pending,
      requested_by: userId,
    },
    include: {
      requester: {
        select: {
          name: true,
          email: true,
        },
      },
    },
  });

  return {
    id: changeRequest.id,
    entity_type: changeRequest.entity_type,
    operation: changeRequest.operation,
    payload: changeRequest.payload,
    target_id: changeRequest.target_id,
    status: changeRequest.status,
    requested_by: changeRequest.requested_by,
    requester_name: changeRequest.requester.name,
    requester_email: changeRequest.requester.email,
    reviewed_by: changeRequest.reviewed_by,
    reviewed_at: changeRequest.reviewed_at,
    reason: changeRequest.reason,
    created_at: changeRequest.created_at,
    updated_at: changeRequest.updated_at,
  };
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
    result = await prisma.$transaction(async (tx) => {
      switch (changeRequest.operation) {
        case OperationType.create:
          // Check if an item with the same code already exists
          if (changeRequest.payload.code) {
            const existingItem = await tx.item.findUnique({
              where: { code: changeRequest.payload.code },
            });

            if (existingItem) {
              throw new AppError(`An item with code ${changeRequest.payload.code} already exists`, 400);
            }
          }

          // Create the item
          const createdItem = await tx.item.create({
            data: changeRequest.payload,
          });

          // Create audit log
          await createAuditLog(
            reviewerId,
            'create_approved',
            'item',
            createdItem.id,
            { 
              item: createdItem,
              change_request_id: changeRequest.id 
            }
          );

          return createdItem;

        case OperationType.update:
          if (!changeRequest.target_id) {
            throw new Error('Target ID is required for update operation');
          }

          // Lock the row by selecting it for update
          const itemToUpdate = await tx.item.findUnique({
            where: { id: changeRequest.target_id },
          });

          if (!itemToUpdate) {
            throw new Error('Item not found');
          }

          // Check if code is being updated and if it's unique
          if (changeRequest.payload.code && changeRequest.payload.code !== itemToUpdate.code) {
            const existingItem = await tx.item.findUnique({
              where: { code: changeRequest.payload.code },
            });

            if (existingItem) {
              throw new AppError(`An item with code ${changeRequest.payload.code} already exists`, 400);
            }
          }

          // Update the item
          const updatedItem = await tx.item.update({
            where: { id: changeRequest.target_id },
            data: changeRequest.payload,
          });

          // Create audit log
          await createAuditLog(
            reviewerId,
            'update_approved',
            'item',
            updatedItem.id,
            { 
              before: itemToUpdate,
              after: updatedItem,
              change_request_id: changeRequest.id 
            }
          );

          return updatedItem;

        case OperationType.delete:
          if (!changeRequest.target_id) {
            throw new Error('Target ID is required for delete operation');
          }

          // Lock the row by selecting it for update
          const itemToDelete = await tx.item.findUnique({
            where: { id: changeRequest.target_id },
          });

          if (!itemToDelete) {
            throw new Error('Item not found');
          }

          // Delete the item
          const deletedItem = await tx.item.delete({
            where: { id: changeRequest.target_id },
          });

          // Create audit log
          await createAuditLog(
            reviewerId,
            'delete_approved',
            'item',
            deletedItem.id,
            { 
              item: deletedItem,
              change_request_id: changeRequest.id 
            }
          );

          return deletedItem;

        default:
          throw new Error(`Unsupported operation: ${changeRequest.operation}`);
      }
    });
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError) {
      // Handle unique constraint violations
      if (error.code === 'P2002') {
        throw new AppError(`An item with this code already exists`, 400);
      }
    }
    throw error;
  }

  return result;
};