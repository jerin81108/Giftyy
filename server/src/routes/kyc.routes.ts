import { Router } from 'express';
import { KycController } from '../controllers/kyc.controller';
import { authenticateJwt } from '../middlewares/auth.middleware';

const router = Router();

router.get('/status', authenticateJwt, KycController.getKycStatus);
router.post('/consent', authenticateJwt, KycController.submitConsent);
router.post('/verify-pan', authenticateJwt, KycController.verifyPan);
router.post('/verify-aadhaar', authenticateJwt, KycController.verifyAadhaar);
router.post('/verify-liveness', authenticateJwt, KycController.verifyLiveness);
router.post('/delete-my-data', authenticateJwt, KycController.deleteMyData);

export default router;
