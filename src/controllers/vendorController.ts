import { Request, Response } from 'express';
import { OperationType, UserRole } from '../types/models';
import * as vendorService from '../services/vendorService';
import { CreateVendorRequest, UpdateVendorRequest } from '../types/vendor';
import { AppError, asyncHandler } from '../middlewares/errorMiddleware';
import { t } from '../utils/i18n';

/**
 * Get all vendors
 * GET /vendors
 */
export const getVendors = asyncHandler(async (req: Request, res: Response) => {
  const { name, status, limit, offset } = req.query;
  
  const vendors = await vendorService.getVendors(
    name as string,
    status as string,
    limit ? parseInt(limit as string) : undefined,
    offset ? parseInt(offset as string) : undefined
  );
  
  res.status(200).json({
    success: true,
    count: vendors.length,
    data: vendors,
  });
});

/**
 * Get a vendor by ID
 * GET /vendors/:id
 */
export const getVendorById = asyncHandler(async (req: Request, res: Response) => {
  const { id } = req.params;
  
  const vendor = await vendorService.getVendorById(id);
  
  if (!vendor) {
    throw new AppError(t(req, 'vendor.notFound', { ns: 'errors' }), 404);
  }
  
  res.status(200).json({
    success: true,
    data: vendor,
  });
});

/**
 * Create a vendor
 * POST /vendors
 */
export const createVendor = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }
  
  const vendorData: CreateVendorRequest = req.body;
  
  // Validate required fields
  if (!vendorData.name || !vendorData.contact_person || !vendorData.phone || !vendorData.address || !vendorData.status) {
    throw new AppError(t(req, 'validation.requiredFields', { ns: 'errors' }), 400);
  }
  
  // If user is a manager, create the vendor directly
  if (req.user.role === UserRole.MANAGER) {
    const vendor = await vendorService.createVendor(vendorData, req.user.userId);
    
    res.status(201).json({
      success: true,
      message: t(req, 'vendor.created', { ns: 'common' }),
      data: vendor,
    });
  } 
  // If user is an assistant manager, create a change request
  else if (req.user.role === UserRole.ASSISTANT_MANAGER) {
    const changeRequest = await vendorService.createVendorChangeRequest(
      OperationType.CREATE,
      vendorData,
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
 * Update a vendor
 * PUT /vendors/:id
 */
export const updateVendor = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }
  
  const { id } = req.params;
  const vendorData: UpdateVendorRequest = req.body;
  
  // Check if vendor exists
  const existingVendor = await vendorService.getVendorById(id);
  
  if (!existingVendor) {
    throw new AppError(t(req, 'vendor.notFound', { ns: 'errors' }), 404);
  }
  
  // If user is a manager, update the vendor directly
  if (req.user.role === UserRole.MANAGER) {
    const vendor = await vendorService.updateVendor(id, vendorData, req.user.userId);
    
    res.status(200).json({
      success: true,
      message: t(req, 'vendor.updated', { ns: 'common' }),
      data: vendor,
    });
  } 
  // If user is an assistant manager, create a change request
  else if (req.user.role === UserRole.ASSISTANT_MANAGER) {
    const changeRequest = await vendorService.createVendorChangeRequest(
      OperationType.UPDATE,
      vendorData,
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
 * Delete a vendor
 * DELETE /vendors/:id
 */
export const deleteVendor = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }
  
  const { id } = req.params;
  
  // Check if vendor exists
  const existingVendor = await vendorService.getVendorById(id);
  
  if (!existingVendor) {
    throw new AppError(t(req, 'vendor.notFound', { ns: 'errors' }), 404);
  }
  
  // If user is a manager, delete the vendor directly
  if (req.user.role === UserRole.MANAGER) {
    await vendorService.deleteVendor(id, req.user.userId);
    
    res.status(200).json({
      success: true,
      message: t(req, 'vendor.deleted', { ns: 'common' }),
      data: null,
    });
  } 
  // If user is an assistant manager, create a change request
  else if (req.user.role === UserRole.ASSISTANT_MANAGER) {
    const changeRequest = await vendorService.createVendorChangeRequest(
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