import { ItemStatus } from '@prisma/client';

export interface CreateItemRequest {
  name: string;
  description?: string;
  unit: string;
  code: string;
  status: ItemStatus;
}

export interface UpdateItemRequest {
  name?: string;
  description?: string;
  unit?: string;
  code?: string;
  status?: ItemStatus;
}

export interface ItemResponse {
  id: string;
  name: string;
  description: string | null;
  unit: string;
  code: string;
  status: ItemStatus;
  created_at: Date;
  updated_at: Date;
}