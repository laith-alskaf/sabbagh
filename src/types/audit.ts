export interface AuditLogResponse {
  id: string;
  actor_id: string;
  actor_name?: string;
  actor_email?: string;
  action: string;
  entity_type: string;
  entity_id: string | null;
  details: any;
  created_at: Date;
}