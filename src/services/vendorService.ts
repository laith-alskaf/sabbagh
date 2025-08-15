import { EntityType, OperationType, ChangeRequestStatus } from '../types/models';
import { CreateVendorRequest, UpdateVendorRequest, VendorResponse } from '../types/vendor';
import { createAuditLog } from './auditService';
import { AppError } from '../middlewares/errorMiddleware';
import * as vendorRepo from '../repositories/vendorRepository';
import * as crRepo from '../repositories/changeRequestRepository';
import { withTx } from '../repositories/tx';

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

  const vendors = await vendorRepo.findVendors({
    name,
    status,
    limit,
    offset,
  });
  return vendors;
};

/**
 * Get a vendor by ID
 */
export const getVendorById = async (id: string): Promise<VendorResponse | null> => {
  const vendor = await vendorRepo.findVendorById(id);
  return vendor;
};

/**
 * Create a vendor directly (for managers)
 */
export const createVendor = async (
  data: CreateVendorRequest,
  userId: string
): Promise<VendorResponse> => {
  const vendor = await vendorRepo.createVendor({
    name: data.name,
    contact_person: data.contact_person,
    phone: data.phone,
    email: data.email ?? null,
    address: data.address,
    notes: data.notes ?? null,
    rating: data.rating ?? null,
    status: data.status,
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
  const vendorBefore = await vendorRepo.findVendorById(id);

  if (!vendorBefore) {
    throw new Error('Vendor not found');
  }

  const vendor = await vendorRepo.updateVendor(id, data as any);

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
  const vendorBefore = await vendorRepo.findVendorById(id);

  if (!vendorBefore) {
    throw new Error('Vendor not found');
  }

  const vendor = await vendorRepo.deleteVendor(id);

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
  const changeRequest = await crRepo.create({
    entity_type: EntityType.VENDOR,
    operation,
    payload: data as any,
    target_id: targetId,
    requested_by: userId,
  } as any);
  return changeRequest;
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
    result = await withTx(async (client) => {
      switch (changeRequest.operation) {
        case OperationType.CREATE: {
          const insertSql = `
            INSERT INTO vendors (name, contact_person, phone, email, address, notes, rating, status)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
            RETURNING id, name, contact_person, phone, email, address, notes, rating, status, created_at, updated_at`;
          const payload = changeRequest.payload;
          const { rows } = await client.query(insertSql, [
            payload.name,
            payload.contact_person,
            payload.phone,
            payload.email ?? null,
            payload.address,
            payload.notes ?? null,
            payload.rating ?? null,
            payload.status,
          ]);
          const createdVendor = rows[0];

          await createAuditLog(
            reviewerId,
            'create_approved',
            'vendor',
            createdVendor.id,
            { vendor: createdVendor, change_request_id: changeRequest.id }
          );
          return createdVendor;
        }
        case OperationType.UPDATE: {
          if (!changeRequest.target_id) throw new Error('Target ID is required for update operation');
          const before = await vendorRepo.findVendorById(changeRequest.target_id);
          if (!before) throw new Error('Vendor not found');

          const updated = await vendorRepo.updateVendor(changeRequest.target_id, changeRequest.payload);

          await createAuditLog(
            reviewerId,
            'update_approved',
            'vendor',
            updated.id,
            { before, after: updated, change_request_id: changeRequest.id }
          );
          return updated;
        }
        case OperationType.DELETE: {
          if (!changeRequest.target_id) throw new Error('Target ID is required for delete operation');
          const before = await vendorRepo.findVendorById(changeRequest.target_id);
          if (!before) throw new Error('Vendor not found');

          const deleted = await vendorRepo.deleteVendor(changeRequest.target_id);

          await createAuditLog(
            reviewerId,
            'delete_approved',
            'vendor',
            deleted.id,
            { vendor: deleted, change_request_id: changeRequest.id }
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