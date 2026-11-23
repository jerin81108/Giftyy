import { Router } from 'express';
import { AdminController } from '../controllers/admin.controller';
import { authenticateJwt, requireRole } from '../middlewares/auth.middleware';

const router = Router();

// Internal Admin endpoints
router.get('/stats', authenticateJwt, requireRole('admin'), AdminController.getDashboardStats);
router.get('/weddings', authenticateJwt, requireRole('admin'), AdminController.getAllWeddings);
router.get('/contributions', authenticateJwt, requireRole('admin'), AdminController.getAllContributions);
router.get('/audit-logs', authenticateJwt, requireRole('admin'), AdminController.getAuditLogs);
router.get('/reports', authenticateJwt, requireRole('admin'), AdminController.getReports);
router.patch('/weddings/:weddingId/status', authenticateJwt, requireRole('admin'), AdminController.updateWeddingStatus);
router.post('/refund/:contributionId', authenticateJwt, requireRole('admin'), AdminController.refundContribution);

export default router;
