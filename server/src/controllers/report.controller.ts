import { Request, Response } from 'express';
import { z } from 'zod';
import { store } from '../services/store.service';

const reportSchema = z.object({
  reason: z.string().min(3, 'Reason is required (e.g. fake wedding, impersonation, scam)'),
  reporterName: z.string().default('Concerned Guest'),
  reporterContact: z.string().optional(),
  details: z.string().max(1000).optional(),
});

export class ReportController {
  static async reportWedding(req: Request, res: Response): Promise<void> {
    const slug = (req.params.slug as string).toLowerCase();
    const data = reportSchema.parse(req.body);

    const wedding = await store.findWeddingBySlug(slug);
    if (!wedding) {
      res.status(404).json({ success: false, message: 'Wedding not found' });
      return;
    }

    const report = await store.createReport({
      weddingId: wedding._id,
      reporterName: data.reporterName,
      reporterContact: data.reporterContact,
      reason: data.reason,
      details: data.details,
    });

    // Auto-flag wedding if multiple reports received
    const allReports = await store.getReports();
    const weddingReports = allReports.filter(r => r.weddingId === wedding._id);
    if (weddingReports.length >= 3) {
      await store.updateWedding(wedding._id, {
        status: 'flagged',
        isPublic: false,
      });
    }

    await store.createAuditLog({
      actorId: 'guest',
      actorRole: 'guest',
      action: 'wedding:reported_fraud',
      targetId: wedding._id,
      ip: req.ip || '127.0.0.1',
      metadata: { reason: data.reason, totalReports: weddingReports.length },
    });

    res.json({
      success: true,
      message: 'Thank you for keeping Giftyy safe. Our security & compliance team has received your report.',
      reportId: report._id,
    });
  }
}
