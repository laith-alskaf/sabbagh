import { Request, Response } from 'express';
import { asyncHandler, AppError } from '../middlewares/errorMiddleware';
import * as notifRepo from '../repositories/notificationRepository';
import * as fcmRepo from '../repositories/fcmTokenRepository';


export const listMyNotifications = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) throw new AppError('Unauthorized', 401);
  const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 50;
  const offset = req.query.offset ? parseInt(req.query.offset as string, 10) : 0;
  const items = await notifRepo.list(req.user.userId, limit, offset);
  res.status(200).json({ success: true, count: items.length, data: items });
});


export const markNotificationRead = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) throw new AppError('Unauthorized', 401);
  const { id } = req.params;
  const ok = await notifRepo.markRead(req.user.userId, id);
  res.status(200).json({ success: ok });
});


export const markAllNotificationsRead = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) throw new AppError('Unauthorized', 401);
  const n = await notifRepo.markAllRead(req.user.userId);
  res.status(200).json({ success: true, updated: n });
});


export const saveFcmToken = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) throw new AppError('Unauthorized', 401);
  const { token, device_info } = req.body as { token?: string; device_info?: string };
  if (!token) throw new AppError('token is required', 400);
  await fcmRepo.upsertToken({ userId: req.user.userId, token, deviceInfo: device_info });
  res.status(200).json({ success: true });
});


export const deleteFcmToken = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) throw new AppError('Unauthorized', 401);
  const { token } = req.body as { token?: string };
  if (!token) throw new AppError('token is required', 400);
  await fcmRepo.removeToken(req.user.userId, token);
  res.status(200).json({ success: true });
});


export const deleteNotification = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) throw new AppError('Unauthorized', 401);
  const { id } = req.params;
  const ok = await notifRepo.remove(req.user.userId, id);
  res.status(200).json({ success: ok });
});


export const deleteAllNotifications = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) throw new AppError('Unauthorized', 401);
  const n = await notifRepo.removeAll(req.user.userId);
  res.status(200).json({ success: true, deleted: n });
});