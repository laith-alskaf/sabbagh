import { VendorStatus } from '@prisma/client';

export interface CreateVendorRequest {
  name: string;
  contact_person: string;
  phone: string;
  email?: string;
  address: string;
  notes?: string;
  rating?: number;
  status: VendorStatus;
}

export interface UpdateVendorRequest {
  name?: string;
  contact_person?: string;
  phone?: string;
  email?: string;
  address?: string;
  notes?: string;
  rating?: number;
  status?: VendorStatus;
}

export interface VendorResponse {
  id: string;
  name: string;
  contact_person: string;
  phone: string;
  email: string | null;
  address: string;
  notes: string | null;
  rating: number | null;
  status: VendorStatus;
  created_at: Date;
  updated_at: Date;
}