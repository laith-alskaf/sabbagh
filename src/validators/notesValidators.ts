import { z } from 'zod';

export const createPurchaseOrderNoteSchema = z.object({
  note: z.string().min(1, 'Note is required').max(4000, 'Note is too long')
});