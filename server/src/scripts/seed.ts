import QRCode from 'qrcode';
import { store } from '../services/store.service';
import { config } from '../config';

export const seedDatabase = async () => {
  console.log('🌱 Starting Giftyy Seed Script ("Skip the gifts. Fund the dream")...');

  await store.init();
  await store.reset();

  // 1. Create Couple User (Aisha & Kabir) - Fully KYC Verified
  const aishaUser = await store.createUser({
    phone: '9876543210',
    name: 'Aisha Sharma',
    email: 'aisha.kabir@example.com',
    dob: '1996-08-14',
    partnerName: 'Kabir Verma',
    city: 'Mumbai',
    role: 'couple',
    kycStatus: 'verified',
    kycProvider: 'digio',
    kycReferenceId: 'ref_kyc_aisha_2026',
    panLast4: '234F',
    maskedPan: 'ABCDE****F',
    aadhaarLast4: '9012',
    verifiedName: 'AISHA SHARMA',
    kycVerifiedAt: new Date(),
    consentVersion: 'v1.0',
    consentAt: new Date(),
  });
  console.log(`👤 Created KYC Verified Host: ${aishaUser.name} (+91-${aishaUser.phone}, PAN: ${aishaUser.maskedPan})`);

  // QR for wedding room
  const aishaJoinLink = `${config.appBaseUrl}/r/aisha-kabir`;
  const aishaQr = await QRCode.toDataURL(aishaJoinLink);

  // 2. Room 1: Wedding (Aisha & Kabir) - Public & Published
  const weddingRoom = await store.createRoom({
    hostId: aishaUser._id,
    ownerId: aishaUser._id,
    eventType: 'wedding',
    title: 'Aisha & Kabir Wedding',
    honoreeName: 'Aisha',
    partner1Name: 'Aisha',
    partner2Name: 'Kabir',
    date: new Date('2027-01-15T18:00:00.000Z'),
    venue: 'Fateh Garh Palace',
    city: 'Udaipur, Rajasthan',
    coverImageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=1200&q=80',
    story: "Skip the gifts. Fund the dream! We're so blessed to have you in our lives. Help us fund our dream memories together! ✨",
    privacy: 'public',
    isPublic: true,
    slug: 'aisha-kabir',
    roomCode: 'AISHA2027',
    qrUrl: aishaQr,
    status: 'active',
    kycVerified: true,
    showAmounts: true,
    isWishlistEnabled: true,
    memberCount: 5,
  });

  // Host member
  await store.addRoomMember({
    roomId: weddingRoom._id,
    userId: aishaUser._id,
    displayName: 'Aisha Sharma',
    phone: aishaUser.phone,
    role: 'host',
    status: 'approved',
    rsvpStatus: 'attending',
  });

  // Wishlist items for wedding room
  const honeymoon = await store.createWishlistItem({
    roomId: weddingRoom._id,
    weddingId: weddingRoom._id,
    title: 'Honeymoon in Europe',
    description: 'Rome, Paris & Switzerland romantic getaway',
    icon: 'plane',
    targetAmount: 300000,
    raisedAmount: 216000,
    contributorCount: 48,
    priority: 1, // Highlighted first yellow card!
    status: 'active',
  });

  const home = await store.createWishlistItem({
    roomId: weddingRoom._id,
    weddingId: weddingRoom._id,
    title: 'First home down payment',
    description: 'Building our cozy sanctuary together',
    icon: 'house',
    targetAmount: 1000000,
    raisedAmount: 180000,
    contributorCount: 22,
    priority: 2,
    status: 'active',
  });

  const japan = await store.createWishlistItem({
    roomId: weddingRoom._id,
    weddingId: weddingRoom._id,
    title: 'Trip to Japan',
    description: 'Tokyo street food, Kyoto temples & Mt. Fuji cherry blossoms',
    icon: 'mountain',
    targetAmount: 250000,
    raisedAmount: 45000,
    contributorCount: 9,
    priority: 3,
    status: 'active',
  });

  // Seed sample contributions
  const sampleWeddingGuests = [
    { name: 'Rahul & Priya', amount: 5000, message: 'Have the best time in Switzerland! So happy for you both ❤️', itemId: honeymoon._id, itemTitle: honeymoon.title },
    { name: 'Neha (Bride’s college gang)', amount: 10000, message: 'Eat lots of gelato in Rome for us! ✨', itemId: honeymoon._id, itemTitle: honeymoon.title },
    { name: 'Rohan Verma', amount: 2000, message: 'Wishing you a lifetime of love and happiness!', itemId: honeymoon._id, itemTitle: honeymoon.title },
    { name: 'Vikram & Ananya', amount: 5000, message: 'Cannot wait for the sangeet! Cheers to new beginnings 🥂', itemId: home._id, itemTitle: home.title },
    { name: 'Sameer K.', amount: 2000, message: 'Skip the gifts. Fund the dream! ✨', itemId: japan._id, itemTitle: japan.title },
    { name: 'Generous Uncle', amount: 25000, message: 'Blessings to both of you from all of us in Delhi.', itemId: home._id, itemTitle: home.title },
  ];

  for (const g of sampleWeddingGuests) {
    await store.createContribution({
      roomId: weddingRoom._id,
      weddingId: weddingRoom._id,
      itemId: g.itemId,
      itemTitle: g.itemTitle,
      guestName: g.name,
      amount: g.amount,
      netAmount: g.amount,
      platformFee: 0,
      message: g.message,
      isAnonymous: false,
      paymentProvider: 'razorpay',
      orderId: `order_seed_${Math.random().toString(36).substring(2, 9)}`,
      paymentId: `pay_seed_${Math.random().toString(36).substring(2, 9)}`,
      status: 'paid',
    });
  }
  await store.recalculateWeddingTotals(weddingRoom._id);
  console.log(`💍 Created Wedding Room: ${weddingRoom.title} (/r/${weddingRoom.slug}, Code: ${weddingRoom.roomCode}) [PUBLIC]`);

  // 3. Room 2: Child Ear Piercing Ceremony (Karnavedha) - Priya's Ear Piercing
  // Private child event: Parent is host, minor data not collected, photos protected
  const parentUser = await store.createUser({
    phone: '9845012345',
    name: 'Anita Sharma (Mother & Guardian)',
    email: 'anita.sharma@example.com',
    city: 'Bengaluru',
    role: 'couple',
    kycStatus: 'verified',
  });

  const priyaJoinLink = `${config.appBaseUrl}/r/priya-ear-piercing-4821`;
  const priyaQr = await QRCode.toDataURL(priyaJoinLink);

  const earPiercingRoom = await store.createRoom({
    hostId: parentUser._id,
    eventType: 'ear_piercing',
    title: "Priya's Karnavedha Ceremony",
    honoreeName: 'Priya',
    date: new Date('2026-12-14T10:30:00.000Z'),
    venue: 'Sri Meenakshi Temple Kalyana Mandapam, Jayanagar',
    city: 'Bengaluru',
    coverImageUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=1200&q=80',
    story: "Our little Priya is turning two! We are celebrating her traditional Karnavedha (ear piercing) ceremony. As our dearest family and friends, your presence and heartfelt blessings will protect and guide her on this auspicious milestone.",
    privacy: 'private', // Child event: private by default
    isPublic: false,
    slug: 'priya-ear-piercing-4821',
    roomCode: 'PRIYA4821',
    qrUrl: priyaQr,
    status: 'active',
    isWishlistEnabled: true,
    showAmounts: false, // amounts hidden from members for privacy
    kycVerified: true,
  });

  // Members of Priya's Room
  await store.addRoomMember({
    roomId: earPiercingRoom._id,
    userId: parentUser._id,
    displayName: 'Anita Sharma (Mother)',
    role: 'host',
    status: 'approved',
    rsvpStatus: 'attending',
    guestCount: 2,
  });

  await store.addRoomMember({
    roomId: earPiercingRoom._id,
    displayName: 'Suresh & Janaki Sharma (Grandparents)',
    role: 'co_host',
    status: 'approved',
    rsvpStatus: 'attending',
    guestCount: 2,
  });

  await store.addRoomMember({
    roomId: earPiercingRoom._id,
    displayName: 'Rajesh Uncle & Family',
    role: 'member',
    status: 'approved',
    rsvpStatus: 'attending',
    guestCount: 3,
  });

  // Pending join request awaiting host approval
  await store.addRoomMember({
    roomId: earPiercingRoom._id,
    displayName: 'Sneha Aunty',
    role: 'member',
    status: 'pending',
    rsvpStatus: 'maybe',
  });

  // Wishlist items for Priya's ceremony
  const goldEarrings = await store.createWishlistItem({
    roomId: earPiercingRoom._id,
    title: 'Traditional Gold Earrings (Jimikki)',
    description: 'First 22K gold studs crafted with auspicious blessings',
    icon: 'gem',
    targetAmount: 25000,
    raisedAmount: 18000,
    contributorCount: 6,
    priority: 1,
  });

  const educationSukanya = await store.createWishlistItem({
    roomId: earPiercingRoom._id,
    title: 'Sukanya Samriddhi Education Fund',
    description: 'Long-term government savings account for Priya’s college future',
    icon: 'charity',
    targetAmount: 50000,
    raisedAmount: 22000,
    contributorCount: 4,
    priority: 2,
  });

  // Blessings wall posts
  await store.createRoomPost({
    roomId: earPiercingRoom._id,
    authorName: 'Anita Sharma (Host)',
    authorRole: 'host',
    type: 'announcement',
    content: 'Muhurtham is strictly at 10:45 AM. Traditional South Indian lunch will be served at 12:30 PM. Please RSVP so we can arrange temple prasad for everyone! 🙏',
    isPinned: true,
  });

  await store.createRoomPost({
    roomId: earPiercingRoom._id,
    authorName: 'Janaki Grandma',
    authorRole: 'co_host',
    type: 'blessing',
    content: 'Ayushman Bhava Priya kutti! May Devi bless you with long life, sweet voice, and all happiness. We cannot wait to see our little princess in her pattu pavadai. 🌸❤️',
  });

  await store.createRoomPost({
    roomId: earPiercingRoom._id,
    authorName: 'Rajesh Uncle',
    authorRole: 'member',
    type: 'blessing',
    content: 'All our warmest wishes to little Priya on this special sanskar! See you all this Sunday.',
  });

  // Photo in shared album
  await store.createRoomPost({
    roomId: earPiercingRoom._id,
    authorName: 'Anita Sharma',
    authorRole: 'host',
    type: 'photo',
    content: 'Priya trying on her traditional silk dress this morning! ✨',
    mediaUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=600&q=80',
  });

  await store.recalculateWeddingTotals(earPiercingRoom._id);
  console.log(`👶 Created Ear Piercing Room: ${earPiercingRoom.title} (/r/${earPiercingRoom.slug}, Code: ${earPiercingRoom.roomCode}) [PRIVATE CHILD EVENT]`);

  // 4. Room 3: Housewarming (Griha Pravesh) - Sharma Family
  const sharmaUser = await store.createUser({
    phone: '9711223344',
    name: 'Vikram Sharma',
    email: 'vikram.sharma@example.com',
    city: 'Bengaluru',
    role: 'couple',
    kycStatus: 'verified',
  });

  const grihaJoinLink = `${config.appBaseUrl}/r/sharma-griha-pravesh`;
  const grihaQr = await QRCode.toDataURL(grihaJoinLink);

  const grihaRoom = await store.createRoom({
    hostId: sharmaUser._id,
    eventType: 'housewarming',
    title: 'Sharma Family Griha Pravesh',
    honoreeName: 'Vikram & Sunita',
    date: new Date('2026-12-28T09:00:00.000Z'),
    venue: 'Villa 42, Palm Meadows, Whitefield',
    city: 'Bengaluru',
    coverImageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
    story: "New Home, New Beginnings, New Memories! We are finally moving into our dream house. Come grace our home with your warmth, laughter, and blessings. Puja starts at 9 AM followed by festive lunch.",
    privacy: 'public',
    isPublic: true,
    slug: 'sharma-griha-pravesh',
    roomCode: 'SHARMA55',
    qrUrl: grihaQr,
    status: 'active',
    isWishlistEnabled: true,
    showAmounts: true,
    kycVerified: true,
  });

  await store.addRoomMember({
    roomId: grihaRoom._id,
    userId: sharmaUser._id,
    displayName: 'Vikram Sharma',
    role: 'host',
    status: 'approved',
    rsvpStatus: 'attending',
    guestCount: 4,
  });

  await store.createWishlistItem({
    roomId: grihaRoom._id,
    title: 'Living Room Sectional Sofa',
    description: 'Comfortable seating where friends & family gather',
    icon: 'house',
    targetAmount: 60000,
    raisedAmount: 32000,
    contributorCount: 8,
    priority: 1,
  });

  await store.createWishlistItem({
    roomId: grihaRoom._id,
    title: 'Solar Rooftop Inverter System',
    description: 'Eco-friendly green power backup for our new home',
    icon: 'charity',
    targetAmount: 75000,
    raisedAmount: 15000,
    contributorCount: 3,
    priority: 2,
  });

  await store.createRoomPost({
    roomId: grihaRoom._id,
    authorName: 'Vikram Sharma',
    authorRole: 'host',
    type: 'announcement',
    content: 'Visitor parking is reserved at Clubhouse Gate 2. Please mention Villa 42 at the security gate for quick entry!',
    isPinned: true,
  });

  await store.recalculateWeddingTotals(grihaRoom._id);
  console.log(`🏡 Created Housewarming Room: ${grihaRoom.title} (/r/${grihaRoom.slug}, Code: ${grihaRoom.roomCode}) [PUBLIC]`);

  // 5. Create Draft (Unverified) Wedding to showcase KYC Gating
  const unverifiedUser = await store.createUser({
    phone: '9123456780',
    name: 'Pooja & Sameer (Draft Host)',
    role: 'couple',
    kycStatus: 'not_started',
  });

  const draftWedding = await store.createWedding({
    ownerId: unverifiedUser._id,
    slug: 'pooja-sameer',
    partner1Name: 'Pooja',
    partner2Name: 'Sameer',
    date: new Date('2027-04-10T18:00:00.000Z'),
    city: 'Bengaluru',
    story: 'Draft wedding awaiting KYC verification before launch.',
    isPublic: false,
    status: 'draft',
    kycVerified: false,
  });
  console.log(`🔒 Created Draft Wedding: ${draftWedding.partner1Name} & ${draftWedding.partner2Name} (/w/${draftWedding.slug}) [KYC PENDING]`);

  console.log(`\n🎉 Seed Completed Successfully!`);
  console.log(`   1. Aisha & Kabir Wedding: ${config.appBaseUrl}/r/${weddingRoom.slug} (Code: ${weddingRoom.roomCode})`);
  console.log(`   2. Priya's Karnavedha:    ${config.appBaseUrl}/r/${earPiercingRoom.slug} (Code: ${earPiercingRoom.roomCode})`);
  console.log(`   3. Sharma Griha Pravesh:  ${config.appBaseUrl}/r/${grihaRoom.slug} (Code: ${grihaRoom.roomCode})`);
};

// Run if called directly
if (require.main === module) {
  seedDatabase()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('Seed error:', err);
      process.exit(1);
    });
}
