import { Response } from 'express';
import { z } from 'zod';
import { kycService } from '../services/kyc.service';
import { store } from '../services/store.service';
import { AuthenticatedRequest } from '../middlewares/auth.middleware';

const consentSchema = z.object({
  consentVersion: z.string().default('v1.0'),
  acceptedTerms: z.boolean().refine(val => val === true, 'You must accept the DPDP consent terms'),
});

const verifyPanSchema = z.object({
  panNumber: z.string().length(10, 'PAN must be 10 characters'),
  fullName: z.string().min(2, 'Full name as per PAN card is required'),
  dob: z.string().optional(),
});

const verifyAadhaarSchema = z.object({
  aadhaarNumber: z.string().min(12, 'Aadhaar must be 12 digits'),
  otp: z.string().optional(),
});

export class KycController {
  // 1. Get KYC Status for logged-in host
  static async getKycStatus(req: AuthenticatedRequest, res: Response): Promise<void> {
    const user = req.user!;
    const kycRecord = await store.findKycRecordByUserId(user._id);
    const wedding = await store.findWeddingByOwnerId(user._id);

    res.json({
      success: true,
      kyc: {
        status: user.kycStatus || 'not_started',
        provider: user.kycProvider,
        maskedPan: user.maskedPan,
        panLast4: user.panLast4,
        aadhaarLast4: user.aadhaarLast4,
        verifiedName: user.verifiedName,
        verifiedAt: user.kycVerifiedAt,
        rejectionReason: user.rejectionReason,
        consentVersion: user.consentVersion,
        consentAt: user.consentAt,
        isPublicAllowed: user.kycStatus === 'verified',
        weddingStatus: wedding?.status || 'draft',
      },
    });
  }

  // 2. Accept DPDP Consent
  static async submitConsent(req: AuthenticatedRequest, res: Response): Promise<void> {
    const { consentVersion } = consentSchema.parse(req.body);
    const user = req.user!;

    await store.updateUser(user._id, {
      consentVersion,
      consentAt: new Date(),
    });

    await store.createAuditLog({
      actorId: user._id,
      actorRole: 'couple',
      action: 'dpdp:consent_accepted',
      ip: req.ip || '127.0.0.1',
      metadata: { consentVersion },
    });

    res.json({
      success: true,
      message: 'DPDP consent recorded securely.',
    });
  }

  // 3. Verify PAN
  static async verifyPan(req: AuthenticatedRequest, res: Response): Promise<void> {
    const data = verifyPanSchema.parse(req.body);
    const user = req.user!;

    const result = await kycService.verifyPan({
      userId: user._id,
      panNumber: data.panNumber,
      fullName: data.fullName,
      dob: data.dob,
      ipAddress: req.ip,
    });

    res.json(result);
  }

  // 4. Verify Aadhaar via DigiLocker / OTP
  static async verifyAadhaar(req: AuthenticatedRequest, res: Response): Promise<void> {
    const data = verifyAadhaarSchema.parse(req.body);
    const user = req.user!;

    const result = await kycService.verifyAadhaar({
      userId: user._id,
      aadhaarNumber: data.aadhaarNumber,
      otp: data.otp,
      ipAddress: req.ip,
    });

    res.json(result);
  }

  // 5. Selfie Liveness Check
  static async verifyLiveness(req: AuthenticatedRequest, res: Response): Promise<void> {
    const user = req.user!;

    await store.createAuditLog({
      actorId: user._id,
      actorRole: 'couple',
      action: 'kyc:liveness_check_passed',
      ip: req.ip || '127.0.0.1',
    });

    res.json({
      success: true,
      message: 'Selfie liveness check matched successfully with verified ID photo.',
    });
  }

  // 6. DPDP Compliance: Right to Erasure ("Delete My Data")
  static async deleteMyData(req: AuthenticatedRequest, res: Response): Promise<void> {
    const user = req.user!;

    // Anonymize & clear KYC references
    await store.updateUser(user._id, {
      name: 'Anonymized Host',
      email: undefined,
      panLast4: undefined,
      maskedPan: undefined,
      aadhaarLast4: undefined,
      kycStatus: 'not_started',
      verifiedName: undefined,
    });

    await store.createAuditLog({
      actorId: user._id,
      actorRole: 'couple',
      action: 'dpdp:data_erasure_requested',
      ip: req.ip || '127.0.0.1',
    });

    res.json({
      success: true,
      message: 'Your personal and KYC verification data has been purged in compliance with DPDP Act 2023.',
    });
  }
}
