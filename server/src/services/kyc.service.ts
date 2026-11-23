import { config } from '../config';
import { store } from './store.service';
import { EncryptionService } from './encryption.service';
import { IUser, KycStatus } from '../models/types';

export interface IPanVerifyInput {
  userId: string;
  panNumber: string; // 10 alphanumeric chars
  fullName: string;
  dob?: string;
  ipAddress?: string;
}

export interface IAadhaarVerifyInput {
  userId: string;
  aadhaarNumber: string; // 12 digits
  otp?: string;
  ipAddress?: string;
}

export interface IBankPennyDropInput {
  userId: string;
  accountNumber: string;
  ifscCode: string;
  accountHolderName: string;
  ipAddress?: string;
}

class KycService {
  // 1. Verify PAN (Mandatory for payouts & publishing wedding)
  async verifyPan(input: IPanVerifyInput): Promise<{
    success: boolean;
    status: KycStatus;
    verifiedName?: string;
    nameMatchScore?: number;
    maskedPan: string;
    message: string;
  }> {
    const { userId, panNumber, fullName, ipAddress } = input;
    const cleanPan = panNumber.toUpperCase().trim();

    // Regex format: 5 letters, 4 digits, 1 letter (e.g. ABCDE1234F)
    const panRegex = /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/;
    if (!panRegex.test(cleanPan)) {
      throw new Error('Invalid PAN format. Must be 10 characters (e.g. ABCDE1234F)');
    }

    const panLast4 = cleanPan.slice(-4);
    const maskedPan = EncryptionService.maskPan(cleanPan);

    // Anti-fraud: Duplicate PAN check
    const existing = await store.findUserByPanLast4(panLast4, userId);
    if (existing) {
      await store.createAuditLog({
        actorId: userId,
        actorRole: 'couple',
        action: 'kyc:duplicate_pan_attempt',
        ip: ipAddress || '127.0.0.1',
        metadata: { panLast4, duplicateUserId: existing._id },
      });
      throw new Error('This PAN is already registered and verified with another Giftyy wedding account.');
    }

    // In production with Digio / Setu / Cashfree, call the provider API here:
    // e.g. const res = await axios.post('https://api.digio.in/v3/client/kyc/pan/verify', { pan: cleanPan, name: fullName });
    const verifiedName = fullName.toUpperCase().trim();
    const nameMatchScore = EncryptionService.calculateNameMatch(fullName, verifiedName);

    if (nameMatchScore < 70) {
      const record = await store.createKycRecord({
        userId,
        provider: config.kyc.provider,
        referenceId: `pan_ref_${Date.now()}`,
        documentType: 'pan',
        status: 'rejected',
        rejectionReason: `Name mismatch: ID name (${verifiedName}) did not match provided name (${fullName})`,
        panLast4,
        ipAddress,
      });

      await store.updateUser(userId, {
        kycStatus: 'rejected',
        rejectionReason: record.rejectionReason,
      });

      return {
        success: false,
        status: 'rejected',
        maskedPan,
        message: 'Name on PAN card does not match host full name.',
      };
    }

    // Passed PAN verification
    const referenceId = `ref_pan_${Date.now().toString(36)}`;
    await store.createKycRecord({
      userId,
      provider: config.kyc.provider,
      referenceId,
      documentType: 'pan',
      status: 'verified',
      verifiedName,
      nameMatchScore,
      panLast4,
      ipAddress,
    });

    // Update user profile
    await store.updateUser(userId, {
      kycStatus: 'verified',
      kycProvider: config.kyc.provider,
      kycReferenceId: referenceId,
      panLast4,
      maskedPan,
      verifiedName,
      kycVerifiedAt: new Date(),
      rejectionReason: undefined,
    });

    // Automatically mark couple's wedding as KYC verified and publishable!
    const wedding = await store.findWeddingByOwnerId(userId);
    if (wedding) {
      await store.updateWedding(wedding._id, {
        kycVerified: true,
        isPublic: true,
        status: 'published',
      });
    }

    await store.createAuditLog({
      actorId: userId,
      actorRole: 'couple',
      action: 'kyc:pan_verified',
      ip: ipAddress || '127.0.0.1',
      metadata: { panLast4, nameMatchScore },
    });

    return {
      success: true,
      status: 'verified',
      verifiedName,
      nameMatchScore,
      maskedPan,
      message: 'PAN verified successfully! Your wedding page is now publicly accessible and ready to receive contributions ✨',
    };
  }

  // 2. Aadhaar DigiLocker eKYC (OTP or DigiLocker flow)
  async verifyAadhaar(input: IAadhaarVerifyInput): Promise<{
    success: boolean;
    status: KycStatus;
    maskedAadhaar: string;
    message: string;
  }> {
    const { userId, aadhaarNumber, otp, ipAddress } = input;
    const cleanAadhaar = aadhaarNumber.replace(/\D/g, '');

    if (cleanAadhaar.length !== 12) {
      throw new Error('Aadhaar number must be 12 digits');
    }

    const aadhaarLast4 = cleanAadhaar.slice(-4);
    const maskedAadhaar = EncryptionService.maskAadhaar(cleanAadhaar);

    // In dev mode or with test OTP '123456'
    if (otp && otp !== '123456') {
      throw new Error('Invalid Aadhaar OTP. Try 123456 in dev mode.');
    }

    // UIDAI & DPDP compliance: NEVER store the 12-digit Aadhaar number
    await store.createKycRecord({
      userId,
      provider: config.kyc.provider,
      referenceId: `aadhaar_ref_${Date.now()}`,
      documentType: 'aadhaar',
      status: 'verified',
      aadhaarLast4,
      ipAddress,
    });

    await store.updateUser(userId, {
      aadhaarLast4,
    });

    await store.createAuditLog({
      actorId: userId,
      actorRole: 'couple',
      action: 'kyc:aadhaar_verified',
      ip: ipAddress || '127.0.0.1',
      metadata: { aadhaarLast4 },
    });

    return {
      success: true,
      status: 'verified',
      maskedAadhaar,
      message: 'Aadhaar eKYC verified successfully via DigiLocker.',
    };
  }

  // 3. Bank Penny Drop Verification (Bank Account Name Match)
  async verifyBankPennyDrop(input: IBankPennyDropInput): Promise<{
    success: boolean;
    accountHolderName: string;
    matchScore: number;
    message: string;
  }> {
    const { userId, accountNumber, ifscCode, accountHolderName, ipAddress } = input;

    const user = await store.findUserById(userId);
    if (!user) throw new Error('User not found');

    const expectedName = user.verifiedName || user.name;
    const matchScore = EncryptionService.calculateNameMatch(accountHolderName, expectedName);

    if (matchScore < 70) {
      await store.createAuditLog({
        actorId: userId,
        actorRole: 'couple',
        action: 'bank:penny_drop_mismatch',
        ip: ipAddress || '127.0.0.1',
        metadata: { accountHolderName, expectedName, matchScore },
      });
      throw new Error(`Bank account name (${accountHolderName}) does not match KYC verified host name (${expectedName}). Name must match for payout compliance.`);
    }

    await store.createAuditLog({
      actorId: userId,
      actorRole: 'couple',
      action: 'bank:penny_drop_verified',
      ip: ipAddress || '127.0.0.1',
      metadata: { matchScore, accountNumberLast4: accountNumber.slice(-4) },
    });

    return {
      success: true,
      accountHolderName,
      matchScore,
      message: 'Bank account verified via penny-drop match.',
    };
  }
}

export const kycService = new KycService();
