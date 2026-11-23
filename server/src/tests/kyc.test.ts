import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import { createApp } from '../app';
import { store } from '../services/store.service';
import { kycService } from '../services/kyc.service';
import { EncryptionService } from '../services/encryption.service';
import { seedDatabase } from '../scripts/seed';

describe('Giftyy - KYC Identity Verification & Anti-Fraud Tests', () => {
  let app: any;

  beforeAll(async () => {
    await seedDatabase();
    app = createApp();
  });

  it('EncryptionService should mask PAN and Aadhaar in compliance with DPDP & UIDAI', () => {
    const maskedPan = EncryptionService.maskPan('ABCDE1234F');
    expect(maskedPan).toBe('ABCDE****F');

    const maskedAadhaar = EncryptionService.maskAadhaar('123456789012');
    expect(maskedAadhaar).toBe('XXXX-XXXX-9012');
  });

  it('EncryptionService should accurately score name similarity (Penny Drop)', () => {
    const scoreExact = EncryptionService.calculateNameMatch('Aisha Sharma', 'Aisha Sharma');
    expect(scoreExact).toBe(100);

    const scorePartial = EncryptionService.calculateNameMatch('Aisha Kabir Sharma', 'Aisha Sharma');
    expect(scorePartial).toBeGreaterThanOrEqual(70);

    const scoreDifferent = EncryptionService.calculateNameMatch('Aisha Sharma', 'Rohan Gupta');
    expect(scoreDifferent).toBeLessThan(70);
  });

  it('GET /api/weddings/public/pooja-sameer should return 403 because KYC is pending', async () => {
    const res = await request(app).get('/api/weddings/public/pooja-sameer');
    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.isDraft).toBe(true);
  });

  it('GET /api/weddings/public/aisha-kabir should return 200 because host is verified', async () => {
    const res = await request(app).get('/api/weddings/public/aisha-kabir');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.wedding.slug).toBe('aisha-kabir');
  });

  it('PAN verification should prevent duplicate PAN registrations across accounts (Anti-Fraud)', async () => {
    // Aisha already has PAN with last4 1234
    const newUser = await store.createUser({
      phone: '9999988888',
      name: 'Imposter User',
      kycStatus: 'not_started',
    });

    await expect(
      kycService.verifyPan({
        userId: newUser._id,
        panNumber: 'ABCDE1234F', // Duplicate PAN
        fullName: 'Imposter User',
      })
    ).rejects.toThrow('already registered');
  });

  it('POST /api/weddings/report/aisha-kabir should record an abuse report and audit log', async () => {
    const res = await request(app)
      .post('/api/weddings/report/aisha-kabir')
      .send({
        reason: 'Testing anti-fraud reporting mechanism',
        reporterName: 'Vigilant Guest',
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.reportId).toBeDefined();

    const reports = await store.getReports();
    expect(reports.length).toBeGreaterThan(0);
  });
});
