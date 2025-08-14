import { Router } from 'express';
import * as itemController from '../controllers/itemController';
import { authenticateJWT } from '../middlewares/authMiddleware';

const router = Router();

// Apply authentication middleware to all routes
router.use(authenticateJWT);

// Get all items
router.get('/', itemController.getItems);

// Get an item by ID
router.get('/:id', itemController.getItemById);

// Create an item
router.post('/', itemController.createItem);

// Update an item
router.put('/:id', itemController.updateItem);

// Delete an item
router.delete('/:id', itemController.deleteItem);

export default router;