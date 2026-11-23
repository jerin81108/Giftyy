import mongoose from 'mongoose';
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
  PostType,
  RsvpStatus,
} from '../models/types';
import {
  UserModel,
  WeddingModel,
  RoomModel,
  RoomMemberModel,
  RoomPostModel,
  WishlistItemModel,
  ContributionModel,
  PayoutModel,
  KycRecordModel,
  AuditLogModel,
  ReportModel,
} from '../models/schemas';
import { config } from '../config';

class StoreService {
  private isMongoConnected = false;

  // In-memory collections
  private users: Map<string, IUser> = new Map();
  private rooms: Map<string, IRoom> = new Map();
  private weddings: Map<string, IWedding> = new Map();
  private roomMembers: Map<string, IRoomMember> = new Map();
  private roomPosts: Map<string, IRoomPost> = new Map();
  private wishlistItems: Map<string, IWishlistItem> = new Map();
  private contributions: Map<string, IContribution> = new Map();
  private payouts: Map<string, IPayout> = new Map();
  private kycRecords: Map<string, IKycRecord> = new Map();
  private auditLogs: IAuditLog[] = [];
  private reports: Map<string, IReport> = new Map();

  async init() {
    if (!config.useInMemoryDb) {
      try {
        await mongoose.connect(config.mongoUri, { serverSelectionTimeoutMS: 3000 });
        this.isMongoConnected = true;
        console.log(' Connected to MongoDB Atlas / Server');
      } catch (err) {
        console.warn('⚠️ MongoDB connection failed, falling back to in-memory store:', (err as Error).message);
        this.isMongoConnected = false;
      }
    } else {
      console.log('⚡ Using In-Memory Database store (Fast & Zero external dependencies)');
    }
  }

  // Helper ID generator
  private generateId(): string {
    return 'id_' + Math.random().toString(36).substring(2, 11) + Date.now().toString(36);
  }

  // --- Users ---
  async findUserByPhone(phone: string): Promise<IUser | null> {
    if (this.isMongoConnected) {
      return (await UserModel.findOne({ phone }).lean()) as IUser | null;
    }
    for (const user of this.users.values()) {
      if (user.phone === phone) return user;
    }
    return null;
  }

  async findUserById(id: string): Promise<IUser | null> {
    if (this.isMongoConnected) {
      return (await UserModel.findById(id).lean()) as IUser | null;
    }
    return this.users.get(id) || null;
  }

  // Anti-fraud: Duplicate PAN check
  async findUserByPanLast4(panLast4: string, excludeUserId?: string): Promise<IUser | null> {
    if (this.isMongoConnected) {
      const query: any = { panLast4, kycStatus: 'verified' };
      if (excludeUserId) query._id = { $ne: excludeUserId };
      return (await UserModel.findOne(query).lean()) as IUser | null;
    }
    for (const user of this.users.values()) {
      if (user.panLast4 === panLast4 && user._id !== excludeUserId && user.kycStatus === 'verified') {
        return user;
      }
    }
    return null;
  }

  async createUser(data: Partial<IUser>): Promise<IUser> {
    if (this.isMongoConnected) {
      const doc = await UserModel.create(data);
      return doc.toObject() as IUser;
    }
    const user: IUser = {
      _id: this.generateId(),
      phone: data.phone!,
      name: data.name || 'Couple Host',
      email: data.email,
      dob: data.dob,
      partnerName: data.partnerName,
      city: data.city,
      role: data.role || 'couple',
      fcmToken: data.fcmToken,
      kycStatus: data.kycStatus || 'not_started',
      kycProvider: data.kycProvider,
      kycReferenceId: data.kycReferenceId,
      panLast4: data.panLast4,
      maskedPan: data.maskedPan,
      aadhaarLast4: data.aadhaarLast4,
      kycVerifiedAt: data.kycVerifiedAt,
      rejectionReason: data.rejectionReason,
      verifiedName: data.verifiedName,
      consentVersion: data.consentVersion || 'v1.0',
      consentAt: data.consentAt || new Date(),
      lastLoginAt: new Date(),
      failedOtpAttempts: 0,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.users.set(user._id, user);
    return user;
  }

  async updateUser(id: string, data: Partial<IUser>): Promise<IUser | null> {
    if (this.isMongoConnected) {
      return (await UserModel.findByIdAndUpdate(id, data, { new: true }).lean()) as IUser | null;
    }
    const current = this.users.get(id);
    if (!current) return null;
    const updated = { ...current, ...data, updatedAt: new Date() };
    this.users.set(id, updated);
    return updated;
  }

  // --- KYC Records ---
  async createKycRecord(data: Partial<IKycRecord>): Promise<IKycRecord> {
    if (this.isMongoConnected) {
      const doc = await KycRecordModel.create(data);
      return doc.toObject() as IKycRecord;
    }
    const record: IKycRecord = {
      _id: this.generateId(),
      userId: data.userId!,
      provider: data.provider || 'digio',
      referenceId: data.referenceId || `ref_kyc_${Date.now()}`,
      documentType: data.documentType || 'pan',
      status: data.status || 'pending',
      verifiedName: data.verifiedName,
      nameMatchScore: data.nameMatchScore,
      panLast4: data.panLast4,
      aadhaarLast4: data.aadhaarLast4,
      rejectionReason: data.rejectionReason,
      encryptedDocRef: data.encryptedDocRef,
      ipAddress: data.ipAddress,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.kycRecords.set(record._id, record);
    return record;
  }

  async findKycRecordByUserId(userId: string): Promise<IKycRecord | null> {
    if (this.isMongoConnected) {
      return (await KycRecordModel.findOne({ userId }).sort({ createdAt: -1 }).lean()) as IKycRecord | null;
    }
    for (const r of Array.from(this.kycRecords.values()).reverse()) {
      if (r.userId === userId) return r;
    }
    return null;
  }

  // --- Audit Logs ---
  async createAuditLog(data: Partial<IAuditLog>): Promise<IAuditLog> {
    if (this.isMongoConnected) {
      const doc = await AuditLogModel.create(data);
      return doc.toObject() as IAuditLog;
    }
    const log: IAuditLog = {
      _id: this.generateId(),
      actorId: data.actorId || 'system',
      actorRole: data.actorRole || 'system',
      action: data.action!,
      targetId: data.targetId,
      ip: data.ip || '127.0.0.1',
      metadata: data.metadata,
      timestamp: new Date(),
    };
    this.auditLogs.unshift(log);
    return log;
  }

  async getAuditLogs(limit = 100): Promise<IAuditLog[]> {
    if (this.isMongoConnected) {
      return (await AuditLogModel.find().sort({ timestamp: -1 }).limit(limit).lean()) as IAuditLog[];
    }
    return this.auditLogs.slice(0, limit);
  }

  // --- Rooms (Event Rooms Platform) ---
  async findRoomBySlug(slug: string): Promise<IRoom | null> {
    if (this.isMongoConnected) {
      return (await RoomModel.findOne({ slug: slug.toLowerCase() }).lean()) as IRoom | null;
    }
    for (const room of this.rooms.values()) {
      if (room.slug.toLowerCase() === slug.toLowerCase()) return room;
    }
    return null;
  }

  async findRoomByCode(code: string): Promise<IRoom | null> {
    if (this.isMongoConnected) {
      return (await RoomModel.findOne({ roomCode: code.toUpperCase() }).lean()) as IRoom | null;
    }
    for (const room of this.rooms.values()) {
      if (room.roomCode.toUpperCase() === code.toUpperCase()) return room;
    }
    return null;
  }

  async findRoomById(id: string): Promise<IRoom | null> {
    if (this.isMongoConnected) {
      return (await RoomModel.findById(id).lean()) as IRoom | null;
    }
    return this.rooms.get(id) || null;
  }

  async findRoomsByHostId(hostId: string): Promise<IRoom[]> {
    if (this.isMongoConnected) {
      return (await RoomModel.find({ $or: [{ hostId }, { ownerId: hostId }] }).sort({ createdAt: -1 }).lean()) as IRoom[];
    }
    return Array.from(this.rooms.values())
      .filter(r => r.hostId === hostId || r.ownerId === hostId)
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }

  async getAllRooms(): Promise<IRoom[]> {
    if (this.isMongoConnected) {
      return (await RoomModel.find().lean()) as IRoom[];
    }
    return Array.from(this.rooms.values());
  }

  async createRoom(data: Partial<IRoom>): Promise<IRoom> {
    if (this.isMongoConnected) {
      const doc = await RoomModel.create(data);
      return doc.toObject() as IRoom;
    }
    const id = this.generateId();
    const hostId = data.hostId || data.ownerId || 'host_guest';
    const honoreeName = data.honoreeName || data.partner1Name || 'Host';
    const isPublic = data.isPublic !== undefined ? data.isPublic : (data.privacy ? data.privacy === 'public' : true);
    const privacy = data.privacy || (isPublic ? 'public' : 'private');

    const room: IRoom = {
      _id: id,
      hostId,
      ownerId: hostId,
      eventType: data.eventType || 'wedding',
      title: data.title || `${honoreeName}'s Celebration`,
      honoreeName,
      partner1Name: honoreeName,
      partner2Name: data.partner2Name,
      date: data.date ? new Date(data.date) : new Date(),
      venue: data.venue || '',
      city: data.city || 'India',
      coverImageUrl: data.coverImageUrl,
      story: data.story || '',
      privacy,
      isPublic,
      slug: (data.slug || `room-${Date.now()}`).toLowerCase(),
      roomCode: (data.roomCode || `ROOM${Math.floor(1000 + Math.random() * 9000)}`).toUpperCase(),
      qrUrl: data.qrUrl,
      expiresAt: data.expiresAt ? new Date(data.expiresAt) : undefined,
      status: data.status || 'active',
      isWishlistEnabled: data.isWishlistEnabled !== undefined ? data.isWishlistEnabled : true,
      showAmounts: data.showAmounts !== undefined ? data.showAmounts : true,
      kycVerified: data.kycVerified !== undefined ? data.kycVerified : false,
      invitationCardUrl: data.invitationCardUrl,
      payoutAccountRef: data.payoutAccountRef,
      bankDetails: data.bankDetails,
      memberCount: data.memberCount || 1,
      totalTarget: data.totalTarget || 0,
      totalRaised: 0,
      contributorCount: 0,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.rooms.set(room._id, room);
    this.weddings.set(room._id, room); // Backward compatibility
    return room;
  }

  async updateRoom(id: string, data: Partial<IRoom>): Promise<IRoom | null> {
    if (this.isMongoConnected) {
      return (await RoomModel.findByIdAndUpdate(id, data, { new: true }).lean()) as IRoom | null;
    }
    const current = this.rooms.get(id) || this.weddings.get(id);
    if (!current) return null;
    const updated = { ...current, ...data, updatedAt: new Date() };
    this.rooms.set(id, updated);
    this.weddings.set(id, updated);
    return updated;
  }

  async deleteRoom(id: string): Promise<boolean> {
    if (this.isMongoConnected) {
      const res = await RoomModel.findByIdAndDelete(id);
      return !!res;
    }
    this.rooms.delete(id);
    this.weddings.delete(id);
    return true;
  }

  // Backward-compatibility wrappers for Weddings
  async findWeddingBySlug(slug: string): Promise<IWedding | null> {
    return this.findRoomBySlug(slug);
  }

  async findWeddingById(id: string): Promise<IWedding | null> {
    return this.findRoomById(id);
  }

  async findWeddingByOwnerId(ownerId: string): Promise<IWedding | null> {
    const rooms = await this.findRoomsByHostId(ownerId);
    return rooms.length > 0 ? rooms[0] : null;
  }

  async getAllWeddings(): Promise<IWedding[]> {
    return this.getAllRooms();
  }

  async createWedding(data: Partial<IWedding>): Promise<IWedding> {
    return this.createRoom({
      ...data,
      hostId: data.ownerId || data.hostId,
      honoreeName: data.partner1Name || data.honoreeName,
      eventType: data.eventType || 'wedding',
    });
  }

  async updateWedding(id: string, data: Partial<IWedding>): Promise<IWedding | null> {
    return this.updateRoom(id, data);
  }

  // --- Room Members ---
  async getRoomMembers(roomId: string): Promise<IRoomMember[]> {
    if (this.isMongoConnected) {
      return (await RoomMemberModel.find({ roomId, status: { $ne: 'removed' } }).sort({ joinedAt: 1 }).lean()) as IRoomMember[];
    }
    return Array.from(this.roomMembers.values())
      .filter(m => m.roomId === roomId && m.status !== 'removed')
      .sort((a, b) => a.joinedAt.getTime() - b.joinedAt.getTime());
  }

  async getRoomMember(roomId: string, identifier: string): Promise<IRoomMember | null> {
    if (this.isMongoConnected) {
      return (await RoomMemberModel.findOne({
        roomId,
        $or: [{ _id: identifier }, { userId: identifier }, { guestId: identifier }],
        status: { $ne: 'removed' },
      }).lean()) as IRoomMember | null;
    }
    for (const m of this.roomMembers.values()) {
      if (m.roomId === roomId && (m._id === identifier || m.userId === identifier || m.guestId === identifier) && m.status !== 'removed') {
        return m;
      }
    }
    return null;
  }

  async addRoomMember(data: Partial<IRoomMember>): Promise<IRoomMember> {
    if (this.isMongoConnected) {
      const doc = await RoomMemberModel.create(data);
      await this.updateRoomMemberCount(data.roomId!);
      return doc.toObject() as IRoomMember;
    }
    const member: IRoomMember = {
      _id: this.generateId(),
      roomId: data.roomId!,
      userId: data.userId,
      guestId: data.guestId,
      displayName: data.displayName || 'Guest',
      phone: data.phone,
      email: data.email,
      avatarUrl: data.avatarUrl,
      role: data.role || 'member',
      status: data.status || 'approved',
      rsvpStatus: data.rsvpStatus || 'none',
      guestCount: data.guestCount || 1,
      joinedAt: new Date(),
      updatedAt: new Date(),
    };
    this.roomMembers.set(member._id, member);
    await this.updateRoomMemberCount(member.roomId);
    return member;
  }

  async updateRoomMember(memberId: string, data: Partial<IRoomMember>): Promise<IRoomMember | null> {
    if (this.isMongoConnected) {
      const doc = await RoomMemberModel.findByIdAndUpdate(memberId, data, { new: true }).lean();
      if (doc) await this.updateRoomMemberCount(doc.roomId);
      return doc as IRoomMember | null;
    }
    const current = this.roomMembers.get(memberId);
    if (!current) return null;
    const updated = { ...current, ...data, updatedAt: new Date() };
    this.roomMembers.set(memberId, updated);
    await this.updateRoomMemberCount(updated.roomId);
    return updated;
  }

  async removeRoomMember(roomId: string, memberId: string): Promise<boolean> {
    const updated = await this.updateRoomMember(memberId, { status: 'removed' });
    return !!updated;
  }

  async updateRoomMemberCount(roomId: string): Promise<void> {
    const members = await this.getRoomMembers(roomId);
    const approvedCount = members.filter(m => m.status === 'approved').length;
    await this.updateRoom(roomId, { memberCount: Math.max(1, approvedCount) });
  }

  // --- Room Posts (Guestbook Blessings, Shared Album, Host Announcements) ---
  async getRoomPosts(roomId: string, type?: PostType): Promise<IRoomPost[]> {
    const query: any = { roomId };
    if (type) query.type = type;

    if (this.isMongoConnected) {
      return (await RoomPostModel.find(query).sort({ isPinned: -1, createdAt: -1 }).lean()) as IRoomPost[];
    }
    return Array.from(this.roomPosts.values())
      .filter(p => p.roomId === roomId && (!type || p.type === type))
      .sort((a, b) => {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.createdAt.getTime() - a.createdAt.getTime();
      });
  }

  async createRoomPost(data: Partial<IRoomPost>): Promise<IRoomPost> {
    if (this.isMongoConnected) {
      const doc = await RoomPostModel.create(data);
      return doc.toObject() as IRoomPost;
    }
    const post: IRoomPost = {
      _id: this.generateId(),
      roomId: data.roomId!,
      memberId: data.memberId,
      authorName: data.authorName || 'Guest',
      authorRole: data.authorRole || 'member',
      type: data.type || 'blessing',
      content: data.content || '',
      mediaUrl: data.mediaUrl,
      isPinned: !!data.isPinned,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.roomPosts.set(post._id, post);
    return post;
  }

  async deleteRoomPost(id: string): Promise<boolean> {
    if (this.isMongoConnected) {
      const res = await RoomPostModel.findByIdAndDelete(id);
      return !!res;
    }
    return this.roomPosts.delete(id);
  }

  // --- Wishlist Items ---
  async getWishlistItems(roomIdOrWeddingId: string): Promise<IWishlistItem[]> {
    if (this.isMongoConnected) {
      return (await WishlistItemModel.find({
        $or: [{ roomId: roomIdOrWeddingId }, { weddingId: roomIdOrWeddingId }],
        status: { $ne: 'archived' },
      }).sort({ priority: 1, createdAt: 1 }).lean()) as IWishlistItem[];
    }
    return Array.from(this.wishlistItems.values())
      .filter(item => (item.roomId === roomIdOrWeddingId || item.weddingId === roomIdOrWeddingId) && item.status !== 'archived')
      .sort((a, b) => a.priority - b.priority);
  }

  async getWishlistItemById(id: string): Promise<IWishlistItem | null> {
    if (this.isMongoConnected) {
      return (await WishlistItemModel.findById(id).lean()) as IWishlistItem | null;
    }
    return this.wishlistItems.get(id) || null;
  }

  async createWishlistItem(data: Partial<IWishlistItem>): Promise<IWishlistItem> {
    const parentId = data.roomId || data.weddingId!;
    const itemData = {
      ...data,
      roomId: parentId,
      weddingId: parentId,
    };
    if (this.isMongoConnected) {
      const doc = await WishlistItemModel.create(itemData);
      await this.recalculateWeddingTotals(parentId);
      return doc.toObject() as IWishlistItem;
    }
    const item: IWishlistItem = {
      _id: this.generateId(),
      roomId: parentId,
      weddingId: parentId,
      title: data.title!,
      description: data.description || '',
      icon: data.icon || 'gift',
      targetAmount: data.targetAmount!,
      raisedAmount: data.raisedAmount || 0,
      contributorCount: data.contributorCount || 0,
      priority: data.priority || 1,
      deadline: data.deadline ? new Date(data.deadline) : undefined,
      status: data.status || 'active',
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.wishlistItems.set(item._id, item);
    await this.recalculateWeddingTotals(parentId);
    return item;
  }

  async updateWishlistItem(id: string, data: Partial<IWishlistItem>): Promise<IWishlistItem | null> {
    if (this.isMongoConnected) {
      const doc = await WishlistItemModel.findByIdAndUpdate(id, data, { new: true }).lean();
      if (doc) await this.recalculateWeddingTotals(doc.roomId || doc.weddingId!);
      return doc as IWishlistItem | null;
    }
    const current = this.wishlistItems.get(id);
    if (!current) return null;
    const updated = { ...current, ...data, updatedAt: new Date() };
    this.wishlistItems.set(id, updated);
    await this.recalculateWeddingTotals(updated.roomId || updated.weddingId!);
    return updated;
  }

  async deleteWishlistItem(id: string): Promise<boolean> {
    if (this.isMongoConnected) {
      const doc = await WishlistItemModel.findByIdAndUpdate(id, { status: 'archived' });
      if (doc) await this.recalculateWeddingTotals(doc.roomId || doc.weddingId!);
      return !!doc;
    }
    const current = this.wishlistItems.get(id);
    if (!current) return false;
    current.status = 'archived';
    this.wishlistItems.set(id, current);
    await this.recalculateWeddingTotals(current.roomId || current.weddingId!);
    return true;
  }

  // --- Contributions ---
  async createContribution(data: Partial<IContribution>): Promise<IContribution> {
    const parentId = data.roomId || data.weddingId!;
    const itemData = {
      ...data,
      roomId: parentId,
      weddingId: parentId,
    };
    if (this.isMongoConnected) {
      const doc = await ContributionModel.create(itemData);
      return doc.toObject() as IContribution;
    }
    const contribution: IContribution = {
      _id: this.generateId(),
      roomId: parentId,
      weddingId: parentId,
      itemId: data.itemId,
      itemTitle: data.itemTitle,
      guestName: data.guestName!,
      guestPhone: data.guestPhone,
      guestEmail: data.guestEmail,
      amount: data.amount!,
      platformFee: data.platformFee || 0,
      netAmount: data.netAmount || data.amount!,
      message: data.message || '',
      isAnonymous: !!data.isAnonymous,
      paymentProvider: data.paymentProvider || 'razorpay',
      orderId: data.orderId!,
      paymentId: data.paymentId,
      signature: data.signature,
      status: data.status || 'created',
      receiptNumber: 'GF-REC-' + Math.floor(100000 + Math.random() * 900000),
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.contributions.set(contribution._id, contribution);
    return contribution;
  }

  async findContributionByOrderId(orderId: string): Promise<IContribution | null> {
    if (this.isMongoConnected) {
      return (await ContributionModel.findOne({ orderId }).lean()) as IContribution | null;
    }
    for (const c of this.contributions.values()) {
      if (c.orderId === orderId) return c;
    }
    return null;
  }

  async findContributionById(id: string): Promise<IContribution | null> {
    if (this.isMongoConnected) {
      return (await ContributionModel.findById(id).lean()) as IContribution | null;
    }
    return this.contributions.get(id) || null;
  }

  async updateContribution(id: string, data: Partial<IContribution>): Promise<IContribution | null> {
    if (this.isMongoConnected) {
      return (await ContributionModel.findByIdAndUpdate(id, data, { new: true }).lean()) as IContribution | null;
    }
    const current = this.contributions.get(id);
    if (!current) return null;
    const updated = { ...current, ...data, updatedAt: new Date() };
    this.contributions.set(id, updated);
    return updated;
  }

  async getContributionsByWedding(roomIdOrWeddingId: string, limit = 100): Promise<IContribution[]> {
    if (this.isMongoConnected) {
      return (await ContributionModel.find({
        $or: [{ roomId: roomIdOrWeddingId }, { weddingId: roomIdOrWeddingId }],
        status: 'paid',
      }).sort({ createdAt: -1 }).limit(limit).lean()) as IContribution[];
    }
    return Array.from(this.contributions.values())
      .filter(c => (c.roomId === roomIdOrWeddingId || c.weddingId === roomIdOrWeddingId) && c.status === 'paid')
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
      .slice(0, limit);
  }

  async getAllContributions(): Promise<IContribution[]> {
    if (this.isMongoConnected) {
      return (await ContributionModel.find().sort({ createdAt: -1 }).lean()) as IContribution[];
    }
    return Array.from(this.contributions.values()).sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }

  // --- Payouts ---
  async createPayout(data: Partial<IPayout>): Promise<IPayout> {
    const parentId = data.roomId || data.weddingId!;
    const itemData = { ...data, roomId: parentId, weddingId: parentId };
    if (this.isMongoConnected) {
      const doc = await PayoutModel.create(itemData);
      return doc.toObject() as IPayout;
    }
    const payout: IPayout = {
      _id: this.generateId(),
      roomId: parentId,
      weddingId: parentId,
      amount: data.amount!,
      status: data.status || 'pending',
      providerRef: data.providerRef,
      bankAccountRef: data.bankAccountRef,
      notes: data.notes,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.payouts.set(payout._id, payout);
    return payout;
  }

  async getPayoutsByWedding(roomIdOrWeddingId: string): Promise<IPayout[]> {
    if (this.isMongoConnected) {
      return (await PayoutModel.find({
        $or: [{ roomId: roomIdOrWeddingId }, { weddingId: roomIdOrWeddingId }],
      }).sort({ createdAt: -1 }).lean()) as IPayout[];
    }
    return Array.from(this.payouts.values())
      .filter(p => p.roomId === roomIdOrWeddingId || p.weddingId === roomIdOrWeddingId)
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }

  // --- Reports (Abuse & Anti-Fraud) ---
  async createReport(data: Partial<IReport>): Promise<IReport> {
    const parentId = data.roomId || data.weddingId!;
    const itemData = { ...data, roomId: parentId, weddingId: parentId };
    if (this.isMongoConnected) {
      const doc = await ReportModel.create(itemData);
      return doc.toObject() as IReport;
    }
    const report: IReport = {
      _id: this.generateId(),
      roomId: parentId,
      weddingId: parentId,
      reporterName: data.reporterName || 'Anonymous',
      reporterContact: data.reporterContact,
      reason: data.reason!,
      details: data.details,
      status: data.status || 'pending',
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.reports.set(report._id, report);
    return report;
  }

  async getReports(): Promise<IReport[]> {
    if (this.isMongoConnected) {
      return (await ReportModel.find().sort({ createdAt: -1 }).lean()) as IReport[];
    }
    return Array.from(this.reports.values()).sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }

  // Recalculate totals
  async recalculateWeddingTotals(roomIdOrWeddingId: string): Promise<void> {
    const items = await this.getWishlistItems(roomIdOrWeddingId);
    const totalTarget = items.reduce((acc, curr) => acc + curr.targetAmount, 0);

    const paidContributions = Array.from(this.contributions.values())
      .filter(c => (c.roomId === roomIdOrWeddingId || c.weddingId === roomIdOrWeddingId) && c.status === 'paid');
    const totalRaised = paidContributions.reduce((acc, curr) => acc + curr.amount, 0);
    const contributorCount = paidContributions.length;

    await this.updateRoom(roomIdOrWeddingId, {
      totalTarget,
      totalRaised,
      contributorCount,
    });
  }

  // Clear for tests
  async reset() {
    this.users.clear();
    this.rooms.clear();
    this.weddings.clear();
    this.roomMembers.clear();
    this.roomPosts.clear();
    this.wishlistItems.clear();
    this.contributions.clear();
    this.payouts.clear();
    this.kycRecords.clear();
    this.auditLogs = [];
    this.reports.clear();
  }
}

export const store = new StoreService();
