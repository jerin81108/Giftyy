import { Request, Response } from 'express';
import { z } from 'zod';
import QRCode from 'qrcode';
import { store } from '../services/store.service';
import { PdfService } from '../services/pdf.service';
import { config } from '../config';
import { AuthenticatedRequest } from '../middlewares/auth.middleware';

const createWeddingSchema = z.object({
  partner1Name: z.string().min(1, 'Partner 1 name is required'),
  partner2Name: z.string().min(1, 'Partner 2 name is required'),
  slug: z.string().min(3).regex(/^[a-z0-9-]+$/, 'Slug must only contain lowercase letters, numbers, and hyphens'),
  date: z.string().or(z.date()),
  city: z.string().min(1, 'City is required'),
  coverImageUrl: z.string().optional(),
  story: z.string().optional(),
  showAmounts: z.boolean().optional(),
});

export class WeddingController {
  static async createWedding(req: AuthenticatedRequest, res: Response): Promise<void> {
    const data = createWeddingSchema.parse(req.body);
    const ownerId = req.user!._id;

    const existingSlug = await store.findWeddingBySlug(data.slug);
    if (existingSlug) {
      res.status(400).json({ success: false, message: 'This wedding URL slug is already taken. Try another!' });
      return;
    }

    const wedding = await store.createWedding({
      ...data,
      ownerId,
      date: new Date(data.date),
    });

    res.status(201).json({
      success: true,
      message: 'Wedding wishlist created successfully!',
      wedding,
    });
  }

  static async getMyWedding(req: AuthenticatedRequest, res: Response): Promise<void> {
    const ownerId = req.user!._id;
    const wedding = await store.findWeddingByOwnerId(ownerId);

    if (!wedding) {
      res.status(404).json({ success: false, message: 'No wedding found for this account' });
      return;
    }

    const items = await store.getWishlistItems(wedding._id);
    const contributions = await store.getContributionsByWedding(wedding._id, 100);

    res.json({
      success: true,
      wedding,
      items,
      contributions,
    });
  }

  static async getPublicWeddingBySlug(req: Request, res: Response): Promise<void> {
    const slug = (req.params.slug as string).toLowerCase();
    const wedding = await store.findWeddingBySlug(slug);

    if (!wedding) {
      res.status(404).json({ success: false, message: 'Wedding wishlist not found' });
      return;
    }

    // Gate public page: Couple must be KYC verified to go public
    if (!wedding.isPublic || !wedding.kycVerified) {
      res.status(403).json({
        success: false,
        isDraft: true,
        message: 'This wedding wishlist is currently in draft. Host identity verification (KYC) is pending before public launch.',
      });
      return;
    }

    const items = await store.getWishlistItems(wedding._id);
    const contributions = await store.getContributionsByWedding(wedding._id, 20);

    // Format wishlist items with percentages and formatted amounts
    const formattedItems = items.map(item => {
      const percentFunded = item.targetAmount > 0 
        ? Math.min(100, Math.round((item.raisedAmount / item.targetAmount) * 100))
        : 0;

      return {
        ...item,
        percentFunded,
        isFullyFunded: item.raisedAmount >= item.targetAmount,
      };
    });

    // Public contributions (respect anonymous choice)
    const publicContributions = contributions.map(c => ({
      _id: c._id,
      guestName: c.isAnonymous ? 'Generous Friend' : c.guestName,
      amount: wedding.showAmounts ? c.amount : null,
      message: c.message,
      itemTitle: c.itemTitle,
      createdAt: c.createdAt,
    }));

    res.json({
      success: true,
      wedding: {
        _id: wedding._id,
        slug: wedding.slug,
        partner1Name: wedding.partner1Name,
        partner2Name: wedding.partner2Name,
        date: wedding.date,
        city: wedding.city,
        coverImageUrl: wedding.coverImageUrl,
        story: wedding.story,
        totalTarget: wedding.totalTarget,
        totalRaised: wedding.totalRaised,
        contributorCount: wedding.contributorCount,
        showAmounts: wedding.showAmounts,
      },
      items: formattedItems,
      recentContributions: publicContributions,
    });
  }

  static async updateWedding(req: AuthenticatedRequest, res: Response): Promise<void> {
    const ownerId = req.user!._id;
    const wedding = await store.findWeddingByOwnerId(ownerId);

    if (!wedding) {
      res.status(404).json({ success: false, message: 'Wedding not found' });
      return;
    }

    const updated = await store.updateWedding(wedding._id, req.body);
    res.json({
      success: true,
      message: 'Wedding details updated',
      wedding: updated,
    });
  }

  static async getShareDetails(req: Request, res: Response): Promise<void> {
    const slug = (req.params.slug as string).toLowerCase();
    const wedding = await store.findWeddingBySlug(slug);

    if (!wedding) {
      res.status(404).json({ success: false, message: 'Wedding not found' });
      return;
    }

    const shareUrl = `${config.appBaseUrl}/w/${wedding.slug}`;
    const qrDataUrl = await QRCode.toDataURL(shareUrl, {
      width: 400,
      margin: 2,
      color: {
        dark: '#FFC933',
        light: '#0B0B0B',
      },
    });

    const whatsappMessage = `✨ Celebrate ${wedding.partner1Name} & ${wedding.partner2Name}'s wedding! Instead of boxed gifts, contribute directly towards our Dream Wishlist: ${shareUrl}`;

    res.json({
      success: true,
      shareUrl,
      qrDataUrl,
      whatsappShareUrl: `https://api.whatsapp.com/send?text=${encodeURIComponent(whatsappMessage)}`,
      whatsappMessage,
      weddingTitle: `${wedding.partner1Name} & ${wedding.partner2Name}'s Dream Wishlist`,
    });
  }

  static async downloadPdfInvite(req: Request, res: Response): Promise<void> {
    const slug = (req.params.slug as string).toLowerCase();
    const wedding = await store.findWeddingBySlug(slug);

    if (!wedding) {
      res.status(404).json({ success: false, message: 'Wedding not found' });
      return;
    }

    const pdfBuffer = await PdfService.generateWeddingInviteCard(wedding);

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="${wedding.slug}-wishlist-invite.pdf"`);
    res.send(pdfBuffer);
  }
}
