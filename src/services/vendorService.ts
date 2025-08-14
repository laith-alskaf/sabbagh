import { PrismaClient, Prisma, EntityType, OperationType, ChangeRequestStatus, UserRole } from '@prisma/client';
import { CreateVendorRequest, UpdateVendorRequest, VendorResponse } from '../types/vendor';
import { createAuditLog } from './auditService';
import { AppError } from '../middlewares/errorMiddleware';

const prisma = new PrismaClient();

/**
 * Get all vendors with optional filters
 */
export const getVendors = async (
  name?: string,
  status?: string,
  limit = 50,
  offset = 0
): Promise<VendorResponse[]> => {
  const where: any = {};

  if (name) {
    where.name = {
      contains: name,
      mode: 'insensitive',
    };
  }

  if (status) {
    where.status = status;
  }

  const vendors = await prisma.vendor.findMany({
    where,
    orderBy: {
      name: 'asc',
    },
    take: limit,
    skip: offset,
  });

  return vendors;
};

/**
 * Get a vendor by ID
 */
export const getVendorById = async (id: string): Promise<VendorResponse | null> => {
  const vendor = await prisma.vendor.findUnique({
    where: { id },
  });

  return vendor;
};

/**
 * Create a vendor directly (for managers)
 */
export const createVendor = async (
  data: CreateVendorRequest,
  userId: string
): Promise<VendorResponse> => {
  const vendor = await prisma.vendor.create({
    data,
  });

  // Create audit log
  await createAuditLog(
    userId,
    'create',
    'vendor',
    vendor.id,
    { vendor }
  );

  return vendor;
};

/**
 * Update a vendor directly (for managers)
 */
export const updateVendor = async (
  id: string,
  data: UpdateVendorRequest,
  userId: string
): Promise<VendorResponse> => {
  // Get the vendor before update for audit log
  const vendorBefore = await prisma.vendor.findUnique({
    where: { id },
  });

  if (!vendorBefore) {
    throw new Error('Vendor not found');
  }

  const vendor = await prisma.vendor.update({
    where: { id },
    data,
  });

  // Create audit log
  await createAuditLog(
    userId,
    'update',
    'vendor',
    vendor.id,
    { before: vendorBefore, after: vendor }
  );

  return vendor;
};

/**
 * Delete a vendor directly (for managers)
 */
export const deleteVendor = async (
  id: string,
  userId: string
): Promise<VendorResponse> => {
  // Get the vendor before delete for audit log
  const vendorBefore = await prisma.vendor.findUnique({
    where: { id },
  });

  if (!vendorBefore) {
    throw new Error('Vendor not found');
  }

  const vendor = await prisma.vendor.delete({
    where: { id },
  });

  // Create audit log
  await createAuditLog(
    userId,
    'delete',
    'vendor',
    vendor.id,
    { vendor: vendorBefore }
  );

  return vendor;
};

/**
 * Create a change request for a vendor (for employees)
 */
export const createVendorChangeRequest = async (
  operation: OperationType,
  data: CreateVendorRequest | UpdateVendorRequest,
  targetId: string | null,
  userId: string
): Promise<any> => {
  const changeRequest = await prisma.changeRequest.create({
    data: {
      entity_type: EntityType.vendor,
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
 * Execute a vendor change request after approval
 */
export const executeVendorChangeRequest = async (
  changeRequest: any,
  reviewerId: string
): Promise<VendorResponse> => {
  let result;

  // Use a transaction to ensure atomicity
  try {
    result = await prisma.$transaction(async (tx) => {
      switch (changeRequest.operation) {
        case OperationType.create:
          // Create the vendor
          const createdVendor = await tx.vendor.create({
            data: changeRequest.payload,
          });

          // Create audit log
          await createAuditLog(
            reviewerId,
            'create_approved',
            'vendor',
            createdVendor.id,
            { 
              vendor: createdVendor,
              change_request_id: changeRequest.id 
            }
          );

          return createdVendor;

        case OperationType.update:
          if (!changeRequest.target_id) {
            throw new Error('Target ID is required for update operation');
          }

          // Lock the row by selecting it for update
          const vendorToUpdate = await tx.vendor.findUnique({
            where: { id: changeRequest.target_id },
          });

          if (!vendorToUpdate) {
            throw new Error('Vendor not found');
          }

          // Update the vendor
          const updatedVendor = await tx.vendor.update({
            where: { id: changeRequest.target_id },
            data: changeRequest.payload,
          });

          // Create audit log
          await createAuditLog(
            reviewerId,
            'update_approved',
            'vendor',
            updatedVendor.id,
            { 
              before: vendorToUpdate,
              after: updatedVendor,
              change_request_id: changeRequest.id 
            }
          );

          return updatedVendor;

        case OperationType.delete:
          if (!changeRequest.target_id) {
            throw new Error('Target ID is required for delete operation');
          }

          // Lock the row by selecting it for update
          const vendorToDelete = await tx.vendor.findUnique({
            where: { id: changeRequest.target_id },
          });

          if (!vendorToDelete) {
            throw new Error('Vendor not found');
          }

          // Delete the vendor
          const deletedVendor = await tx.vendor.delete({
            where: { id: changeRequest.target_id },
          });

          // Create audit log
          await createAuditLog(
            reviewerId,
            'delete_approved',
            'vendor',
            deletedVendor.id,
            { 
              vendor: deletedVendor,
              change_request_id: changeRequest.id 
            }
          );

          return deletedVendor;

        default:
          throw new Error(`Unsupported operation: ${changeRequest.operation}`);
      }
    });
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError) {
      // Handle unique constraint violations
      if (error.code === 'P2002') {
        throw new AppError(`A vendor with this ${error.meta?.target} already exists`, 400);
      }
    }
    throw error;
  }

  return result;
};