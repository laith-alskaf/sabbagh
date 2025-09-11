import { Request, Response, NextFunction } from 'express';
import * as notesService from '../services/purchaseOrderNotesService';
import { UserRole } from '../types/models';
import { CreatePurchaseOrderNoteRequest } from '../types/notes';

export const addNote = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params as any;
    const user = req.user!;
    const body = req.body as CreatePurchaseOrderNoteRequest;
    const note = await notesService.addNote(id, user.userId, user.role, body);
    res.status(201).json({ success: true, data: note });
  } catch (err) {
    next(err);
  }
};

export const getNotes = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params as any;
    const user = req.user!;
    const notes = await notesService.getNotes(id, user.userId, user.role);
    res.json({ success: true, data: notes });
  } catch (err) {
    next(err);
  }
};