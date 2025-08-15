import { Router, Request, Response } from 'express';
import { authenticateJWT, authorizeRoles } from '../middlewares/authMiddleware';
import { validate, validateQuery, validateParams } from '../validators';
import { createUserSchema, updateUserSchema, userChangePasswordSchema, userQuerySchema, userIdSchema } from '../validators/userValidators';
import { UserRole } from '../types/models';
import * as userController from '../controllers/userController';

const router = Router();

/**
 * @swagger
 * tags:
 *   name: Admin
 *   description: Administrative endpoints (Manager access only)
 */

// Apply authentication and manager authorization to all routes
router.use(authenticateJWT);
router.use(authorizeRoles([UserRole.MANAGER]));

/**
 * @swagger
 * /admin/ping:
 *   get:
 *     summary: Test admin access
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Admin access confirmed
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "Admin ping successful"
 *                 user:
 *                   $ref: '#/components/schemas/User'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/ping', (req: Request, res: Response) => {
  res.status(200).json({ 
    success: true,
    message: 'Admin ping successful',
    user: req.user
  });
});

/**
 * @swagger
 * /admin/users:
 *   get:
 *     summary: Get all users
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           minimum: 1
 *           default: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *           default: 10
 *         description: Number of items per page
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search by name or email
 *       - in: query
 *         name: role
 *         schema:
 *           type: string
 *           enum: [employee, assistant_manager, manager]
 *         description: Filter by user role
 *       - in: query
 *         name: department
 *         schema:
 *           type: string
 *         description: Filter by department
 *       - in: query
 *         name: is_active
 *         schema:
 *           type: boolean
 *         description: Filter by active status
 *       - in: query
 *         name: sort
 *         schema:
 *           type: string
 *           enum: [name, email, role, department, created_at]
 *           default: created_at
 *         description: Sort field
 *       - in: query
 *         name: order
 *         schema:
 *           type: string
 *           enum: [asc, desc]
 *           default: desc
 *         description: Sort order
 *     responses:
 *       200:
 *         description: List of users
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/User'
 *                 pagination:
 *                   $ref: '#/components/schemas/Pagination'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/users', validateQuery(userQuerySchema), userController.getUsers);

/**
 * @swagger
 * /admin/users:
 *   post:
 *     summary: Create a new user
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - email
 *               - password
 *               - role
 *             properties:
 *               name:
 *                 type: string
 *                 minLength: 2
 *                 maxLength: 100
 *                 description: Full name of the user
 *                 example: "Ahmad Al-Sabbagh"
 *               email:
 *                 type: string
 *                 format: email
 *                 maxLength: 255
 *                 description: Email address (must be unique)
 *                 example: "ahmad@sabbagh.com"
 *               password:
 *                 type: string
 *                 minLength: 8
 *                 maxLength: 128
 *                 description: Password (must contain uppercase, lowercase, and number)
 *                 example: "SecurePass123"
 *               role:
 *                 type: string
 *                 enum: [employee, assistant_manager, manager]
 *                 description: User role
 *                 example: "employee"
 *               department:
 *                 type: string
 *                 minLength: 2
 *                 maxLength: 100
 *                 description: Department name
 *                 example: "IT Department"
 *               phone:
 *                 type: string
 *                 pattern: '^[+]?[0-9\\s\\-()]+$'
 *                 description: Phone number
 *                 example: "+963-11-1234567"
 *               is_active:
 *                 type: boolean
 *                 description: Whether the user is active
 *                 default: true
 *                 example: true
 *     responses:
 *       201:
 *         description: User created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "User created successfully"
 *                 data:
 *                   $ref: '#/components/schemas/User'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       409:
 *         description: Email already exists
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: "Email already exists"
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.post('/users', validate(createUserSchema), userController.createUser);

/**
 * @swagger
 * /admin/users/{id}:
 *   get:
 *     summary: Get user by ID
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: User ID
 *     responses:
 *       200:
 *         description: User details
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/User'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/users/:id', validateParams(userIdSchema), userController.getUserById);

/**
 * @swagger
 * /admin/users/{id}:
 *   put:
 *     summary: Update user
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: User ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *                 minLength: 2
 *                 maxLength: 100
 *                 description: Full name of the user
 *                 example: "Ahmad Al-Sabbagh"
 *               email:
 *                 type: string
 *                 format: email
 *                 maxLength: 255
 *                 description: Email address
 *                 example: "ahmad@sabbagh.com"
 *               role:
 *                 type: string
 *                 enum: [employee, assistant_manager, manager]
 *                 description: User role
 *                 example: "assistant_manager"
 *               department:
 *                 type: string
 *                 minLength: 2
 *                 maxLength: 100
 *                 description: Department name
 *                 example: "IT Department"
 *               phone:
 *                 type: string
 *                 pattern: '^[+]?[0-9\\s\\-()]+$'
 *                 description: Phone number
 *                 example: "+963-11-1234567"
 *               is_active:
 *                 type: boolean
 *                 description: Whether the user is active
 *                 example: true
 *     responses:
 *       200:
 *         description: User updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "User updated successfully"
 *                 data:
 *                   $ref: '#/components/schemas/User'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       409:
 *         description: Email already exists
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: "Email already exists"
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.put('/users/:id', validateParams(userIdSchema), validate(updateUserSchema), userController.updateUser);

/**
 * @swagger
 * /admin/users/{id}:
 *   delete:
 *     summary: Delete user (soft delete)
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: User ID
 *     responses:
 *       200:
 *         description: User deleted successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "User deleted successfully"
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       409:
 *         description: Cannot delete yourself or other managers
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: "Cannot delete this user"
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.delete('/users/:id', validateParams(userIdSchema), userController.deleteUser);

/**
 * @swagger
 * /admin/users/{id}/change-password:
 *   post:
 *     summary: Change user password (Admin only)
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: User ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - new_password
 *               - confirm_password
 *             properties:
 *               new_password:
 *                 type: string
 *                 minLength: 8
 *                 maxLength: 128
 *                 description: New password (must contain uppercase, lowercase, and number)
 *                 example: "NewSecurePass123"
 *               confirm_password:
 *                 type: string
 *                 description: Confirm new password
 *                 example: "NewSecurePass123"
 *     responses:
 *       200:
 *         description: Password changed successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "Password changed successfully"
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.post('/users/:id/change-password', 
  validateParams(userIdSchema), 
  validate(userChangePasswordSchema.omit({ current_password: true })), 
  userController.adminChangePassword
);

export default router;