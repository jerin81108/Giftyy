import crypto from 'crypto';
import { config } from '../config';

export class EncryptionService {
  private static algorithm = 'aes-256-cbc';
  private static key = crypto.scryptSync(config.encryptionKey, 'salt_giftyy_kyc_2026', 32);

  // Encrypt string into iv:hexString
  static encrypt(text: string): string {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv(this.algorithm, this.key, iv);
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    return `${iv.toString('hex')}:${encrypted}`;
  }

  // Decrypt iv:hexString into plaintext
  static decrypt(encryptedText: string): string {
    try {
      const parts = encryptedText.split(':');
      if (parts.length !== 2) return encryptedText;
      const iv = Buffer.from(parts[0], 'hex');
      const encrypted = parts[1];
      const decipher = crypto.createDecipheriv(this.algorithm, this.key, iv);
      let decrypted = decipher.update(encrypted, 'hex', 'utf8');
      decrypted += decipher.final('utf8');
      return decrypted;
    } catch {
      return encryptedText;
    }
  }

  // Mask PAN number (e.g. ABCDE1234F -> ABCDE****F)
  static maskPan(pan: string): string {
    const clean = pan.toUpperCase().trim();
    if (clean.length !== 10) return clean;
    return `${clean.substring(0, 5)}****${clean.substring(9)}`;
  }

  // Mask Aadhaar number (e.g. 123456789012 -> XXXX-XXXX-9012)
  static maskAadhaar(aadhaar: string): string {
    const clean = aadhaar.replace(/\D/g, '');
    if (clean.length !== 12) return clean;
    return `XXXX-XXXX-${clean.substring(8)}`;
  }

  // Mask Bank Account (e.g. 123456789012 -> xxxxxxxx9012)
  static maskBankAccount(accountNumber: string): string {
    const clean = accountNumber.trim();
    if (clean.length < 4) return clean;
    return `xxxx-xxxx-${clean.slice(-4)}`;
  }

  // Levenshtein / fuzzy string similarity for name matching (0 to 100)
  static calculateNameMatch(name1: string, name2: string): number {
    const n1 = name1.toLowerCase().trim().replace(/[^a-z]/g, '');
    const n2 = name2.toLowerCase().trim().replace(/[^a-z]/g, '');

    if (n1 === n2) return 100;
    if (!n1 || !n2) return 0;

    // Check if one contains the other
    if (n1.includes(n2) || n2.includes(n1)) return 85;

    // Split words match (e.g. "Aisha Sharma" vs "Aisha Kabir Sharma")
    const words1 = name1.toLowerCase().split(/\s+/);
    const words2 = name2.toLowerCase().split(/\s+/);
    let commonWords = 0;
    for (const w of words1) {
      if (words2.includes(w)) commonWords++;
    }
    // If all words of the shorter name are present in the longer name
    if (commonWords >= Math.min(words1.length, words2.length) && commonWords > 0) {
      return 85;
    }
    const score = Math.round((commonWords / Math.max(words1.length, words2.length)) * 100);
    return Math.max(score, 60);
  }
}
