import { Router } from 'express';
import { RoomController } from '../controllers/room.controller';
import { optionalAuthenticateJwt } from '../middlewares/auth.middleware';

const router = Router();

// Templates listing
router.get('/templates', RoomController.getTemplates);

// Room creation
router.post('/', optionalAuthenticateJwt, RoomController.createRoom);

// Get room details by slug or roomCode
router.get('/:slugOrCode', optionalAuthenticateJwt, RoomController.getRoom);

// Join room (public instant / private pending)
router.post('/:id/join', optionalAuthenticateJwt, RoomController.joinRoom);

// Member management
router.get('/:id/members', optionalAuthenticateJwt, RoomController.getMembers);
router.patch('/:id/members/:memberId', optionalAuthenticateJwt, RoomController.updateMemberStatus);

// Wishlist
router.get('/:id/wishlist', optionalAuthenticateJwt, RoomController.getWishlist);

// RSVP
router.post('/:id/rsvp', optionalAuthenticateJwt, RoomController.submitRsvp);

// Posts (blessings, album photos, announcements)
router.get('/:id/posts', optionalAuthenticateJwt, RoomController.getPosts);
router.post('/:id/posts', optionalAuthenticateJwt, RoomController.createPost);

// Host controls
router.post('/:id/regenerate-qr', optionalAuthenticateJwt, RoomController.regenerateQr);
router.patch('/:id/lock', optionalAuthenticateJwt, RoomController.lockRoom);
router.delete('/:id', optionalAuthenticateJwt, RoomController.deleteRoom);

export default router;
