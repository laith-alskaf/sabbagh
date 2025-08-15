import { Router } from 'express';
import healthRoutes from './healthRoutes';
import authRoutes from './authRoutes';
import adminRoutes from './adminRoutes';
import i18nRoutes from './i18nRoutes';
import vendorRoutes from './vendorRoutes';
import itemRoutes from './itemRoutes';
import changeRequestRoutes from './changeRequestRoutes';
import auditRoutes from './auditRoutes';
import purchaseOrderRoutes from './purchaseOrderRoutes';
import dashboardRoutes from './dashboardRoutes';
import reportRoutes from './reportRoutes';

const router = Router();

router.use('/health', healthRoutes);
router.use('/auth', authRoutes);
router.use('/admin', adminRoutes);
router.use('/i18n', i18nRoutes);
router.use('/vendors', vendorRoutes);
router.use('/items', itemRoutes);
router.use('/change-requests', changeRequestRoutes);
router.use('/audit-logs', auditRoutes);
router.use('/purchase-orders', purchaseOrderRoutes);
router.use('/dashboard', dashboardRoutes);
router.use('/reports', reportRoutes);

export default router;