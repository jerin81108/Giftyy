export type UserRole = 'couple' | 'admin';

export type KycStatus = 'not_started' | 'pending' | 'verified' | 'rejected' | 'needs_resubmission';

export interface IUser {
  _id: string;
  phone: string;
  name: string;
  email?: string;
  dob?: string;
  partnerName?: string;
  city?: string;
  role: UserRole;
  fcmToken?: string;
  
  // KYC fields (DPDP Act 2023 compliant)
  kycStatus: KycStatus;
  kycProvider?: string;
  kycReferenceId?: string;
  panLast4?: string;
  maskedPan?: string;
  aadhaarLast4?: string;
  kycVerifiedAt?: Date;
  rejectionReason?: string;
  verifiedName?: string;

  // DPDP Consent
  consentVersion?: string;
  consentAt?: Date;

  // Security & Lockout
  lastLoginAt?: Date;
  deviceInfo?: string;
  failedOtpAttempts?: number;
  lockedUntil?: Date;

  createdAt: Date;
  updatedAt: Date;
}

export interface IKycRecord {
  _id: string;
  userId: string;
  provider: string;
  referenceId: string;
  documentType: 'pan' | 'aadhaar' | 'passport' | 'voter_id' | 'driving_licence';
  status: KycStatus;
  verifiedName?: string;
  nameMatchScore?: number;
  panLast4?: string;
  aadhaarLast4?: string;
  rejectionReason?: string;
  encryptedDocRef?: string;
  ipAddress?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface IAuditLog {
  _id: string;
  actorId: string;
  actorRole: string;
  action: string;
  targetId?: string;
  ip: string;
  metadata?: Record<string, any>;
  timestamp: Date;
}

export type RoomPrivacy = 'public' | 'private';
export type RoomStatus = 'draft' | 'active' | 'published' | 'locked' | 'archived' | 'flagged' | 'suspended';

export interface IRoom {
  _id: string;
  hostId: string;
  ownerId?: string; // alias for backwards compatibility
  eventType: string; // wedding, engagement, birthday, baby_shower, ear_piercing, coming_of_age, housewarming, graduation, anniversary, festival, custom
  title: string;
  honoreeName: string;
  partner1Name?: string; // alias for backwards compatibility
  partner2Name?: string; // for wedding / anniversary
  date: Date;
  venue: string;
  city: string;
  coverImageUrl?: string;
  story: string;
  privacy: RoomPrivacy;
  isPublic?: boolean; // alias for backwards compatibility
  slug: string; // e.g. "priya-ear-piercing-4821" or "aisha-kabir"
  roomCode: string; // e.g. "PRIYA4821"
  qrUrl?: string;
  expiresAt?: Date;
  status: RoomStatus;
  isWishlistEnabled: boolean;
  showAmounts: boolean;
  kycVerified: boolean;
  invitationCardUrl?: string;
  payoutAccountRef?: string;
  bankDetails?: {
    accountHolderName: string;
    accountNumber: string;
    ifscCode: string;
    upiId?: string;
    isVerified: boolean;
    pennyDropMatchScore?: number;
  };
  memberCount: number;
  totalTarget: number;
  totalRaised: number;
  contributorCount: number;
  createdAt: Date;
  updatedAt: Date;
}

// Backward-compatibility alias for legacy code
export type IWedding = IRoom;

export type MemberRole = 'host' | 'co_host' | 'member';
export type MemberStatus = 'pending' | 'approved' | 'removed';
export type RsvpStatus = 'attending' | 'not_attending' | 'maybe' | 'none';

export interface IRoomMember {
  _id: string;
  roomId: string;
  userId?: string;
  guestId?: string;
  displayName: string;
  phone?: string;
  email?: string;
  avatarUrl?: string;
  role: MemberRole;
  status: MemberStatus;
  rsvpStatus: RsvpStatus;
  guestCount: number; // e.g. attending with +1 or family
  joinedAt: Date;
  updatedAt: Date;
}

export type PostType = 'blessing' | 'photo' | 'announcement';

export interface IRoomPost {
  _id: string;
  roomId: string;
  memberId?: string;
  authorName: string;
  authorRole: MemberRole;
  type: PostType;
  content: string;
  mediaUrl?: string;
  isPinned?: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export type WishlistStatus = 'active' | 'funded' | 'archived';

export interface IWishlistItem {
  _id: string;
  roomId: string;
  weddingId?: string; // alias
  title: string;
  description: string;
  icon: string;
  targetAmount: number;
  raisedAmount: number;
  contributorCount: number;
  priority: number;
  deadline?: Date;
  status: WishlistStatus;
  createdAt: Date;
  updatedAt: Date;
}

export type PaymentStatus = 'created' | 'paid' | 'failed' | 'refunded';

export interface IContribution {
  _id: string;
  roomId: string;
  weddingId?: string; // alias
  itemId?: string;
  itemTitle?: string;
  guestName: string;
  guestPhone?: string;
  guestEmail?: string;
  amount: number;
  platformFee: number;
  netAmount: number;
  message?: string;
  isAnonymous: boolean;
  paymentProvider: 'razorpay' | 'cashfree' | 'mock';
  orderId: string;
  paymentId?: string;
  signature?: string;
  status: PaymentStatus;
  receiptNumber?: string;
  createdAt: Date;
  updatedAt: Date;
}

export type PayoutStatus = 'pending' | 'processing' | 'completed' | 'failed';

export interface IPayout {
  _id: string;
  roomId: string;
  weddingId?: string; // alias
  amount: number;
  status: PayoutStatus;
  providerRef?: string;
  bankAccountRef?: string;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface IReport {
  _id: string;
  roomId?: string;
  weddingId?: string; // alias
  reporterName: string;
  reporterContact?: string;
  reason: string;
  details?: string;
  status: 'pending' | 'reviewed' | 'action_taken' | 'dismissed';
  createdAt: Date;
  updatedAt: Date;
}
