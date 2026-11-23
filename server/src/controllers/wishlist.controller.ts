import { Response } from 'express';
import { z } from 'zod';
import { store } from '../services/store.service';
import { socketService } from '../services/socket.service';
import { AuthenticatedRequest } from '../middlewares/auth.middleware';

const createItemSchema = z.object({
  title: z.string().min(1, 'Item title is required'),
  description: z.string().optional(),
  icon: z.string().default('gift'),
  targetAmount: z.number().min(100, 'Target amount must be at least ₹100'),
  priority: z.number().default(1),
  deadline: z.string().optional(),
});

const updateItemSchema = z.object({
  title: z.string().optional(),
  description: z.string().optional(),
  icon: z.string().optional(),
  targetAmount: z.number().min(100).optional(),
  priority: z.number().optional(),
  deadline: z.string().optional(),
  status: z.enum(['active', 'funded', 'archived']).optional(),
});

export class WishlistController {
  static async getItems(req: AuthenticatedRequest, res: Response): Promise<void> {
    const ownerId = req.user!._id;
    const wedding = await store.findWeddingByOwnerId(ownerId);

    if (!wedding) {
      res.status(404).json({ success: false, message: 'Wedding not found' });
      return;
    }

    const items = await store.getWishlistItems(wedding._id);
    res.json({ success: true, items });
  }

  static async createItem(req: AuthenticatedRequest, res: Response): Promise<void> {
    const data = createItemSchema.parse(req.body);
    const ownerId = req.user!._id;
    const wedding = await store.findWeddingByOwnerId(ownerId);

    if (!wedding) {
      res.status(404).json({ success: false, message: 'Wedding not found. Create a wedding first.' });
      return;
    }

    const item = await store.createWishlistItem({
      ...data,
      weddingId: wedding._id,
      deadline: data.deadline ? new Date(data.deadline) : undefined,
    });

    // Notify connected clients
    const allItems = await store.getWishlistItems(wedding._id);
    socketService.broadcastWishlistUpdate(wedding._id, allItems);

    res.status(201).json({
      success: true,
      message: 'Wishlist dream goal added!',
      item,
    });
  }

  static async updateItem(req: AuthenticatedRequest, res: Response): Promise<void> {
    const id = req.params.id as string;
    const data = updateItemSchema.parse(req.body);
    const ownerId = req.user!._id;
    const wedding = await store.findWeddingByOwnerId(ownerId);

    if (!wedding) {
      res.status(404).json({ success: false, message: 'Wedding not found' });
      return;
    }

    const currentItem = await store.getWishlistItemById(id);
    if (!currentItem || currentItem.weddingId !== wedding._id) {
      res.status(404).json({ success: false, message: 'Wishlist item not found' });
      return;
    }

    const updated = await store.updateWishlistItem(id, {
      ...data,
      deadline: data.deadline ? new Date(data.deadline) : undefined,
    });

    const allItems = await store.getWishlistItems(wedding._id);
    socketService.broadcastWishlistUpdate(wedding._id, allItems);

    res.json({
      success: true,
      message: 'Wishlist item updated',
      item: updated,
    });
  }

  static async deleteItem(req: AuthenticatedRequest, res: Response): Promise<void> {
    const id = req.params.id as string;
    const ownerId = req.user!._id;
    const wedding = await store.findWeddingByOwnerId(ownerId);

    if (!wedding) {
      res.status(404).json({ success: false, message: 'Wedding not found' });
      return;
    }

    const currentItem = await store.getWishlistItemById(id);
    if (!currentItem || currentItem.weddingId !== wedding._id) {
      res.status(404).json({ success: false, message: 'Wishlist item not found' });
      return;
    }

    await store.deleteWishlistItem(id);

    const allItems = await store.getWishlistItems(wedding._id);
    socketService.broadcastWishlistUpdate(wedding._id, allItems);

    res.json({
      success: true,
      message: 'Wishlist item deleted',
    });
  }
}
