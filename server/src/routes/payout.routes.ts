import { Router } from 'express';
import { PayoutController } from '../controllers/payout.controller';
import { authenticateJwt } from '../middlewares/auth.middleware';

const router = Router();

router.post('/bank-details', authenticateJwt, PayoutController.saveBankDetails);
router.post('/request', authenticateJwt, PayoutController.requestPayout);
router.get('/', authenticateJwt, PayoutController.getPayouts);

export default router;
