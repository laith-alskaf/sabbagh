import { PrismaClient, ChangeRequestStatus, EntityType } from '@prisma/client';
import { ChangeRequestResponse } from '../types/changeRequest';
import { executeVendorChangeRequest } from './vendorService';
import { executeItemChangeRequest } from './itemService';
import { createAuditLog } from './auditService';
import { AppError } from '../middlewares/errorMiddleware';

const prisma = new PrismaClient();

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

  const changeRequests = await prisma.changeRequest.findMany({
    where,
    include: {
      requester: {
        select: {
          name: true,
          email: true,
        },
      },
      reviewer: {
        select: {
          name: true,
          email: true,
        },
      },
    },
    orderBy: {
      created_at: 'desc',
    },
    take: limit,
    skip: offset,
  });

  return changeRequests.map((cr) => ({
    id: cr.id,
    entity_type: cr.entity_type,
    operation: cr.operation,
    payload: cr.payload,
    target_id: cr.target_id,
    status: cr.status,
    requested_by: cr.requested_by,
    requester_name: cr.requester.name,
    requester_email: cr.requester.email,
    reviewed_by: cr.reviewed_by,
    reviewer_name: cr.reviewer?.name,
    reviewer_email: cr.reviewer?.email,
    reviewed_at: cr.reviewed_at,
    reason: cr.reason,
    created_at: cr.created_at,
    updated_at: cr.updated_at,
  }));
};

/**
 * Get a change request by ID
 */
export const getChangeRequestById = async (id: string): Promise<ChangeRequestResponse | null> => {
  const changeRequest = await prisma.changeRequest.findUnique({
    where: { id },
    include: {
      requester: {
        select: {
          name: true,
          email: true,
        },
      },
      reviewer: {
        select: {
          name: true,
          email: true,
        },
      },
    },
  });

  if (!changeRequest) {
    return null;
  }

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
    reviewer_name: changeRequest.reviewer?.name,
    reviewer_email: changeRequest.reviewer?.email,
    reviewed_at: changeRequest.reviewed_at,
    reason: changeRequest.reason,
    created_at: changeRequest.created_at,
    updated_at: changeRequest.updated_at,
  };
};

/**
 * Approve a change request
 */
export const approveChangeRequest = async (
  id: string,
  reviewerId: string
): Promise<ChangeRequestResponse> => {
  // Get the change request
  const changeRequest = await prisma.changeRequest.findUnique({
    where: { id },
  });

  if (!changeRequest) {
    throw new Error('Change request not found');
  }

  if (changeRequest.status !== ChangeRequestStatus.pending) {
    throw new Error(`Change request is already ${changeRequest.status}`);
  }

  let result;

  try {
    // Execute the change request based on entity type
    if (changeRequest.entity_type === EntityType.vendor) {
      result = await executeVendorChangeRequest(changeRequest, reviewerId);
    } else if (changeRequest.entity_type === EntityType.item) {
      result = await executeItemChangeRequest(changeRequest, reviewerId);
    } else {
      throw new Error(`Unsupported entity type: ${changeRequest.entity_type}`);
    }

    // Update the change request status
    const updatedChangeRequest = await prisma.changeRequest.update({
      where: { id },
      data: {
        status: ChangeRequestStatus.approved,
        reviewed_by: reviewerId,
        reviewed_at: new Date(),
      },
      include: {
        requester: {
          select: {
            name: true,
            email: true,
          },
        },
        reviewer: {
          select: {
            name: true,
            email: true,
          },
        },
      },
    });

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

    return {
      id: updatedChangeRequest.id,
      entity_type: updatedChangeRequest.entity_type,
      operation: updatedChangeRequest.operation,
      payload: updatedChangeRequest.payload,
      target_id: updatedChangeRequest.target_id,
      status: updatedChangeRequest.status,
      requested_by: updatedChangeRequest.requested_by,
      requester_name: updatedChangeRequest.requester.name,
      requester_email: updatedChangeRequest.requester.email,
      reviewed_by: updatedChangeRequest.reviewed_by,
      reviewer_name: updatedChangeRequest.reviewer?.name,
      reviewer_email: updatedChangeRequest.reviewer?.email,
      reviewed_at: updatedChangeRequest.reviewed_at,
      reason: updatedChangeRequest.reason,
      created_at: updatedChangeRequest.created_at,
      updated_at: updatedChangeRequest.updated_at,
    };
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
  const changeRequest = await prisma.changeRequest.findUnique({
    where: { id },
  });

  if (!changeRequest) {
    throw new Error('Change request not found');
  }

  if (changeRequest.status !== ChangeRequestStatus.pending) {
    throw new Error(`Change request is already ${changeRequest.status}`);
  }

  // Update the change request status
  const updatedChangeRequest = await prisma.changeRequest.update({
    where: { id },
    data: {
      status: ChangeRequestStatus.rejected,
      reviewed_by: reviewerId,
      reviewed_at: new Date(),
      reason,
    },
    include: {
      requester: {
        select: {
          name: true,
          email: true,
        },
      },
      reviewer: {
        select: {
          name: true,
          email: true,
        },
      },
    },
  });

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

  return {
    id: updatedChangeRequest.id,
    entity_type: updatedChangeRequest.entity_type,
    operation: updatedChangeRequest.operation,
    payload: updatedChangeRequest.payload,
    target_id: updatedChangeRequest.target_id,
    status: updatedChangeRequest.status,
    requested_by: updatedChangeRequest.requested_by,
    requester_name: updatedChangeRequest.requester.name,
    requester_email: updatedChangeRequest.requester.email,
    reviewed_by: updatedChangeRequest.reviewed_by,
    reviewer_name: updatedChangeRequest.reviewer?.name,
    reviewer_email: updatedChangeRequest.reviewer?.email,
    reviewed_at: updatedChangeRequest.reviewed_at,
    reason: updatedChangeRequest.reason,
    created_at: updatedChangeRequest.created_at,
    updated_at: updatedChangeRequest.updated_at,
  };
};