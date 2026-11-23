import { Router } from 'express';
import { PaymentController } from '../controllers/payment.controller';

const router = Router();

// Guest checkout endpoints
router.post('/create-order', PaymentController.createOrder);
router.post('/verify', PaymentController.verifyPayment);
router.post('/webhook', PaymentController.handleWebhook);
router.get('/receipt/:contributionId', PaymentController.getReceipt);

export default router;
