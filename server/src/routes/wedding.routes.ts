import { Router } from 'express';
import { WeddingController } from '../controllers/wedding.controller';
import { ReportController } from '../controllers/report.controller';
import { authenticateJwt } from '../middlewares/auth.middleware';

const router = Router();

// Couple routes (Protected)
router.post('/', authenticateJwt, WeddingController.createWedding);
router.get('/me', authenticateJwt, WeddingController.getMyWedding);
router.put('/me', authenticateJwt, WeddingController.updateWedding);

// Public Guest routes
router.get('/public/:slug', WeddingController.getPublicWeddingBySlug);
router.get('/share/:slug', WeddingController.getShareDetails);
router.get('/invite-pdf/:slug', WeddingController.downloadPdfInvite);
router.post('/report/:slug', ReportController.reportWedding);

export default router;
