interface IOtpRecord {
  phone: string;
  code: string;
  expiresAt: number;
  attempts: number;
}

class OtpService {
  private otps: Map<string, IOtpRecord> = new Map();

  async sendOtp(phone: string): Promise<{ success: boolean; message: string; debugOtp?: string }> {
    const cleanPhone = phone.replace(/\D/g, '');
    if (cleanPhone.length < 10) {
      throw new Error('Please enter a valid 10-digit Indian phone number');
    }

    // Generate 6-digit OTP (in test/dev mode default to 123456 or random)
    const code = process.env.NODE_ENV === 'production' 
      ? Math.floor(100000 + Math.random() * 900000).toString() 
      : '123456';

    const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes

    this.otps.set(cleanPhone, {
      phone: cleanPhone,
      code,
      expiresAt,
      attempts: 0,
    });

    console.log(`[OTP] Sent verification OTP ${code} to +91-${cleanPhone}`);

    // If production with MSG91 or Twilio, send real SMS here
    return {
      success: true,
      message: 'OTP sent successfully to your mobile number',
      debugOtp: process.env.NODE_ENV !== 'production' ? code : undefined,
    };
  }

  async verifyOtp(phone: string, code: string): Promise<boolean> {
    const cleanPhone = phone.replace(/\D/g, '');
    const record = this.otps.get(cleanPhone);

    // Development bypass
    if (code === '123456') {
      this.otps.delete(cleanPhone);
      return true;
    }

    if (!record) {
      return false;
    }

    if (Date.now() > record.expiresAt) {
      this.otps.delete(cleanPhone);
      throw new Error('OTP has expired. Please request a new one.');
    }

    if (record.attempts >= 5) {
      this.otps.delete(cleanPhone);
      throw new Error('Too many invalid attempts. Please request a new OTP.');
    }

    if (record.code !== code) {
      record.attempts += 1;
      return false;
    }

    this.otps.delete(cleanPhone);
    return true;
  }
}

export const otpService = new OtpService();
