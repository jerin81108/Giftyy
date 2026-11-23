import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '5000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  appName: process.env.APP_NAME || 'Giftyy',
  appTagline: process.env.APP_TAGLINE || 'Skip the gifts. Fund the dream',
  appBaseUrl: process.env.APP_BASE_URL || 'http://localhost:3000',
  corsOrigin: process.env.CORS_ORIGIN || '*',

  // Database
  mongoUri: process.env.MONGODB_URI || 'mongodb://localhost:27017/giftyy',
  useInMemoryDb: process.env.USE_IN_MEMORY_DB !== 'false',

  // Auth
  jwtSecret: process.env.JWT_SECRET || 'super_secret_jwt_key_giftyy_2026_dev',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',

  // Encryption (AES-256-CBC, 32-byte key)
  encryptionKey: process.env.ENCRYPTION_KEY || '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',

  // KYC Verification
  kyc: {
    provider: process.env.KYC_PROVIDER || 'mock',
    apiKey: process.env.KYC_API_KEY || 'mock_kyc_api_key',
    apiSecret: process.env.KYC_API_SECRET || 'mock_kyc_api_secret',
    webhookSecret: process.env.KYC_WEBHOOK_SECRET || 'mock_kyc_webhook_secret',
    retentionDays: parseInt(process.env.KYC_DATA_RETENTION_DAYS || '180', 10),
  },

  // Razorpay
  razorpay: {
    keyId: process.env.RAZORPAY_KEY_ID || 'rzp_test_placeholder_key',
    keySecret: process.env.RAZORPAY_KEY_SECRET || 'placeholder_secret_key',
    webhookSecret: process.env.RAZORPAY_WEBHOOK_SECRET || 'webhook_secret_key',
    mockMode: process.env.RAZORPAY_MOCK_MODE !== 'false',
  },

  // Fee
  platformFeePercent: parseFloat(process.env.PLATFORM_FEE_PERCENT || '0'),

  // SMS
  smsProvider: process.env.SMS_PROVIDER || 'mock',

  // Firebase
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID || 'giftyy-2ce00',
    serviceAccountPath: process.env.FIREBASE_SERVICE_ACCOUNT_PATH,
  },
};
