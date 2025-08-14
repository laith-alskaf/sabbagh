import { Router } from 'express';
import * as vendorController from '../controllers/vendorController';
import { authenticateJWT } from '../middlewares/authMiddleware';

const router = Router();

// Apply authentication middleware to all routes
router.use(authenticateJWT);

// Get all vendors
router.get('/', vendorController.getVendors);

// Get a vendor by ID
router.get('/:id', vendorController.getVendorById);

// Create a vendor
router.post('/', vendorController.createVendor);

// Update a vendor
router.put('/:id', vendorController.updateVendor);

// Delete a vendor
router.delete('/:id', vendorController.deleteVendor);

export default router;