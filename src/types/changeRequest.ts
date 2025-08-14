import { ChangeRequestStatus, EntityType, OperationType } from '@prisma/client';

export interface ChangeRequestResponse {
  id: string;
  entity_type: EntityType;
  operation: OperationType;
  payload: any;
  target_id: string | null;
  status: ChangeRequestStatus;
  requested_by: string;
  requester_name?: string;
  requester_email?: string;
  reviewed_by: string | null;
  reviewer_name?: string;
  reviewer_email?: string;
  reviewed_at: Date | null;
  reason: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface ApproveRejectRequest {
  reason?: string;
}