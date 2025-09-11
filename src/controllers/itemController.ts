import { Request, Response } from 'express';
import { OperationType, UserRole } from '../types/models';
import * as itemService from '../services/itemService';
import { CreateItemRequest, UpdateItemRequest } from '../types/item';
import { AppError, asyncHandler } from '../middlewares/errorMiddleware';
import { t } from '../utils/i18n';

/**
 * Get all items
 * GET /items
 */
export const getItems = asyncHandler(async (req: Request, res: Response) => {
  const { name, code, status, limit, offset, search } = req.query;

  const items = await itemService.getItems(
    name as string,
    code as string,
    status as string,
    limit ? parseInt(limit as string) : undefined,
    offset ? parseInt(offset as string) : undefined
  );

  res.status(200).json({
    success: true,
    count: items.length,
    data: items,
  });
});

/**
 * Get an item by ID
 * GET /items/:id
 */
export const getItemById = asyncHandler(async (req: Request, res: Response) => {
  const { id } = req.params;

  const item = await itemService.getItemById(id);

  if (!item) {
    throw new AppError(t(req, 'item.notFound', { ns: 'errors' }), 404);
  }

  res.status(200).json({
    success: true,
    data: item,
  });
});

/**
 * Create an item
 * POST /items
 */
export const createItem = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  const itemData: CreateItemRequest = req.body;

  // Validate required fields
  if (!itemData.name || !itemData.unit || !itemData.code || !itemData.status) {
    throw new AppError(t(req, 'validation.requiredFields', { ns: 'errors' }), 400);
  }

  // If user is a manager, create the item directly
  if (req.user.role === UserRole.MANAGER) {
    try {
      const item = await itemService.createItem(itemData, req.user.userId);

      res.status(201).json({
        success: true,
        message: t(req, 'item.created', { ns: 'common' }),
        data: item,
      });
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError(
        t(req, 'item.createFailed', { ns: 'errors' }),
        500
      );
    }
  }
  // If user is an assistant manager, create a change request
  else if (req.user.role === UserRole.ASSISTANT_MANAGER) {
    const changeRequest = await itemService.createItemChangeRequest(
      OperationType.CREATE,
      itemData,
      null,
      req.user.userId
    );

    res.status(201).json({
      success: true,
      message: t(req, 'changeRequest.created', { ns: 'common' }),
      data: changeRequest,
    });
  } else {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }
});

/**
 * Update an item
 * PUT /items/:id
 */
export const updateItem = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  const { id } = req.params;
  const itemData: UpdateItemRequest = req.body;

  // Check if item exists
  const existingItem = await itemService.getItemById(id);

  if (!existingItem) {
    throw new AppError(t(req, 'item.notFound', { ns: 'errors' }), 404);
  }

  // If user is a manager, update the item directly
  if (req.user.role === UserRole.MANAGER) {
    try {
      const item = await itemService.updateItem(id, itemData, req.user.userId);

      res.status(200).json({
        success: true,
        message: t(req, 'item.updated', { ns: 'common' }),
        data: item,
      });
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError(
        t(req, 'item.updateFailed', { ns: 'errors' }),
        500
      );
    }
  }
  // If user is an assistant manager, create a change request
  else if (req.user.role === UserRole.ASSISTANT_MANAGER) {
    const changeRequest = await itemService.createItemChangeRequest(
      OperationType.UPDATE,
      itemData,
      id,
      req.user.userId
    );

    res.status(200).json({
      success: true,
      message: t(req, 'changeRequest.created', { ns: 'common' }),
      data: changeRequest,
    });
  } else {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }
});

/**
 * Delete an item
 * DELETE /items/:id
 */
export const deleteItem = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  const { id } = req.params;

  // Check if item exists
  const existingItem = await itemService.getItemById(id);

  if (!existingItem) {
    throw new AppError(t(req, 'item.notFound', { ns: 'errors' }), 404);
  }

  // If user is a manager, delete the item directly
  if (req.user.role === UserRole.MANAGER) {
    await itemService.deleteItem(id, req.user.userId);

    res.status(200).json({
      success: true,
      message: t(req, 'item.deleted', { ns: 'common' }),
      data: null,
    });
  }
  // If user is an assistant manager, create a change request
  else if (req.user.role === UserRole.ASSISTANT_MANAGER) {
    const changeRequest = await itemService.createItemChangeRequest(
      OperationType.DELETE,
      {},
      id,
      req.user.userId
    );

    res.status(200).json({
      success: true,
      message: t(req, 'changeRequest.created', { ns: 'common' }),
      data: changeRequest,
    });
  } else {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }
});