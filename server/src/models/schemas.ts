import mongoose, { Schema } from 'mongoose';
import {
  IUser,
  IWedding,
  IRoom,
  IRoomMember,
  IRoomPost,
  IWishlistItem,
  IContribution,
  IPayout,
  IKycRecord,
  IAuditLog,
  IReport,
} from './types';

// User Schema with KYC & DPDP Compliance
const UserSchema = new Schema<IUser>({
  phone: { type: String, required: true, unique: true, index: true },
  name: { type: String, required: true },
  email: { type: String, sparse: true },
  dob: { type: String },
  partnerName: { type: String },
  city: { type: String },
  role: { type: String, enum: ['couple', 'admin'], default: 'couple' },
  fcmToken: { type: String },

  // KYC Verification fields (DPDP Act 2023 compliant)
  kycStatus: {
    type: String,
    enum: ['not_started', 'pending', 'verified', 'rejected', 'needs_resubmission'],
    default: 'not_started',
    index: true,
  },
  kycProvider: { type: String, default: 'digio' },
  kycReferenceId: { type: String },
  panLast4: { type: String },
  maskedPan: { type: String },
  aadhaarLast4: { type: String },
  kycVerifiedAt: { type: Date },
  rejectionReason: { type: String },
  verifiedName: { type: String },

  // DPDP Consent
  consentVersion: { type: String, default: 'v1.0' },
  consentAt: { type: Date },

  // Security & Lockout
  lastLoginAt: { type: Date },
  deviceInfo: { type: String },
  failedOtpAttempts: { type: Number, default: 0 },
  lockedUntil: { type: Date },
}, { timestamps: true });

// KYC Record Schema (Restricted access, audit logged)
const KycRecordSchema = new Schema<IKycRecord>({
  userId: { type: String, required: true, index: true },
  provider: { type: String, required: true },
  referenceId: { type: String, required: true, index: true },
  documentType: {
    type: String,
    enum: ['pan', 'aadhaar', 'passport', 'voter_id', 'driving_licence'],
    required: true,
  },
  status: {
    type: String,
    enum: ['not_started', 'pending', 'verified', 'rejected', 'needs_resubmission'],
    default: 'pending',
  },
  verifiedName: { type: String },
  nameMatchScore: { type: Number },
  panLast4: { type: String },
  aadhaarLast4: { type: String },
  rejectionReason: { type: String },
  encryptedDocRef: { type: String },
  ipAddress: { type: String },
}, { timestamps: true });

// Audit Log Schema
const AuditLogSchema = new Schema<IAuditLog>({
  actorId: { type: String, required: true, index: true },
  actorRole: { type: String, required: true },
  action: { type: String, required: true, index: true },
  targetId: { type: String, index: true },
  ip: { type: String, required: true },
  metadata: { type: Schema.Types.Mixed },
  timestamp: { type: Date, default: Date.now, index: true },
});

// Room Schema (Event Rooms platform)
const RoomSchema = new Schema<IRoom>({
  hostId: { type: String, required: true, index: true },
  ownerId: { type: String, index: true },
  eventType: { type: String, required: true, default: 'wedding', index: true },
  title: { type: String, required: true },
  honoreeName: { type: String, required: true },
  partner1Name: { type: String },
  partner2Name: { type: String },
  date: { type: Date, required: true },
  venue: { type: String, default: '' },
  city: { type: String, required: true },
  coverImageUrl: { type: String },
  story: { type: String, default: '' },
  privacy: { type: String, enum: ['public', 'private'], default: 'public', index: true },
  isPublic: { type: Boolean, default: true },
  slug: { type: String, required: true, unique: true, index: true },
  roomCode: { type: String, required: true, unique: true, index: true },
  qrUrl: { type: String },
  expiresAt: { type: Date },
  status: { type: String, enum: ['draft', 'active', 'locked', 'archived'], default: 'active', index: true },
  isWishlistEnabled: { type: Boolean, default: true },
  showAmounts: { type: Boolean, default: true },
  kycVerified: { type: Boolean, default: false, index: true },
  invitationCardUrl: { type: String },
  payoutAccountRef: { type: String },
  bankDetails: {
    accountHolderName: { type: String },
    accountNumber: { type: String },
    ifscCode: { type: String },
    upiId: { type: String },
    isVerified: { type: Boolean, default: false },
    pennyDropMatchScore: { type: Number },
  },
  memberCount: { type: Number, default: 1 },
  totalTarget: { type: Number, default: 0 },
  totalRaised: { type: Number, default: 0 },
  contributorCount: { type: Number, default: 0 },
}, { timestamps: true });

// Room Member Schema
const RoomMemberSchema = new Schema<IRoomMember>({
  roomId: { type: String, required: true, index: true },
  userId: { type: String, index: true },
  guestId: { type: String, index: true },
  displayName: { type: String, required: true },
  phone: { type: String },
  email: { type: String },
  avatarUrl: { type: String },
  role: { type: String, enum: ['host', 'co_host', 'member'], default: 'member' },
  status: { type: String, enum: ['pending', 'approved', 'removed'], default: 'approved', index: true },
  rsvpStatus: { type: String, enum: ['attending', 'not_attending', 'maybe', 'none'], default: 'none' },
  guestCount: { type: Number, default: 1 },
  joinedAt: { type: Date, default: Date.now },
}, { timestamps: true });

RoomMemberSchema.index({ roomId: 1, userId: 1 });
RoomMemberSchema.index({ roomId: 1, guestId: 1 });

// Room Post Schema (Guestbook blessings, shared album photos, announcements)
const RoomPostSchema = new Schema<IRoomPost>({
  roomId: { type: String, required: true, index: true },
  memberId: { type: String, index: true },
  authorName: { type: String, required: true },
  authorRole: { type: String, enum: ['host', 'co_host', 'member'], default: 'member' },
  type: { type: String, enum: ['blessing', 'photo', 'announcement'], required: true },
  content: { type: String, default: '' },
  mediaUrl: { type: String },
  isPinned: { type: Boolean, default: false },
}, { timestamps: true });

RoomPostSchema.index({ roomId: 1, createdAt: -1 });

// Wishlist Item Schema (linked to roomId and legacy weddingId)
const WishlistItemSchema = new Schema<IWishlistItem>({
  roomId: { type: String, index: true },
  weddingId: { type: String, index: true },
  title: { type: String, required: true },
  description: { type: String, default: '' },
  icon: { type: String, default: 'gift' },
  targetAmount: { type: Number, required: true, min: 1 },
  raisedAmount: { type: Number, default: 0 },
  contributorCount: { type: Number, default: 0 },
  priority: { type: Number, default: 1 },
  deadline: { type: Date },
  status: { type: String, enum: ['active', 'funded', 'archived'], default: 'active' },
}, { timestamps: true });

WishlistItemSchema.index({ roomId: 1, priority: 1 });
WishlistItemSchema.index({ weddingId: 1, priority: 1 });

// Contribution Schema
const ContributionSchema = new Schema<IContribution>({
  roomId: { type: String, index: true },
  weddingId: { type: String, index: true },
  itemId: { type: String, index: true },
  itemTitle: { type: String },
  guestName: { type: String, required: true },
  guestPhone: { type: String },
  guestEmail: { type: String },
  amount: { type: Number, required: true, min: 1 },
  platformFee: { type: Number, default: 0 },
  netAmount: { type: Number, required: true },
  message: { type: String, default: '' },
  isAnonymous: { type: Boolean, default: false },
  paymentProvider: { type: String, enum: ['razorpay', 'cashfree', 'mock'], default: 'razorpay' },
  orderId: { type: String, required: true, unique: true, index: true },
  paymentId: { type: String, index: true },
  signature: { type: String },
  status: { type: String, enum: ['created', 'paid', 'failed', 'refunded'], default: 'created', index: true },
  receiptNumber: { type: String },
}, { timestamps: true });

// Payout Schema
const PayoutSchema = new Schema<IPayout>({
  roomId: { type: String, index: true },
  weddingId: { type: String, index: true },
  amount: { type: Number, required: true, min: 1 },
  status: { type: String, enum: ['pending', 'processing', 'completed', 'failed'], default: 'pending' },
  providerRef: { type: String },
  bankAccountRef: { type: String },
  notes: { type: String },
}, { timestamps: true });

// Report Schema (Anti-fraud / Abuse)
const ReportSchema = new Schema<IReport>({
  roomId: { type: String, index: true },
  weddingId: { type: String, index: true },
  reporterName: { type: String, required: true },
  reporterContact: { type: String },
  reason: { type: String, required: true },
  details: { type: String },
  status: { type: String, enum: ['pending', 'reviewed', 'action_taken', 'dismissed'], default: 'pending' },
}, { timestamps: true });

export const UserModel = mongoose.model<IUser>('User', UserSchema);
export const KycRecordModel = mongoose.model<IKycRecord>('KycRecord', KycRecordSchema);
export const AuditLogModel = mongoose.model<IAuditLog>('AuditLog', AuditLogSchema);
export const RoomModel = mongoose.model<IRoom>('Room', RoomSchema);
export const WeddingModel = mongoose.model<IWedding>('Wedding', RoomSchema as any);
export const RoomMemberModel = mongoose.model<IRoomMember>('RoomMember', RoomMemberSchema);
export const RoomPostModel = mongoose.model<IRoomPost>('RoomPost', RoomPostSchema);
export const WishlistItemModel = mongoose.model<IWishlistItem>('WishlistItem', WishlistItemSchema);
export const ContributionModel = mongoose.model<IContribution>('Contribution', ContributionSchema);
export const PayoutModel = mongoose.model<IPayout>('Payout', PayoutSchema);
export const ReportModel = mongoose.model<IReport>('Report', ReportSchema);
