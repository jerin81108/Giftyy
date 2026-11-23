import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import crypto from 'crypto';
import { createApp } from '../app';
import { store } from '../services/store.service';
import { seedDatabase } from '../scripts/seed';
import { config } from '../config';

describe('Razorpay Payment & Webhook Integration Tests', () => {
  let app: any;

  beforeAll(async () => {
    await seedDatabase();
    app = createApp();
  });

  it('GET /health should return 200 and healthy status', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('healthy');
  });

  it('GET /api/weddings/public/aisha-kabir should return public wishlist matching reel', async () => {
    const res = await request(app).get('/api/weddings/public/aisha-kabir');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.wedding.slug).toBe('aisha-kabir');
    expect(res.body.items.length).toBeGreaterThanOrEqual(3);

    const honeymoonItem = res.body.items.find((i: any) => i.title === 'Honeymoon in Europe');
    expect(honeymoonItem).toBeDefined();
    expect(honeymoonItem.targetAmount).toBe(300000);
    expect(honeymoonItem.percentFunded).toBe(72);
  });

  it('POST /api/payments/create-order should generate a valid payment order', async () => {
    const wedding = await store.findWeddingBySlug('aisha-kabir');
    expect(wedding).not.toBeNull();

    const res = await request(app)
      .post('/api/payments/create-order')
      .send({
        weddingId: wedding!._id,
        amount: 2000,
        guestName: 'Anand & Shalini',
        message: 'Wishing you all the joy in the world!',
        isAnonymous: false,
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.order).toBeDefined();
    expect(res.body.order.orderId).toBeDefined();
    expect(res.body.order.amount).toBe(2000);
  });

  it('POST /api/payments/verify should verify signature and fulfill payment', async () => {
    const wedding = await store.findWeddingBySlug('aisha-kabir');
    const items = await store.getWishlistItems(wedding!._id);
    const item = items[0];
    const initialRaised = item.raisedAmount;

    // 1. Create order
    const orderRes = await request(app)
      .post('/api/payments/create-order')
      .send({
        weddingId: wedding!._id,
        itemId: item._id,
        amount: 5000,
        guestName: 'Rohit K.',
        message: 'Have an epic trip!',
      });

    const { orderId } = orderRes.body.order;

    // 2. Verify payment
    const verifyRes = await request(app)
      .post('/api/payments/verify')
      .send({
        orderId,
        paymentId: 'pay_test_' + Date.now(),
        signature: 'valid_mock_signature',
      });

    expect(verifyRes.status).toBe(200);
    expect(verifyRes.body.success).toBe(true);
    expect(verifyRes.body.contribution.status).toBe('paid');

    // 3. Verify item raisedAmount was incremented
    const updatedItem = await store.getWishlistItemById(item._id);
    expect(updatedItem?.raisedAmount).toBe(initialRaised + 5000);
  });

  it('POST /api/payments/webhook should be idempotent (not double count if called twice)', async () => {
    const wedding = await store.findWeddingBySlug('aisha-kabir');

    // 1. Create order
    const orderRes = await request(app)
      .post('/api/payments/create-order')
      .send({
        weddingId: wedding!._id,
        amount: 3000,
        guestName: 'Idempotency Test Guest',
      });

    const { orderId } = orderRes.body.order;

    const webhookPayload = {
      event: 'payment.captured',
      payload: {
        payment: {
          entity: {
            id: 'pay_webhook_unique_123',
            order_id: orderId,
            amount: 300000,
            currency: 'INR',
          },
        },
      },
      mock: true,
    };

    // First webhook call
    const res1 = await request(app)
      .post('/api/payments/webhook')
      .send(webhookPayload);
    expect(res1.status).toBe(200);

    const initialContribution = await store.findContributionByOrderId(orderId);
    expect(initialContribution?.status).toBe('paid');

    // Second webhook call with same order
    const res2 = await request(app)
      .post('/api/payments/webhook')
      .send(webhookPayload);
    expect(res2.status).toBe(200);

    // Contribution should still be paid and wedding totals unchanged
    const contributionAfter = await store.findContributionByOrderId(orderId);
    expect(contributionAfter?.status).toBe('paid');
  });
});
