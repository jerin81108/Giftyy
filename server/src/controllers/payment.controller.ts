import { Request, Response } from 'express';
import { z } from 'zod';
import { razorpayService } from '../services/razorpay.service';
import { store } from '../services/store.service';

const createOrderSchema = z.object({
  weddingId: z.string().min(1, 'Wedding ID is required'),
  itemId: z.string().optional(),
  amount: z.number().min(10, 'Contribution must be at least ₹10'),
  guestName: z.string().min(1, 'Guest name is required'),
  guestPhone: z.string().optional(),
  guestEmail: z.string().email().optional().or(z.literal('')),
  message: z.string().max(500).optional(),
  isAnonymous: z.boolean().optional(),
});

const verifyPaymentSchema = z.object({
  orderId: z.string().min(1),
  paymentId: z.string().min(1),
  signature: z.string().min(1),
});

export class PaymentController {
  // 1. Create Razorpay Order
  static async createOrder(req: Request, res: Response): Promise<void> {
    const data = createOrderSchema.parse(req.body);

    const wedding = await store.findWeddingById(data.weddingId);
    if (!wedding) {
      res.status(404).json({ success: false, message: 'Wedding not found' });
      return;
    }

    if (!wedding.kycVerified) {
      res.status(403).json({
        success: false,
        message: 'This wedding cannot accept contributions until the couple completes identity verification (KYC).',
      });
      return;
    }

    if (data.itemId) {
      const item = await store.getWishlistItemById(data.itemId);
      if (!item || item.weddingId !== wedding._id) {
        res.status(404).json({ success: false, message: 'Wishlist item not found' });
        return;
      }
    }

    const orderDetails = await razorpayService.createOrder({
      amount: data.amount,
      weddingId: data.weddingId,
      itemId: data.itemId,
      guestName: data.guestName,
      guestPhone: data.guestPhone,
      guestEmail: data.guestEmail || undefined,
      message: data.message,
      isAnonymous: data.isAnonymous,
    });

    res.json({
      success: true,
      message: 'Razorpay order created',
      order: orderDetails,
    });
  }

  // 2. Client-side payment confirmation & signature verification
  static async verifyPayment(req: Request, res: Response): Promise<void> {
    const { orderId, paymentId, signature } = verifyPaymentSchema.parse(req.body);

    const isValid = razorpayService.verifyPaymentSignature(orderId, paymentId, signature);
    if (!isValid) {
      res.status(400).json({
        success: false,
        message: 'Payment verification failed: invalid signature. Please contact support.',
      });
      return;
    }

    const contribution = await razorpayService.fulfillPayment(orderId, paymentId, signature);
    const wedding = contribution ? await store.findWeddingById(contribution.weddingId || contribution.roomId || '') : null;

    res.json({
      success: true,
      message: 'Payment verified successfully! Thank you for your contribution ✨',
      contribution,
      wedding: wedding ? {
        totalRaised: wedding.totalRaised,
        contributorCount: wedding.contributorCount,
      } : null,
    });
  }

  // 3. Webhook handler (Server-to-Server, Idempotent)
  static async handleWebhook(req: Request, res: Response): Promise<void> {
    const webhookSignature = req.headers['x-razorpay-signature'] as string;
    const rawBody = (req as any).rawBody || JSON.stringify(req.body);

    if (!webhookSignature && !req.body?.mock) {
      res.status(400).json({ success: false, message: 'Missing webhook signature' });
      return;
    }

    if (webhookSignature) {
      const isValid = razorpayService.verifyWebhookSignature(rawBody, webhookSignature);
      if (!isValid) {
        res.status(400).json({ success: false, message: 'Invalid webhook signature' });
        return;
      }
    }

    const event = req.body.event;
    console.log(`[Webhook] Received Razorpay event: ${event}`);

    try {
      if (event === 'payment.captured' || event === 'order.paid') {
        const paymentEntity = req.body.payload?.payment?.entity;
        const orderId = paymentEntity?.order_id || req.body.payload?.order?.entity?.id;
        const paymentId = paymentEntity?.id || 'pay_wh_' + Date.now();

        if (orderId) {
          await razorpayService.fulfillPayment(orderId, paymentId, 'webhook_verified');
          console.log(`[Webhook] Successfully fulfilled contribution for order: ${orderId}`);
        }
      }

      res.status(200).json({ status: 'ok' });
    } catch (error) {
      console.error('[Webhook] Error processing event:', error);
      // Respond with 200 to acknowledge receipt to gateway, log internally
      res.status(200).json({ status: 'error_logged', message: (error as Error).message });
    }
  }

  // 4. Download / View digital receipt
  static async getReceipt(req: Request, res: Response): Promise<void> {
    const contributionId = req.params.contributionId as string;
    const contribution = await store.findContributionById(contributionId);

    if (!contribution || contribution.status !== 'paid') {
      res.status(404).json({ success: false, message: 'Valid paid contribution receipt not found' });
      return;
    }

    const wedding = await store.findWeddingById(contribution.weddingId || contribution.roomId || '');

    res.json({
      success: true,
      receipt: {
        receiptNumber: contribution.receiptNumber,
        date: contribution.createdAt,
        coupleNames: wedding ? `${wedding.partner1Name} & ${wedding.partner2Name}` : 'Couple',
        weddingSlug: wedding?.slug,
        guestName: contribution.guestName,
        amount: contribution.amount,
        itemTitle: contribution.itemTitle || 'General Wedding Fund',
        message: contribution.message,
        paymentId: contribution.paymentId,
        orderId: contribution.orderId,
        status: contribution.status,
      },
    });
  }
}
