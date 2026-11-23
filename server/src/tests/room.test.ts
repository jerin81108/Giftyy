import { describe, it, expect, beforeAll, beforeEach } from 'vitest';
import request from 'supertest';
import { createApp } from '../app';
import { store } from '../services/store.service';
import { PdfService } from '../services/pdf.service';

describe('Event Rooms Platform & Safety Tests', () => {
  let app: any;

  beforeAll(() => {
    app = createApp();
  });

  beforeEach(async () => {
    await store.reset();
  });

  it('1. should return all 11 event templates with pre-filled metadata', async () => {
    const res = await request(app).get('/api/rooms/templates');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.templates).toBeInstanceOf(Array);
    expect(res.body.templates.length).toBeGreaterThanOrEqual(10);

    const earPiercing = res.body.templates.find((t: any) => t.type === 'ear_piercing');
    expect(earPiercing).toBeDefined();
    expect(earPiercing.isChildEvent).toBe(true);
    expect(earPiercing.isPrivateByDefault).toBe(true);
    expect(earPiercing.suggestedWishlist.length).toBeGreaterThan(0);
  });

  it('2. should create a Room with unguessable slug, uppercase code, QR data, and auto-seeded wishlist', async () => {
    const res = await request(app)
      .post('/api/rooms')
      .send({
        eventType: 'birthday',
        title: 'Arjun 30th Birthday Bash',
        honoreeName: 'Arjun',
        city: 'Mumbai',
        venue: 'Bandra Rooftop Lounge',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.room).toBeDefined();
    expect(res.body.room.slug).toMatch(/^arjun-birthday-\d{4}$/);
    expect(res.body.room.roomCode).toMatch(/^ARJUN\d{4}$/);
    expect(res.body.room.qrUrl).toMatch(/^data:image\/png;base64,/);
    expect(res.body.joinLink).toContain(res.body.room.slug);

    // Check wishlist items were auto-seeded
    const items = await store.getWishlistItems(res.body.room._id);
    expect(items.length).toBeGreaterThanOrEqual(2);
  });

  it('3. should enforce privacy protection by default for child-centric ceremonies', async () => {
    // Ear piercing ceremony (Karnavedha)
    const res = await request(app)
      .post('/api/rooms')
      .send({
        eventType: 'ear_piercing',
        title: "Ananya's Karnavedha",
        honoreeName: 'Ananya',
        city: 'Chennai',
      });

    expect(res.status).toBe(201);
    expect(res.body.room.privacy).toBe('private');
    expect(res.body.room.isPublic).toBe(false);

    // Unapproved guest requests room details
    const guestRes = await request(app)
      .get(`/api/rooms/${res.body.room.slug}`)
      .set('x-guest-id', 'stranger_123');

    expect(guestRes.status).toBe(200);
    expect(guestRes.body.room.requiresApproval).toBe(true);
    expect(guestRes.body.room.privacy).toBe('private');
    expect(guestRes.body.room.venue).toContain('Private Event');
    expect(guestRes.body.isApproved).toBe(false);
  });

  it('4. should lookup room by short room code case-insensitively', async () => {
    const room = await store.createRoom({
      title: 'Priya Ear Piercing',
      honoreeName: 'Priya',
      eventType: 'ear_piercing',
      slug: 'priya-ear-piercing-4821',
      roomCode: 'PRIYA4821',
      privacy: 'public',
      isPublic: true,
      city: 'Bengaluru',
    });

    const resLower = await request(app).get(`/api/rooms/priya4821`);
    expect(resLower.status).toBe(200);
    expect(resLower.body.room._id).toBe(room._id);

    const resUpper = await request(app).get(`/api/rooms/PRIYA4821`);
    expect(resUpper.status).toBe(200);
    expect(resUpper.body.room._id).toBe(room._id);
  });

  it('5. should manage join workflow: public rooms auto-approve, private rooms require host approval', async () => {
    const privateRoom = await store.createRoom({
      title: 'Baby Shower',
      honoreeName: 'Deepa',
      eventType: 'baby_shower',
      slug: 'deepa-shower-1122',
      roomCode: 'DEEPA1122',
      privacy: 'private',
      isPublic: false,
      city: 'Delhi',
      hostId: 'host_anita_1',
    });

    // 1. Guest joins private room -> status is 'pending'
    const joinRes = await request(app)
      .post(`/api/rooms/${privateRoom._id}/join`)
      .send({
        displayName: 'Kavita Aunty',
        guestId: 'guest_kavita_77',
      });

    expect(joinRes.status).toBe(201);
    expect(joinRes.body.status).toBe('pending');
    expect(joinRes.body.requiresApproval).toBe(true);
    const memberId = joinRes.body.member._id;

    // 2. Host approves join request
    const approveRes = await request(app)
      .patch(`/api/rooms/${privateRoom._id}/members/${memberId}`)
      .send({ status: 'approved' });

    expect(approveRes.status).toBe(200);
    expect(approveRes.body.member.status).toBe('approved');

    // 3. Member now has full approved access
    const verifiedGuestRes = await request(app)
      .get(`/api/rooms/${privateRoom.slug}`)
      .set('x-guest-id', 'guest_kavita_77');

    expect(verifiedGuestRes.status).toBe(200);
    expect(verifiedGuestRes.body.isApproved).toBe(true);
  });

  it('6. should track RSVP tally accurately with guest counts', async () => {
    const room = await store.createRoom({
      title: 'Griha Pravesh Puja',
      honoreeName: 'Sharma Family',
      eventType: 'housewarming',
      slug: 'sharma-housewarming-99',
      roomCode: 'SHARMA99',
      privacy: 'public',
      isPublic: true,
      city: 'Hyderabad',
    });

    // Guest 1: Attending with family of 3
    const rsvp1 = await request(app)
      .post(`/api/rooms/${room._id}/rsvp`)
      .send({
        displayName: 'Verma Family',
        guestId: 'guest_verma',
        rsvpStatus: 'attending',
        guestCount: 3,
      });

    expect(rsvp1.status).toBe(200);
    expect(rsvp1.body.tally.attendingCount).toBe(3);

    // Guest 2: Maybe
    const rsvp2 = await request(app)
      .post(`/api/rooms/${room._id}/rsvp`)
      .send({
        displayName: 'College Friend',
        guestId: 'guest_friend',
        rsvpStatus: 'maybe',
      });

    expect(rsvp2.status).toBe(200);
    expect(rsvp2.body.tally.attendingCount).toBe(3);
    expect(rsvp2.body.tally.maybeCount).toBe(1);
  });

  it('7. should allow guestbook blessings and album photos, and restrict announcements to hosts', async () => {
    const room = await store.createRoom({
      title: 'Graduation Celebration',
      honoreeName: 'Rohan',
      eventType: 'graduation',
      slug: 'rohan-grad-1234',
      roomCode: 'ROHAN1234',
      privacy: 'public',
      isPublic: true,
      city: 'Pune',
      hostId: 'host_rohan_id',
    });

    // Guest leaves a blessing
    const blessingRes = await request(app)
      .post(`/api/rooms/${room._id}/posts`)
      .send({
        type: 'blessing',
        content: 'Congratulations engineer! Sky is the limit 🚀',
        authorName: 'Sunil Uncle',
      });

    expect(blessingRes.status).toBe(201);
    expect(blessingRes.body.post.type).toBe('blessing');

    // Guest attempting to post host announcement without host auth gets 403
    const invalidAnnouncement = await request(app)
      .post(`/api/rooms/${room._id}/posts`)
      .send({
        type: 'announcement',
        content: 'Fake announcement',
        authorName: 'Random Guest',
      });

    expect(invalidAnnouncement.status).toBe(403);
  });

  it('8. should allow host to regenerate room QR and unguessable link, revoking the old one', async () => {
    const room = await store.createRoom({
      title: 'Anniversary Party',
      honoreeName: 'Meera',
      eventType: 'anniversary',
      slug: 'meera-anniversary-1111',
      roomCode: 'MEERA1111',
      privacy: 'public',
      isPublic: true,
      city: 'Goa',
    });

    const regenRes = await request(app)
      .post(`/api/rooms/${room._id}/regenerate-qr`)
      .send();

    expect(regenRes.status).toBe(200);
    expect(regenRes.body.slug).not.toBe('meera-anniversary-1111');
    expect(regenRes.body.roomCode).not.toBe('MEERA1111');
    expect(regenRes.body.qrUrl).toMatch(/^data:image\/png;base64,/);

    // Old slug should no longer exist
    const oldSlugLookup = await store.findRoomBySlug('meera-anniversary-1111');
    expect(oldSlugLookup).toBeNull();
  });

  it('9. should generate a print-ready invitation PDF card with Giftyy branding, QR code, and room code', async () => {
    const room = await store.createRoom({
      title: 'Priya Karnavedha Ceremony',
      honoreeName: 'Priya',
      eventType: 'ear_piercing',
      slug: 'priya-ear-piercing-4821',
      roomCode: 'PRIYA4821',
      date: new Date('2026-12-14'),
      venue: 'Sri Meenakshi Temple',
      city: 'Bengaluru',
      privacy: 'private',
      isPublic: false,
    });

    const pdfBuffer = await PdfService.generateRoomInviteCard(room);
    expect(pdfBuffer).toBeInstanceOf(Buffer);
    expect(pdfBuffer.length).toBeGreaterThan(1000);
    // PDF magic bytes '%PDF'
    expect(pdfBuffer.toString('utf-8', 0, 4)).toBe('%PDF');
  });
});
