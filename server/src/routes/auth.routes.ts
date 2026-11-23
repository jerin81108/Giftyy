import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { authenticateJwt } from '../middlewares/auth.middleware';
import { otpRateLimiter } from '../middlewares/rateLimiter';

const router = Router();

router.post('/send-otp', otpRateLimiter, AuthController.sendOtp);
router.post('/verify-otp', AuthController.verifyOtp);
router.post('/firebase-login', AuthController.firebaseLogin);
router.post('/fcm-token', authenticateJwt, AuthController.updateFcmToken);
router.get('/me', authenticateJwt, AuthController.getMe);

export default router;
