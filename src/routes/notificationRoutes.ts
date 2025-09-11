import { Router } from 'express';
import { authenticateJWT } from '../middlewares/authMiddleware';
import { listMyNotifications, markNotificationRead, markAllNotificationsRead, saveFcmToken, deleteFcmToken, deleteNotification, deleteAllNotifications } from '../controllers/notificationController';

const router = Router();
router.use(authenticateJWT);



/**
 * @swagger
 * /notifications:
 *   get:
 *     summary: Get my notifications
 *     tags:
 *       - Notifications
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 50
 *         description: Max number of items to return
 *       - in: query
 *         name: offset
 *         schema:
 *           type: integer
 *           default: 0
 *         description: Offset for pagination
 *     responses:
 *       200:
 *         description: A list of notifications
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 count:
 *                   type: integer
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id: { type: string }
 *                       type: { type: string }
 *                       title: { type: string }
 *                       body: { type: string, nullable: true }
 *                       data: { type: object, nullable: true }
 *                       is_read: { type: boolean }
 *                       created_at: { type: string, format: date-time }
 */
router.get('/', listMyNotifications);

/**
 * @swagger
 * /notifications/{id}/read:
 *   patch:
 *     summary: Mark a notification as read
 *     tags:
 *       - Notifications
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Status of the operation
 */
router.patch('/:id/read', markNotificationRead);

/**
 * @swagger
 * /notifications/read-all:
 *   patch:
 *     summary: Mark all my notifications as read
 *     tags:
 *       - Notifications
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Count of updated notifications
 */
router.patch('/read-all', markAllNotificationsRead);

/**
 * @swagger
 * /notifications/{id}:
 *   delete:
 *     summary: Delete a notification by id
 *     tags:
 *       - Notifications
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Status of deletion
 */
router.delete('/:id', deleteNotification);

/**
 * @swagger
 * /notifications:
 *   delete:
 *     summary: Delete all my notifications
 *     tags:
 *       - Notifications
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Count of deleted notifications
 */
router.delete('/', deleteAllNotifications);

/**
 * @swagger
 * /notifications/fcm-token:
 *   post:
 *     summary: Save or update my FCM token
 *     tags:
 *       - Notifications
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [token]
 *             properties:
 *               token: { type: string }
 *               device_info: { type: string }
 *     responses:
 *       200:
 *         description: Token saved
 */
router.post('/fcm-token', saveFcmToken);

/**
 * @swagger
 * /notifications/fcm-token:
 *   delete:
 *     summary: Delete my FCM token
 *     tags:
 *       - Notifications
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [token]
 *             properties:
 *               token: { type: string }
 *     responses:
 *       200:
 *         description: Token removed
 */
router.delete('/fcm-token', deleteFcmToken);

export default router;