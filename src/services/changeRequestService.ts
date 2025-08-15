import { ChangeRequestStatus, EntityType } from '../types/models';
import { ChangeRequestResponse } from '../types/changeRequest';
import { executeVendorChangeRequest } from './vendorService';
import { executeItemChangeRequest } from './itemService';
import { createAuditLog } from './auditService';
import { AppError } from '../middlewares/errorMiddleware';
import * as crRepo from '../repositories/changeRequestRepository';

/**
 * Get all change requests with optional filters
 */
export const getChangeRequests = async (
  status?: ChangeRequestStatus,
  entityType?: EntityType,
  requestedBy?: string,
  limit = 50,
  offset = 0
): Promise<ChangeRequestResponse[]> => {
  const where: any = {};

  if (status) {
    where.status = status;
  }

  if (entityType) {
    where.entity_type = entityType;
  }

  if (requestedBy) {
    where.requested_by = requestedBy;
  }

  const changeRequests = await crRepo.findChangeRequests({
    status,
    entityType,
    requestedBy,
    limit,
    offset,
  });
  return changeRequests;
};

/**
 * Get a change request by ID
 */
export const getChangeRequestById = async (id: string): Promise<ChangeRequestResponse | null> => {
  const changeRequest = await crRepo.findById(id);
  if (!changeRequest) return null;
  return changeRequest;
};

/**
 * Approve a change request
 */
export const approveChangeRequest = async (
  id: string,
  reviewerId: string
): Promise<ChangeRequestResponse> => {
  // Get the change request
  const changeRequest = await crRepo.findById(id);

  if (!changeRequest) {
    throw new Error('Change request not found');
  }

  if (changeRequest.status !== ChangeRequestStatus.PENDING) {
    throw new Error(`Change request is already ${changeRequest.status}`);
  }

  let result;

  try {
    // Execute the change request based on entity type
    if (changeRequest.entity_type === EntityType.VENDOR) {
      result = await executeVendorChangeRequest(changeRequest, reviewerId);
    } else if (changeRequest.entity_type === EntityType.ITEM) {
      result = await executeItemChangeRequest(changeRequest, reviewerId);
    } else {
      throw new Error(`Unsupported entity type: ${changeRequest.entity_type}`);
    }

    // Update the change request status
    const updatedChangeRequest = await crRepo.approve(id, reviewerId);

    // Create audit log for the approval
    await createAuditLog(
      reviewerId,
      'approve_change_request',
      'change_request',
      id,
      {
        change_request: {
          id: updatedChangeRequest.id,
          entity_type: updatedChangeRequest.entity_type,
          operation: updatedChangeRequest.operation,
          target_id: updatedChangeRequest.target_id,
        },
        result,
      }
    );

    return updatedChangeRequest;
  } catch (error) {
    // If there's an error during execution, we don't update the change request status
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(
      `Failed to execute change request: ${error instanceof Error ? error.message : 'Unknown error'}`,
      500
    );
  }
};

/**
 * Reject a change request
 */
export const rejectChangeRequest = async (
  id: string,
  reviewerId: string,
  reason?: string
): Promise<ChangeRequestResponse> => {
  // Get the change request
  const changeRequest = await crRepo.findById(id);

  if (!changeRequest) {
    throw new Error('Change request not found');
  }

  if (changeRequest.status !== ChangeRequestStatus.PENDING) {
    throw new Error(`Change request is already ${changeRequest.status}`);
  }

  // Update the change request status
  const updatedChangeRequest = await crRepo.reject(id, reviewerId, reason);

  // Create audit log for the rejection
  await createAuditLog(
    reviewerId,
    'reject_change_request',
    'change_request',
    id,
    {
      change_request: {
        id: updatedChangeRequest.id,
        entity_type: updatedChangeRequest.entity_type,
        operation: updatedChangeRequest.operation,
        target_id: updatedChangeRequest.target_id,
      },
      reason,
    }
  );

  return updatedChangeRequest;
};