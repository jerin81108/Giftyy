import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { config } from '../config';
import { store } from '../services/store.service';
import { otpService } from '../services/otp.service';
import { firebaseService } from '../services/firebase.service';
import { AuthenticatedRequest } from '../middlewares/auth.middleware';

const sendOtpSchema = z.object({
  phone: z.string().min(10, 'Valid 10-digit Indian phone number is required'),
});

const verifyOtpSchema = z.object({
  phone: z.string().min(10),
  otp: z.string().length(6, 'OTP must be 6 digits'),
  name: z.string().optional(),
  email: z.string().email().optional().or(z.literal('')),
  dob: z.string().optional(),
  partnerName: z.string().optional(),
  city: z.string().optional(),
  deviceInfo: z.string().optional(),
});

export class AuthController {
  static async sendOtp(req: Request, res: Response): Promise<void> {
    const { phone } = sendOtpSchema.parse(req.body);
    const cleanPhone = phone.replace(/\D/g, '');

    // Check if user is locked out from repeated failures
    const existing = await store.findUserByPhone(cleanPhone);
    if (existing?.lockedUntil && existing.lockedUntil > new Date()) {
      const waitMinutes = Math.ceil((existing.lockedUntil.getTime() - Date.now()) / 60000);
      res.status(429).json({
        success: false,
        message: `Account temporarily locked due to repeated invalid attempts. Please try again in ${waitMinutes} minutes.`,
      });
      return;
    }

    const result = await otpService.sendOtp(cleanPhone);

    await store.createAuditLog({
      actorId: existing ? existing._id : 'guest',
      actorRole: 'couple',
      action: 'auth:otp_requested',
      ip: req.ip || '127.0.0.1',
      metadata: { phone: `+91-xxxxxx${cleanPhone.slice(-4)}` },
    });

    res.json(result);
  }

  static async verifyOtp(req: Request, res: Response): Promise<void> {
    const { phone, otp, name, email, dob, partnerName, city, deviceInfo } = verifyOtpSchema.parse(req.body);
    const cleanPhone = phone.replace(/\D/g, '');

    const existingUser = await store.findUserByPhone(cleanPhone);

    // Check lockout
    if (existingUser?.lockedUntil && existingUser.lockedUntil > new Date()) {
      res.status(429).json({
        success: false,
        message: 'Account temporarily locked. Please try again later.',
      });
      return;
    }

    const isValid = await otpService.verifyOtp(cleanPhone, otp);
    if (!isValid) {
      if (existingUser) {
        const attempts = (existingUser.failedOtpAttempts || 0) + 1;
        const lockedUntil = attempts >= 5 ? new Date(Date.now() + 15 * 60 * 1000) : undefined;
        await store.updateUser(existingUser._id, {
          failedOtpAttempts: attempts,
          lockedUntil,
        });
      }
      res.status(400).json({ success: false, message: 'Invalid OTP. Please check and try again.' });
      return;
    }

    let user = existingUser;
    if (!user) {
      user = await store.createUser({
        phone: cleanPhone,
        name: name || 'Host',
        email: email || undefined,
        dob,
        partnerName,
        city,
        role: 'couple',
        kycStatus: 'not_started',
        consentVersion: 'v1.0',
        consentAt: new Date(),
        deviceInfo: deviceInfo || req.headers['user-agent'],
      });
    } else {
      // Reset failed attempts on success
      await store.updateUser(user._id, {
        failedOtpAttempts: 0,
        lockedUntil: undefined,
        lastLoginAt: new Date(),
        deviceInfo: deviceInfo || (req.headers['user-agent'] as string),
        ...(name ? { name } : {}),
        ...(email ? { email } : {}),
      });
    }

    const token = jwt.sign(
      { id: user._id, role: user.role, phone: user.phone },
      config.jwtSecret,
      { expiresIn: '30d' }
    );

    const wedding = await store.findWeddingByOwnerId(user._id);

    await store.createAuditLog({
      actorId: user._id,
      actorRole: user.role,
      action: 'auth:login_success',
      ip: req.ip || '127.0.0.1',
      metadata: { deviceInfo: deviceInfo || req.headers['user-agent'] },
    });

    res.json({
      success: true,
      message: 'Logged in successfully',
      token,
      user: {
        _id: user._id,
        phone: user.phone,
        name: user.name,
        email: user.email,
        dob: user.dob,
        role: user.role,
        kycStatus: user.kycStatus,
        maskedPan: user.maskedPan,
      },
      hasWedding: !!wedding,
      weddingSlug: wedding?.slug,
      isKycVerified: user.kycStatus === 'verified',
    });
  }

  static async updateFcmToken(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const { fcmToken } = req.body;
      if (!fcmToken) {
        res.status(400).json({ success: false, message: 'fcmToken is required' });
        return;
      }
      await store.updateUser(req.user!._id, { fcmToken });
      res.json({ success: true, message: 'FCM token registered successfully' });
    } catch (error) {
      res.status(500).json({ success: false, message: 'Failed to update FCM token', error: (error as Error).message });
    }
  }

  static async getMe(req: AuthenticatedRequest, res: Response): Promise<void> {
    const user = req.user!;
    const wedding = await store.findWeddingByOwnerId(user._id);

    res.json({
      success: true,
      user,
      wedding,
      isKycVerified: user.kycStatus === 'verified',
    });
  }

  static async firebaseLogin(req: Request, res: Response): Promise<void> {
    try {
      const { idToken, name, fcmToken } = req.body;
      if (!idToken) {
        res.status(400).json({ success: false, message: 'Firebase idToken is required' });
        return;
      }

      const decoded = await firebaseService.verifyIdToken(idToken);
      if (!decoded) {
        res.status(401).json({ success: false, message: 'Invalid or expired Firebase ID token' });
        return;
      }

      const phone = decoded.phone_number ? decoded.phone_number.replace(/\D/g, '').slice(-10) : '';
      let user = phone ? await store.findUserByPhone(phone) : null;

      if (!user) {
        user = await store.createUser({
          phone: phone || decoded.uid,
          name: name || decoded.name || 'Giftyy User',
          email: decoded.email,
          role: 'couple',
          fcmToken,
        });
      } else if (fcmToken && user.fcmToken !== fcmToken) {
        user = await store.updateUser(user._id, { fcmToken }) || user;
      }

      const token = jwt.sign(
        { id: user._id, role: user.role },
        config.jwtSecret,
        { expiresIn: config.jwtExpiresIn as any }
      );

      res.json({
        success: true,
        message: 'Firebase authentication successful',
        token,
        user,
      });
    } catch (error) {
      res.status(500).json({ success: false, message: 'Firebase login failed', error: (error as Error).message });
    }
  }
}
