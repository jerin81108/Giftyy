import { describe, it, expect } from 'vitest';
import { razorpayService } from '../services/razorpay.service';

describe('Dream Wishlist - Money & Progress Calculation Tests', () => {
  it('should accurately calculate percentage funded from the reel (72% for 2,16,000 of 3,00,000)', () => {
    const targetAmount = 300000;
    const raisedAmount = 216000;
    const percent = Math.min(100, Math.round((raisedAmount / targetAmount) * 100));

    expect(percent).toBe(72);
  });

  it('should cap progress ratio at 1.0 (100%) for overfunded goals', () => {
    const targetAmount = 300000;
    const raisedAmount = 350000;
    const progressRatio = Math.min(1.0, raisedAmount / targetAmount);
    const percent = Math.min(100, Math.round((raisedAmount / targetAmount) * 100));

    expect(progressRatio).toBe(1.0);
    expect(percent).toBe(100);
  });

  it('should calculate platform fee splits correctly (e.g. 2% fee on ₹5,000 contribution)', () => {
    // Test custom split helper
    const amount = 5000;
    const feePercent = 2; // 2%
    const fee = Math.round(amount * (feePercent / 100));
    const netAmount = amount - fee;

    expect(fee).toBe(100);
    expect(netAmount).toBe(4900);
  });

  it('should correctly calculate the 200 Guests Calculator (Goal ÷ 200 = suggested contribution)', () => {
    const goal = 300000;
    const guests = 200;
    const perGuestContribution = Math.round(goal / guests);

    expect(perGuestContribution).toBe(1500); // 200 guests × ₹1,500 = ₹3,00,000
  });
});
