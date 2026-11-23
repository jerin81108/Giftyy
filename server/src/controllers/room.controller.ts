import { Response } from 'express';
import QRCode from 'qrcode';
import { AuthenticatedRequest } from '../middlewares/auth.middleware';
import { store } from '../services/store.service';
import { firebaseService } from '../services/firebase.service';
import { EVENT_TEMPLATES, IEventTemplate } from '../constants/eventTemplates';
import { IRoom, IRoomMember, IRoomPost, PostType, RsvpStatus } from '../models/types';
import { config } from '../config';

// Helper to generate unguessable slug and room code
function generateSlugAndCode(honoreeName: string, eventType: string): { slug: string; roomCode: string } {
  const cleanName = honoreeName
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '')
    .slice(0, 10) || 'celebration';
  const cleanEvent = eventType
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '-')
    .slice(0, 15) || 'event';
  const randomSuffix = Math.floor(1000 + Math.random() * 9000).toString();

  const slug = `${cleanName}-${cleanEvent}-${randomSuffix}`;
  const codePrefix = (cleanName.slice(0, 5) || 'GIFT').toUpperCase();
  const roomCode = `${codePrefix}${randomSuffix}`;

  return { slug, roomCode };
}

export class RoomController {
  // GET /api/rooms/templates
  static async getTemplates(_req: AuthenticatedRequest, res: Response): Promise<void> {
    res.json({
      success: true,
      templates: Object.values(EVENT_TEMPLATES),
    });
  }

  // POST /api/rooms
  static async createRoom(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const {
        eventType = 'custom',
        title,
        honoreeName,
        partner2Name,
        date,
        venue,
        city,
        coverImageUrl,
        story,
        privacy,
        isWishlistEnabled = true,
        showAmounts = true,
        initialWishlist,
      } = req.body;

      if (!honoreeName) {
        res.status(400).json({ success: false, message: 'Honoree or host name is required.' });
        return;
      }

      const template: IEventTemplate | undefined = EVENT_TEMPLATES[eventType];
      const isChild = template?.isChildEvent || false;

      // DPDP Child Safety: child-centric events default to private
      let finalPrivacy: 'public' | 'private' = 'public';
      if (privacy) {
        finalPrivacy = privacy;
      } else if (isChild || template?.isPrivateByDefault) {
        finalPrivacy = 'private';
      }

      const hostId = req.user?._id || req.body.hostId || 'host_' + Math.random().toString(36).substring(2, 9);
      const hostName = req.user?.name || req.body.hostName || honoreeName;

      const { slug, roomCode } = generateSlugAndCode(honoreeName, eventType);
      const joinLink = `${config.appBaseUrl}/r/${slug}`;
      const qrDataUrl = await QRCode.toDataURL(joinLink, {
        errorCorrectionLevel: 'M',
        margin: 2,
        color: { dark: '#000000', light: '#ffffff' },
      });

      const finalTitle = title || (template ? `${honoreeName}'s ${template.label}` : `${honoreeName}'s Celebration`);
      const finalStory = story || template?.defaultStory || `Welcome to ${finalTitle}!`;
      const finalCover = coverImageUrl || template?.defaultCoverUrl || 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?auto=format&fit=crop&w=1200&q=80';

      const room = await store.createRoom({
        hostId,
        eventType,
        title: finalTitle,
        honoreeName,
        partner2Name,
        date: date ? new Date(date) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        venue: venue || 'Venue Details TBA',
        city: city || 'India',
        coverImageUrl: finalCover,
        story: finalStory,
        privacy: finalPrivacy,
        isPublic: finalPrivacy === 'public',
        slug,
        roomCode,
        qrUrl: qrDataUrl,
        isWishlistEnabled,
        showAmounts,
        kycVerified: req.user?.kycStatus === 'verified',
      });

      // Add host as the first member with role 'host'
      await store.addRoomMember({
        roomId: room._id,
        userId: req.user?._id,
        displayName: hostName,
        phone: req.user?.phone,
        email: req.user?.email,
        role: 'host',
        status: 'approved',
      });

      // Seed pre-filled suggested wishlist items if wishlist enabled
      if (isWishlistEnabled) {
        const itemsToSeed = initialWishlist && Array.isArray(initialWishlist) && initialWishlist.length > 0
          ? initialWishlist
          : template?.suggestedWishlist || [];

        for (let i = 0; i < itemsToSeed.length; i++) {
          const item = itemsToSeed[i];
          await store.createWishlistItem({
            roomId: room._id,
            weddingId: room._id,
            title: item.title,
            description: item.description,
            icon: item.icon || 'gift',
            targetAmount: item.amount || item.targetAmount || 10000,
            priority: i + 1,
          });
        }
      }

      res.status(201).json({
        success: true,
        message: 'Event Room created successfully!',
        room,
        joinLink,
        roomCode,
        qrUrl: qrDataUrl,
      });
    } catch (error) {
      res.status(500).json({ success: false, message: 'Failed to create room', error: (error as Error).message });
    }
  }

  // GET /api/rooms/:slugOrCode
  static async getRoom(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const slugOrCode = (req.params.slugOrCode as string).trim();
      let room = await store.findRoomBySlug(slugOrCode);
      if (!room) {
        room = await store.findRoomByCode(slugOrCode);
      }

      if (!room) {
        res.status(404).json({ success: false, message: 'Room not found with provided link or code.' });
        return;
      }

      // Check requester identity & membership
      const requesterId = req.user?._id || (req.headers['x-guest-id'] as string) || (req.query.guestId as string);
      const isHost = req.user?._id && room.hostId === req.user._id;

      let member: IRoomMember | null = null;
      if (requesterId) {
        member = await store.getRoomMember(room._id, requesterId);
      }

      const isApproved = isHost || (member && member.status === 'approved');

      // Privacy protection for private or child rooms
      if (room.privacy === 'private' && !isApproved) {
        const template = EVENT_TEMPLATES[room.eventType];
        const isChild = template?.isChildEvent || false;

        res.json({
          success: true,
          room: {
            _id: room._id,
            title: room.title,
            eventType: room.eventType,
            date: room.date,
            venue: 'Private Event (Address visible after host approval)',
            city: room.city,
            coverImageUrl: isChild ? template?.defaultCoverUrl : room.coverImageUrl,
            privacy: 'private',
            slug: room.slug,
            roomCode: room.roomCode,
            requiresApproval: true,
            isWishlistEnabled: room.isWishlistEnabled,
            memberCount: room.memberCount,
            membershipStatus: member?.status || 'none',
          },
          membershipStatus: member?.status || 'none',
          isApproved: false,
        });
        return;
      }

      res.json({
        success: true,
        room,
        membershipStatus: isHost ? 'approved' : (member?.status || 'none'),
        role: isHost ? 'host' : (member?.role || 'guest'),
        isApproved: true,
      });
    } catch (error) {
      res.status(500).json({ success: false, message: 'Failed to fetch room details', error: (error as Error).message });
    }
  }

  // POST /api/rooms/:id/join
  static async joinRoom(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const roomId = req.params.id as string;
      const room = await store.findRoomById(roomId);
      if (!room) {
        res.status(404).json({ success: false, message: 'Room not found.' });
        return;
      }

      if (room.status === 'locked' || room.status === 'archived') {
        res.status(400).json({ success: false, message: 'This room is currently closed for new joins.' });
        return;
      }

      const { displayName, phone, email, avatarUrl, guestId } = req.body;
      if (!displayName) {
        res.status(400).json({ success: false, message: 'Display name is required to join.' });
        return;
      }

      const userId = req.user?._id;
      const effectiveGuestId = guestId || (userId ? undefined : 'guest_' + Math.random().toString(36).substring(2, 10));

      // Check if already a member
      const existingMember = await store.getRoomMember(roomId, (userId || effectiveGuestId)!);
      if (existingMember) {
        res.json({
          success: true,
          message: existingMember.status === 'approved' ? 'You are already an approved member of this room.' : 'Your join request is awaiting host approval.',
          member: existingMember,
          status: existingMember.status,
          requiresApproval: existingMember.status === 'pending',
        });
        return;
      }

      // Public rooms auto-approve; Private rooms are pending approval
      const status = room.privacy === 'public' ? 'approved' : 'pending';

      const newMember = await store.addRoomMember({
        roomId,
        userId,
        guestId: effectiveGuestId,
        displayName: displayName.trim(),
        phone: phone || req.user?.phone,
        email: email || req.user?.email,
        avatarUrl,
        role: 'member',
        status,
        rsvpStatus: 'none',
        guestCount: 1,
      });

      // Notify host of pending join request
      if (status === 'pending') {
        store.findUserById(room.hostId).then(host => {
          if (host?.fcmToken) {
            firebaseService.sendPushNotification(host.fcmToken, {
              title: `Join Request: ${room.title}`,
              body: `${displayName} requested to join your room. Tap to review.`,
            }, { roomId: room._id, slug: room.slug, type: 'join_request' });
          }
        }).catch(() => {});
      }

      res.status(201).json({
        success: true,
        message: status === 'approved' ? 'Joined room successfully!' : 'Join request sent! Awaiting host approval.',
        member: newMember,
        status: newMember.status,
        requiresApproval: status === 'pending',
      });
    } catch (error) {
      res.status(500).json({ success: false, message: 'Failed to join room', error: (error as Error).message });
    }
  }

  // GET /api/rooms/:id/members
  static async getMembers(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const roomId = req.params.id as string;
      const room = await store.findRoomById(roomId);
      if (!room) {
        res.status(404).json({ success: false, message: 'Room not found.' });
        return;
      }

      const requesterId = req.user?._id || (req.headers['x-guest-id'] as string) || (req.query.guestId as string);
      const isHost = req.user?._id && room.hostId === req.user._id;

      let member: IRoomMember | null = null;
      if (requesterId) {
        member = await store.getRoomMember(roomId, requesterId);
      }
      const canManage = isHost || (member && (member.role === 'host' || member.role === 'co_host'));

      const allMembers = await store.getRoomMembers(roomId);

      if (canManage) {
        res.json({
          success: true,
          members: allMembers,
          pendingRequests: allMembers.filter(m => m.status === 'pending'),
          approvedMembers: allMembers.filter(m => m.status === 'approved'),
        });
        return;
      }

      // Regular guests see only approved members
      const approvedOnly = allMembers.filter(m => m.status === 'approved');
      res.json({
        success: true,
        members: approvedOnly,
      });
    } catch (error) {
      res.status(500).json({ success: false, message: 'Failed to fetch members', error: (error as Error).message });
    }
  }

  // GET /api/rooms/:id/wishlist
  static async getWishlist(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const roomId = req.params.id as string;
      const items = await store.getWishlistItems(roomId);
      res.json({
        success: true,
        items,
      });
    } catch (error) {
      res.status(500).json({ success: false, message: 'Failed to fetch wishlist', error: (error as Error).message });
    }
  }

  // PATCH /api/rooms/:id/members/:memberId
  static async updateMemberStatus(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const { id: roomId, memberId } = req.params;
      const room = await store.findRoomById(roomId as string);
      if (!room) {
        res.status(404).json({ success: false, message: 'Room not found.' });
        return;
      }

      const { status, role } = req.body;
      const updated = await store.updateRoomMember(memberId as string, {
        ...(status && { status }),
        ...(role && { role }),
      });

      if (!updated) {
        res.status(404).json({ success: false, message: 'Member not found.' });
        return;
      }

      res.json({
        success: true,
        message: `Member ${status ? 'status updated to ' + status : ''} ${role ? 'role updated to ' + role : ''}`,
        member: updated,
      });
    } catch (error) {
      res.status(500).json({ success: false, message: 'Failed to update member status', error: (error as Error).message });
    }
  }

  // POST /api/rooms/:id/rsvp
  static async submitRsvp(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const roomId = req.params.id as string;
      const room = await store.findRoomById(roomId);
      if (!room) {
        res.status(404).json({ success: false, message: 'Room not found.' });
        return;
      }

      const { rsvpStatus, guestCount = 1, displayName, guestId } = req.body;
      if (!rsvpStatus || !['attending', 'not_attending', 'maybe'].includes(rsvpStatus)) {
        res.status(400).json({ success: false, message: 'Valid rsvpStatus (attending, not_attending, maybe) is required.' });
        return;
      }

      const requesterId = req.user?._id || guestId;
      let member = requesterId ? await store.getRoomMember(roomId, requesterId) : null;

      if (!member) {
        // Auto-register member on RSVP
        const name = displayName || req.user?.name || 'Guest';
        member = await store.addRoomMember({
          roomId,
          userId: req.user?._id,
          guestId: guestId || 'guest_' + Math.random().toString(36).substring(2, 9),
          displayName: name,
          role: 'member',
          status: room.privacy === 'public' ? 'approved' : 'pending',
          rsvpStatus: rsvpStatus as RsvpStatus,
          guestCount: Math.max(1, Number(guestCount) || 1),
        });
      } else {
        member = await store.updateRoomMember(member._id, {
          rsvpStatus: rsvpStatus as RsvpStatus,
          guestCount: Math.max(1, Number(guestCount) || 1),
        });
      }

      // Calculate RSVP tally
      const allMembers = await store.getRoomMembers(roomId);
      const attending = allMembers
        .filter(m => m.rsvpStatus === 'attending' && m.status === 'approved')
        .reduce((sum, m) => sum + (m.guestCount || 1), 0);
      const maybe = allMembers.filter(m => m.rsvpStatus === 'maybe' && m.status === 'approved').length;
      const notAttending = allMembers.filter(m => m.rsvpStatus === 'not_attending' && m.status === 'approved').length;

      // Notify host of RSVP update
      store.findUserById(room.hostId).then(host => {
        if (host?.fcmToken && member) {
          const statusText = rsvpStatus === 'attending'
            ? `${member.displayName} (+${(member.guestCount || 1) - 1}) confirmed attendance! 🎉`
            : rsvpStatus === 'maybe'
              ? `${member.displayName} marked Maybe 🤔`
              : `${member.displayName} cannot attend.`;
          firebaseService.sendPushNotification(host.fcmToken, {
            title: `RSVP: ${room.title}`,
            body: statusText,
          }, { roomId: room._id, slug: room.slug, type: 'rsvp' });
        }
      }).catch(() => {});

      res.json({
        success: true,
        message: 'RSVP submitted successfully!',
        member,
        tally: {
          attendingCount: attending,
          maybeCount: maybe,
          notAttendingCount: notAttending,
        },
      });
    } catch (error) {
      res.status(500).json({ success: false, message: 'Failed to submit RSVP', error: (error as Error).message });
    }
  }

  // GET /api/rooms/:id/posts
  static async getPosts(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const roomId = req.params.id as string;
      const type = req.query.type as PostType | undefined;
      const posts = await store.getRoomPosts(roomId, type);

      res.json({
        success: true,
        posts,
      });
    } catch (error) {
      res.status(500).json({ success: false, message: 'Failed to fetch posts', error: (error as Error).message });
    }
  }

  // POST /api/rooms/:id/posts
  static async createPost(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const roomId = req.params.id as string;
      const room = await store.findRoomById(roomId);
      if (!room) {
        res.status(404).json({ success: false, message: 'Room not found.' });
        return;
      }

      const { type = 'blessing', content = '', mediaUrl, authorName, memberId } = req.body;
      const finalAuthorName = authorName || req.user?.name || 'Guest';

      const isHost = req.user?._id && room.hostId === req.user._id;
      const authorRole = isHost ? 'host' : 'member';

      // Announcements can only be posted by hosts
      if (type === 'announcement' && !isHost) {
        res.status(403).json({ success: false, message: 'Only room hosts can post event announcements.' });
        return;
      }

      const post = await store.createRoomPost({
        roomId,
        memberId,
        authorName: finalAuthorName,
        authorRole,
        type: type as PostType,
        content,
        mediaUrl,
        isPinned: type === 'announcement',
      });

      // Broadcast announcement to topic or notify host of blessing
      if (type === 'announcement') {
        firebaseService.sendTopicNotification(`room_${room.slug}`, {
          title: `📢 Announcement: ${room.title}`,
          body: content ? content.slice(0, 120) : 'A new update was posted by the host.',
        }, { roomId: room._id, slug: room.slug, postId: post._id, type: 'announcement' }).catch(() => {});
      } else if (type === 'blessing' && !isHost) {
        store.findUserById(room.hostId).then(host => {
          if (host?.fcmToken) {
            firebaseService.sendPushNotification(host.fcmToken, {
              title: `New Blessing in ${room.title}! 💖`,
              body: `${finalAuthorName}: "${content ? content.slice(0, 80) : 'Shared a blessing'}"`,
            }, { roomId: room._id, slug: room.slug, postId: post._id, type: 'blessing' });
          }
        }).catch(() => {});
      }

      res.status(201).json({
        success: true,
        message: 'Post created successfully!',
        post,
      });
    } catch (error) {
      res.status(500).json({ success: false, message: 'Failed to create post', error: (error as Error).message });
    }
  }

  // POST /api/rooms/:id/regenerate-qr
  static async regenerateQr(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const roomId = req.params.id as string;
      const room = await store.findRoomById(roomId);
      if (!room) {
        res.status(404).json({ success: false, message: 'Room not found.' });
        return;
      }

      const { slug, roomCode } = generateSlugAndCode(room.honoreeName, room.eventType);
      const joinLink = `${config.appBaseUrl}/r/${slug}`;
      const qrDataUrl = await QRCode.toDataURL(joinLink, {
        errorCorrectionLevel: 'M',
        margin: 2,
        color: { dark: '#000000', light: '#ffffff' },
      });

      const updated = await store.updateRoom(roomId, {
        slug,
        roomCode,
        qrUrl: qrDataUrl,
      });

      res.json({
        success: true,
        message: 'Room link, code, and QR regenerated successfully. Previous link has been revoked.',
        slug,
        roomCode,
        qrUrl: qrDataUrl,
        joinLink,
        room: updated,
      });
    } catch (error) {
      res.status(500).json({ success: false, message: 'Failed to regenerate QR', error: (error as Error).message });
    }
  }

  // PATCH /api/rooms/:id/lock
  static async lockRoom(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const roomId = req.params.id as string;
      const updated = await store.updateRoom(roomId, { status: 'locked' });
      if (!updated) {
        res.status(404).json({ success: false, message: 'Room not found.' });
        return;
      }
      res.json({
        success: true,
        message: 'Room is now locked and read-only.',
        room: updated,
      });
    } catch (error) {
      res.status(500).json({ success: false, message: 'Failed to lock room', error: (error as Error).message });
    }
  }

  // DELETE /api/rooms/:id (DPDP Erasure Compliance)
  static async deleteRoom(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const roomId = req.params.id as string;
      const room = await store.findRoomById(roomId);
      if (!room) {
        res.status(404).json({ success: false, message: 'Room not found.' });
        return;
      }

      await store.deleteRoom(roomId);

      res.json({
        success: true,
        message: 'Room and all related data erased successfully in compliance with DPDP Act 2023.',
      });
    } catch (error) {
      res.status(500).json({ success: false, message: 'Failed to delete room', error: (error as Error).message });
    }
  }
}
