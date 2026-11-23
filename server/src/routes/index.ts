import { Router } from 'express';
import authRoutes from './auth.routes';
import roomRoutes from './room.routes';
import weddingRoutes from './wedding.routes';
import wishlistRoutes from './wishlist.routes';
import paymentRoutes from './payment.routes';
import payoutRoutes from './payout.routes';
import adminRoutes from './admin.routes';
import kycRoutes from './kyc.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/kyc', kycRoutes);
router.use('/rooms', roomRoutes);
router.use('/weddings', weddingRoutes);
router.use('/wishlist', wishlistRoutes);
router.use('/payments', paymentRoutes);
router.use('/payouts', payoutRoutes);
router.use('/admin', adminRoutes);

export default router;
