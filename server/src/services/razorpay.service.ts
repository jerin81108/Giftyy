import crypto from 'crypto';
import Razorpay from 'razorpay';
import { config } from '../config';
import { store } from './store.service';
import { socketService } from './socket.service';
import { firebaseService } from './firebase.service';

export interface ICreateOrderOptions {
  amount: number; // in INR
  weddingId: string;
  itemId?: string;
  guestName: string;
  guestPhone?: string;
  guestEmail?: string;
  message?: string;
  isAnonymous?: boolean;
}

class RazorpayService {
  private rzp: Razorpay | null = null;

  constructor() {
    if (!config.razorpay.mockMode) {
      this.rzp = new Razorpay({
        key_id: config.razorpay.keyId,
        key_secret: config.razorpay.keySecret,
      });
    }
  }

  // Calculate platform fee and net amount
  calculateSplit(amount: number): { platformFee: number; netAmount: number } {
    const fee = Math.round(amount * (config.platformFeePercent / 100));
    return {
      platformFee: fee,
      netAmount: amount - fee,
    };
  }

  // Create Razorpay Order
  async createOrder(options: ICreateOrderOptions) {
    const { amount, weddingId, itemId, guestName, guestPhone, guestEmail, message, isAnonymous } = options;

    const { platformFee, netAmount } = this.calculateSplit(amount);
    const receipt = `dw_${Date.now().toString(36)}`;

    let orderId: string;

    if (config.razorpay.mockMode || !this.rzp) {
      orderId = `order_mock_${Math.random().toString(36).substring(2, 12)}`;
    } else {
      // In paise (1 INR = 100 paise)
      const orderOptions: any = {
        amount: Math.round(amount * 100),
        currency: 'INR',
        receipt,
        notes: {
          weddingId,
          itemId: itemId || 'general',
          guestName,
          isAnonymous: isAnonymous ? 'true' : 'false',
        },
      };

      // If couple has Route linked account and Route transfer is configured
      const wedding = await store.findWeddingById(weddingId);
      if (wedding?.payoutAccountRef) {
        orderOptions.transfers = [
          {
            account: wedding.payoutAccountRef,
            amount: Math.round(netAmount * 100),
            currency: 'INR',
            notes: { weddingId, guestName },
          },
        ];
      }

      const order = await this.rzp.orders.create(orderOptions);
      orderId = order.id;
    }

    // Resolve item title
    let itemTitle = 'General Wedding Fund';
    if (itemId) {
      const item = await store.getWishlistItemById(itemId);
      if (item) itemTitle = item.title;
    }

    // Save pending contribution record in DB
    const contribution = await store.createContribution({
      weddingId,
      itemId,
      itemTitle,
      guestName,
      guestPhone,
      guestEmail,
      amount,
      platformFee,
      netAmount,
      message,
      isAnonymous: !!isAnonymous,
      paymentProvider: config.razorpay.mockMode ? 'mock' : 'razorpay',
      orderId,
      status: 'created',
    });

    return {
      orderId,
      amount,
      currency: 'INR',
      keyId: config.razorpay.keyId,
      contributionId: contribution._id,
      mockMode: config.razorpay.mockMode,
    };
  }

  // Verify client-side checkout signature
  verifyPaymentSignature(orderId: string, paymentId: string, signature: string): boolean {
    if (config.razorpay.mockMode) {
      return true; // Mock mode auto-verifies
    }
    const body = `${orderId}|${paymentId}`;
    const expectedSignature = crypto
      .createHmac('sha256', config.razorpay.keySecret)
      .update(body)
      .digest('hex');
    return expectedSignature === signature;
  }

  // Verify webhook signature from Razorpay
  verifyWebhookSignature(rawBody: string, webhookSignature: string): boolean {
    if (config.razorpay.mockMode) return true;
    const expectedSignature = crypto
      .createHmac('sha256', config.razorpay.webhookSecret)
      .update(rawBody)
      .digest('hex');
    return expectedSignature === webhookSignature;
  }

  // Process successful payment (idempotent)
  async fulfillPayment(orderId: string, paymentId: string, signature?: string) {
    const contribution = await store.findContributionByOrderId(orderId);
    if (!contribution) {
      throw new Error(`Contribution with orderId ${orderId} not found`);
    }

    // Idempotency: if already paid, return existing
    if (contribution.status === 'paid') {
      return contribution;
    }

    // Mark contribution as paid
    const updatedContribution = await store.updateContribution(contribution._id, {
      status: 'paid',
      paymentId,
      signature: signature || 'verified',
    });

    // Update wishlist item if contributed to specific item
    let itemRaisedAmount = 0;
    let itemPercentFunded = 0;

    if (contribution.itemId) {
      const item = await store.getWishlistItemById(contribution.itemId);
      if (item) {
        const newRaised = item.raisedAmount + contribution.amount;
        const newCount = item.contributorCount + 1;
        const newStatus = newRaised >= item.targetAmount ? 'funded' : 'active';

        await store.updateWishlistItem(item._id, {
          raisedAmount: newRaised,
          contributorCount: newCount,
          status: newStatus,
        });

        itemRaisedAmount = newRaised;
        itemPercentFunded = Math.min(100, Math.round((newRaised / item.targetAmount) * 100));
      }
    }

    // Recalculate totals
    const parentId = contribution.weddingId || contribution.roomId || '';
    await store.recalculateWeddingTotals(parentId);
    const wedding = await store.findWeddingById(parentId);

    // Broadcast live event via WebSockets
    if (wedding) {
      socketService.broadcastContribution(wedding._id, {
        contributionId: contribution._id,
        itemId: contribution.itemId,
        guestName: contribution.isAnonymous ? 'Generous Friend' : contribution.guestName,
        amount: contribution.amount,
        message: contribution.message,
        isAnonymous: contribution.isAnonymous,
        weddingTotalRaised: wedding.totalRaised,
        contributorCount: wedding.contributorCount,
        itemRaisedAmount,
        itemPercentFunded,
      });
    }

    // Push notification via Firebase FCM
    try {
      const room = await store.findRoomById(parentId);
      const targetEntity = room || wedding;
      const targetTitle = targetEntity?.title || 'Celebration Room';
      const targetSlug = targetEntity?.slug || '';
      const contributorName = contribution.isAnonymous ? 'A friend' : contribution.guestName;
      const amountStr = `₹${contribution.amount.toLocaleString('en-IN')}`;

      // Send to room topic subscribers
      if (targetSlug) {
        firebaseService.sendTopicNotification(`room_${targetSlug}`, {
          title: `Gift Contribution Received! ✨`,
          body: `${contributorName} contributed ${amountStr} towards ${contribution.itemTitle || 'the celebration fund'}!`,
        }, {
          roomId: parentId,
          amount: String(contribution.amount),
          type: 'contribution',
        }).catch(() => {});
      }

      // Also notify host directly if host has fcmToken
      const hostId = room ? room.hostId : (wedding as any)?.coupleId || null;
      if (hostId) {
        store.findUserById(hostId).then(host => {
          if (host?.fcmToken) {
            firebaseService.sendPushNotification(host.fcmToken, {
              title: `You received a gift for ${targetTitle}! 🎁`,
              body: `${contributorName} sent ${amountStr} ${contribution.message ? `("${contribution.message.slice(0, 50)}")` : ''}`,
            }, {
              roomId: parentId,
              amount: String(contribution.amount),
              type: 'contribution',
            });
          }
        }).catch(() => {});
      }
    } catch (fcmErr) {
      console.warn('FCM payment notification warning:', (fcmErr as Error).message);
    }

    return updatedContribution;
  }
}

export const razorpayService = new RazorpayService();
