import PDFDocument from 'pdfkit';
import QRCode from 'qrcode';
import { IRoom, IWedding } from '../models/types';
import { config } from '../config';

export class PdfService {
  static async generateRoomInviteCard(room: IRoom): Promise<Buffer> {
    const inviteUrl = `${config.appBaseUrl}/r/${room.slug}`;
    const qrBuffer = await QRCode.toBuffer(inviteUrl, {
      width: 240,
      margin: 1,
      color: {
        dark: '#000000',
        light: '#FFFFFF',
      },
    });

    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({
        size: 'A5',
        margin: 36,
      });

      const buffers: Buffer[] = [];
      doc.on('data', buffers.push.bind(buffers));
      doc.on('end', () => resolve(Buffer.concat(buffers)));
      doc.on('error', reject);

      // Dark background card
      doc.rect(0, 0, doc.page.width, doc.page.height).fill('#0B0B0B');

      // Golden Yellow Border accent
      doc.rect(20, 20, doc.page.width - 40, doc.page.height - 40)
        .lineWidth(2)
        .stroke('#FFC933');

      // Event Type Tagline
      const eventLabel = (room.eventType || 'CELEBRATION').toUpperCase().replace(/_/g, ' ');
      doc.fillColor('#FFC933')
        .fontSize(11)
        .font('Helvetica-Bold')
        .text(`GIFTYY · ${eventLabel} INVITATION`, 0, 44, { align: 'center', characterSpacing: 2 });

      doc.moveDown(0.4);

      // Event Title / Honoree Name
      const displayName = room.title || (room.partner2Name ? `${room.honoreeName} & ${room.partner2Name}` : `${room.honoreeName}'s Celebration`);
      doc.fillColor('#FFFFFF')
        .fontSize(22)
        .font('Helvetica-Bold')
        .text(displayName, { align: 'center' });

      doc.moveDown(0.2);

      // Date & City
      const formattedDate = new Date(room.date).toLocaleDateString('en-IN', {
        day: 'numeric',
        month: 'long',
        year: 'numeric',
      });

      const location = [room.venue, room.city].filter(Boolean).join(' · ');
      doc.fillColor('#A0A0A0')
        .fontSize(11)
        .font('Helvetica')
        .text(`${formattedDate} ${location ? `· ${location}` : ''}`, { align: 'center' });

      doc.moveDown(0.6);

      // Short Note
      doc.fillColor('#FFC933')
        .fontSize(12)
        .font('Helvetica-Bold')
        .text('Skip the gifts. Fund the dream.', { align: 'center' });

      doc.fillColor('#CCCCCC')
        .fontSize(10)
        .font('Helvetica')
        .text('Scan the QR code to join our room, RSVP, share blessings & support our wishlist goals.', { align: 'center' });

      // Embed QR code inside a stylish white pill box
      const qrY = doc.y + 14;
      const boxWidth = 190;
      const boxHeight = 190;
      const boxX = (doc.page.width - boxWidth) / 2;

      doc.roundedRect(boxX, qrY, boxWidth, boxHeight, 12).fill('#FFFFFF');
      doc.image(qrBuffer, boxX + 15, qrY + 15, { width: 160 });

      // Room Code Pill below QR
      const afterQrY = qrY + boxHeight + 14;
      doc.fillColor('#FFC933')
        .fontSize(13)
        .font('Helvetica-Bold')
        .text(`ROOM CODE: ${room.roomCode}`, 0, afterQrY, { align: 'center', characterSpacing: 1.5 });

      doc.moveDown(0.3);
      doc.fillColor('#888888')
        .fontSize(9)
        .font('Helvetica')
        .text(inviteUrl, { align: 'center' });

      doc.moveDown(0.5);
      doc.fillColor('#E0E0E0')
        .fontSize(9.5)
        .font('Helvetica-Oblique')
        .text('“Every blessing & contribution brings us closer to the dream ✨”', { align: 'center' });

      doc.end();
    });
  }

  // Backward-compatibility alias
  static async generateWeddingInviteCard(wedding: IWedding): Promise<Buffer> {
    return this.generateRoomInviteCard(wedding);
  }
}
