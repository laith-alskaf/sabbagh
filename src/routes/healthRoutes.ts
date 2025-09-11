import { Router } from 'express';
import { getHealth } from '../controllers/healthController';

const router = Router();

/**
 * @swagger
 * tags:
 *   name: Health
 *   description: System health check endpoints
 */

/**
 * @swagger
 * /health:
 *   get:
 *     summary: Check system health status
 *     tags: [Health]
 *     description: Returns the current health status of the API and its dependencies
 *     responses:
 *       200:
 *         description: System is healthy
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: "ok"
 *                 timestamp:
 *                   type: string
 *                   format: date-time
 *                   example: "2024-01-15T10:30:00Z"
 *                 uptime:
 *                   type: number
 *                   description: Server uptime in seconds
 *                   example: 86400
 *                 version:
 *                   type: string
 *                   example: "1.0.0"
 *                 environment:
 *                   type: string
 *                   example: "production"
 *                 database:
 *                   type: object
 *                   properties:
 *                     status:
 *                       type: string
 *                       example: "connected"
 *                     responseTime:
 *                       type: string
 *                       example: "5ms"
 *                 memory:
 *                   type: object
 *                   properties:
 *                     used:
 *                       type: string
 *                       example: "150MB"
 *                     total:
 *                       type: string
 *                       example: "512MB"
 *                     percentage:
 *                       type: number
 *                       format: float
 *                       example: 29.3
 *       503:
 *         description: System is unhealthy
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: "error"
 *                 timestamp:
 *                   type: string
 *                   format: date-time
 *                   example: "2024-01-15T10:30:00Z"
 *                 errors:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       service:
 *                         type: string
 *                         example: "database"
 *                       status:
 *                         type: string
 *                         example: "disconnected"
 *                       message:
 *                         type: string
 *                         example: "Connection timeout"
 */
router.get('/', getHealth);

export default router;