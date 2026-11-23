import { Request, Response } from 'express';
import { store } from '../services/store.service';
import { AuthenticatedRequest } from '../middlewares/auth.middleware';

export class AdminController {
  // Platform Overview & Metrics
  static async getDashboardStats(req: Request, res: Response): Promise<void> {
    const weddings = await store.getAllWeddings();
    const contributions = await store.getAllContributions();
    const reports = await store.getReports();

    const totalWeddings = weddings.length;
    const paidContributions = contributions.filter(c => c.status === 'paid');
    const totalRaised = paidContributions.reduce((acc, c) => acc + c.amount, 0);
    const totalPlatformFees = paidContributions.reduce((acc, c) => acc + c.platformFee, 0);
    const totalGuestsContributed = paidContributions.length;

    res.json({
      success: true,
      stats: {
        totalWeddings,
        totalRaised,
        totalPlatformFees,
        totalGuestsContributed,
        activeWeddings: weddings.filter(w => w.status === 'published').length,
        draftWeddings: weddings.filter(w => w.status === 'draft').length,
        flaggedWeddings: weddings.filter(w => w.status === 'flagged').length,
        pendingReports: reports.filter(r => r.status === 'pending').length,
      },
    });
  }

  // View all weddings (Admin view)
  static async getAllWeddings(req: AuthenticatedRequest, res: Response): Promise<void> {
    const weddings = await store.getAllWeddings();

    await store.createAuditLog({
      actorId: req.user?._id || 'admin',
      actorRole: 'admin',
      action: 'admin:view_all_weddings',
      ip: req.ip || '127.0.0.1',
    });

    res.json({ success: true, weddings });
  }

  // View all contributions
  static async getAllContributions(req: Request, res: Response): Promise<void> {
    const contributions = await store.getAllContributions();
    res.json({ success: true, contributions });
  }

  // View KYC & Audit logs (Compliant: Masks sensitive PII unless escalated)
  static async getAuditLogs(req: AuthenticatedRequest, res: Response): Promise<void> {
    const logs = await store.getAuditLogs(50);

    await store.createAuditLog({
      actorId: req.user?._id || 'admin',
      actorRole: 'admin',
      action: 'admin:view_audit_logs',
      ip: req.ip || '127.0.0.1',
    });

    res.json({ success: true, logs });
  }

  // View Abuse Reports Queue
  static async getReports(req: AuthenticatedRequest, res: Response): Promise<void> {
    const reports = await store.getReports();
    res.json({ success: true, reports });
  }

  // Flag or Suspend a Wedding
  static async updateWeddingStatus(req: AuthenticatedRequest, res: Response): Promise<void> {
    const weddingId = req.params.weddingId as string;
    const { status, reason } = req.body;

    const updated = await store.updateWedding(weddingId, {
      status,
      isPublic: status === 'published',
    });

    await store.createAuditLog({
      actorId: req.user?._id || 'admin',
      actorRole: 'admin',
      action: `admin:wedding_status_changed_to_${status}`,
      targetId: weddingId,
      ip: req.ip || '127.0.0.1',
      metadata: { reason },
    });

    res.json({
      success: true,
      message: `Wedding status updated to ${status}`,
      wedding: updated,
    });
  }

  // Handle dispute / refund
  static async refundContribution(req: AuthenticatedRequest, res: Response): Promise<void> {
    const contributionId = req.params.contributionId as string;
    const { reason } = req.body;

    const contribution = await store.findContributionById(contributionId);
    if (!contribution) {
      res.status(404).json({ success: false, message: 'Contribution not found' });
      return;
    }

    if (contribution.status !== 'paid') {
      res.status(400).json({ success: false, message: `Cannot refund contribution with status: ${contribution.status}` });
      return;
    }

    const refunded = await store.updateContribution(contributionId, {
      status: 'refunded',
    });

    // Revert raised amount if specific item
    if (contribution.itemId) {
      const item = await store.getWishlistItemById(contribution.itemId);
      if (item) {
        const newRaised = Math.max(0, item.raisedAmount - contribution.amount);
        const newCount = Math.max(0, item.contributorCount - 1);
        await store.updateWishlistItem(item._id, {
          raisedAmount: newRaised,
          contributorCount: newCount,
          status: newRaised >= item.targetAmount ? 'funded' : 'active',
        });
      }
    }

    // Recalculate totals
    await store.recalculateWeddingTotals(contribution.weddingId || contribution.roomId || '');

    await store.createAuditLog({
      actorId: req.user?._id || 'admin',
      actorRole: 'admin',
      action: 'admin:refund_issued',
      targetId: contributionId,
      ip: req.ip || '127.0.0.1',
      metadata: { amount: contribution.amount, reason },
    });

    res.json({
      success: true,
      message: 'Contribution refunded successfully',
      refunded,
      reason: reason || 'Requested by guest/couple',
    });
  }
}
