# Giftyy ✨
### *"Skip the gifts. Fund the dream"* – Event Rooms & UPI Gifting Platform for India

**Giftyy** is a modern, privacy-first Event Rooms platform for Indian celebrations. Instead of receiving random physical boxed gifts (mixers, dinner sets, repetitive gift cards) that hosts don't need, hosts create an **Event Room** for any occasion. Guests join by link, by typing a short Room Code (e.g. `PRIYA4821`), or by scanning a QR code with their phone camera or the in-app scanner.

Inside the room, guests view event details, RSVP with guest counts, sign the digital blessings guestbook, share memories in a shared photo album, receive host announcements, and contribute directly towards the host's dream goals via UPI!

---

## 🎊 Event Rooms & 11 Indian Occasion Templates

Every event in Giftyy is a **Room**. Each template pre-fills suggested wishlist dream goals, greeting text, cover theme, and privacy settings:

| # | Occasion Template | Key Use Case | Suggested Dream Goals | Default Privacy |
|---|-------------------|--------------|-----------------------|-----------------|
| 1 | **Wedding** | Aisha & Kabir wedding celebration | Honeymoon in Europe, First Home Down Payment, Trip to Japan | Public |
| 2 | **Engagement / Roka** | Pre-wedding commitment celebration | Wedding Photography Fund, Couple Weekend Getaway | Public |
| 3 | **Birthday Party** | Milestone birthdays (18th, 25th, 30th) | Dream Tech Gadget, Solo Travel Adventure, Book Library | Public |
| 4 | **Baby Shower (Seemantham)** | Welcoming newborn with blessings | Nursery Setup & Crib, Pram & Car Safety Seat, Stem Cell Banking | **Private (Child Safe)** |
| 5 | **Ear Piercing (Karnavedha)** | Sacred childhood milestone ceremony | Traditional 22K Gold Earrings (Jimikki), Sukanya Samriddhi Education Fund, Silver Payal | **Private (Child Safe)** |
| 6 | **Coming-of-Age (Upanayana / Ritu Kala)** | Spiritual / adulthood transition | Higher Education Coding Laptop, Vedic Learning Fund | **Private (Child Safe)** |
| 7 | **Housewarming (Griha Pravesh)** | New sanctuary and home blessings | Sectional Living Room Sofa, Solar Rooftop Inverter, Kitchen Chimney | Public |
| 8 | **Graduation / Convocation** | College & degree milestones | Career Relocation Security Deposit, MBA Prep & Certifications | Public |
| 9 | **Anniversary** | Silver jubilee & couple celebrations | Silver Jubilee Cruise Vacation, Home Garden Renovation | Public |
| 10 | **Festival / Family Function** | Annual family puja, Diwali, Navratri | Community Annadanam Food Drive, Temple Seva & Deepam | Public |
| 11 | **Custom Occasion** | Host names their own special occasion | Custom dream goals defined by host | Host Choice |

---

## 🔑 Room Creation & Joining Flow

### 1. Room Creation (Host)
- Host selects occasion template, names honoree, specifies date, venue, city, story, and privacy.
- Giftyy automatically generates:
  1. **Unguessable URL**: `app.giftyy.com/r/priya-ear-piercing-4821` (random 4-digit token, not sequential).
  2. **Short Room Code**: `PRIYA4821` (alphanumeric uppercase, 6–9 characters, easily readable on printed invites).
  3. **High-Resolution QR Code**: Embedded data URL and downloadable PNG.
  4. **Print-Ready Invitation Card (PDF)**: A5 print-ready card formatted in Reel Dark & Bold Yellow with QR box, room code, and RSVP instructions.

### 2. Joining a Room (Guest)
- **Scan In-App QR Scanner**: Integrated camera scanner powered by `mobile_scanner`.
- **Scan via Phone Camera / Google Lens**: Opens responsive web page `/r/:slug`.
- **Type Room Code**: Type `PRIYA4821` in app without full signup (name required, phone/email optional).
- **Public Rooms**: Instant join with immediate access to overview, guestbook, album, and wishlist.
- **Private Rooms**: Guest sends a join request. The host reviews and approves access from the Host Members panel.

---

## 🛡️ Child Safety & DPDP Act 2023 Compliance

For child-centric events (Ear piercing, Birthdays of minors, Baby showers, Coming-of-age):
- **Guardian Only**: Only the parent or legal guardian can be the room host. No minor data is collected.
- **Private by Default**: Child ceremony rooms default to `private` mode.
- **Photo & Story Protection**: For unapproved visitors, honoree child photos and sensitive venue details are hidden. Only approved members can view the album or post blessings.
- **Aadhaar Masking**: Stored strictly as `XXXX-XXXX-9012` per UIDAI regulations. Raw 12-digit Aadhaar numbers are never persisted.
- **Right to Erasure**: Hosts can delete their room and erase all posts, photos, member records, and KYC data with a single tap (`DELETE /api/rooms/:id`).

---

## 🎨 Reel Design System (Dark & Bold Yellow)
- **Background**: Near-black (`#0B0B0B`) and dark cards (`#161616`).
- **Bold Yellow Accent (`#FFC933`)**: Highlights the first wishlist card in bold yellow with black text; secondary cards use dark grey with yellow amounts.
- **Progress Bars**: Rounded progress bars with animated percentages (`72% FUNDED`).
- **200 Dots Multiplier Grid**: Interactive visual grid of 200 dots showing small contributions collectively funding big dreams.
- **Celebration Flow**: Confetti animations and downloadable digital contribution receipts.

---

## 🏗️ Project Architecture

```
Giftyy/
├── server/                         # Node.js + TypeScript + Express Backend
│   ├── src/
│   │   ├── config/                 # Giftyy configuration, JWT, Razorpay, encryption keys
│   │   ├── constants/
│   │   │   └── eventTemplates.ts   # 11 Indian Occasion Templates with pre-filled goals
│   │   ├── models/                 # Room, RoomMember, RoomPost, KycRecord, Wishlist, Contribution
│   │   ├── services/
│   │   │   ├── store.service.ts    # Dual MongoDB & In-Memory zero-dependency database
│   │   │   ├── kyc.service.ts      # PAN, DigiLocker Aadhaar, Penny-Drop name matching
│   │   │   ├── encryption.service.ts # AES-256 field encryption & UIDAI masking
│   │   │   ├── pdf.service.ts      # Print-ready PDF invitation card generator
│   │   │   └── socket.service.ts   # Real-time WebSocket live updates
│   │   ├── controllers/            # Room, Auth, KYC, Wishlist, Payment, Payout
│   │   ├── routes/                 # REST API endpoints (/api/rooms, /api/auth, /api/kyc, etc.)
│   │   ├── scripts/seed.ts         # Seeds Wedding, Priya's Ear Piercing, and Griha Pravesh rooms
│   │   └── tests/                  # 24 Automated Tests (100% Passing)
│   │       ├── room.test.ts        # 9 tests: Templates, Slugs, Codes, Privacy, RSVP, Posts, QR regen
│   │       ├── kyc.test.ts         # 6 tests: DPDP masking, Penny-drop matching, Draft gating
│   │       ├── payment.test.ts     # 5 tests: Orders, Signatures, Idempotency
│   │       └── money.test.ts       # 4 tests: 72% funding math, Fee split, 200 dots
│   └── package.json
│
└── app/                            # Flutter Multiplatform App (Android, iOS & Web)
    ├── lib/
    │   ├── core/
    │   │   ├── constants/          # Theme (Reel Dark & Yellow), EventTemplates (11 types)
    │   │   ├── models/             # Room, RoomMember, RoomPost, WishlistItem, Contribution
    │   │   └── network/            # ApiService, SocketService
    │   ├── providers/              # RoomProvider, KycProvider, AuthProvider, GuestProvider
    │   ├── screens/
    │   │   ├── splash_screen.dart  # Hub: Create Room, Scan QR, Explore Sample Rooms
    │   │   ├── room/
    │   │   │   ├── qr_scanner_screen.dart # MobileScanner view + manual code entry
    │   │   │   ├── create_room_screen.dart # Occasion selector, pre-filled goals, privacy
    │   │   │   └── room_screen.dart       # Header, RSVP, Overview, Wishlist, Guestbook, Album, Members
    │   │   └── couple/             # Phone OTP Login, KYC Verification Screen, Dashboard
    │   └── main.dart               # MultiProvider & Route generation (/r/:slugOrCode, /w/:slug)
    └── pubspec.yaml
```

---

## 🧪 Verification & Automated Tests

All **24 tests across 4 test suites** pass cleanly:

```bash
cd server
pnpm test
```

```
Test Files  4 passed (4)
     Tests  24 passed (24)
  ✓ src/tests/room.test.ts (9 tests)
  ✓ src/tests/kyc.test.ts (6 tests)
  ✓ src/tests/payment.test.ts (5 tests)
  ✓ src/tests/money.test.ts (4 tests)
```

Flutter static analysis passes with **0 compilation errors** and **0 warnings**:

```bash
cd app
flutter analyze
```

---

## 🔥 Firebase Integration (Project: `giftyy-2ce00`)

Giftyy is integrated with the official **Firebase Admin SDK** (`firebase-admin` v14) using your project credentials:
- **Project ID**: `giftyy-2ce00`
- **Client Email**: `firebase-adminsdk-fbsvc@giftyy-2ce00.iam.gserviceaccount.com`
- **Service Account Credentials**: Stored securely at `server/src/config/firebase-service-account.json` (and `server/serviceAccountKey.json`, git-ignored).

### Key Firebase Features

1. **Firebase Phone Auth & Token Verification**:
   - `POST /api/auth/firebase-login`: Verifies client-side Firebase ID tokens (`idToken`), provisions/authenticates users, and generates Giftyy JWT sessions.
2. **Device FCM Token Registration**:
   - `POST /api/auth/fcm-token`: Authenticated hosts & guests can register their device push tokens.
3. **Automated FCM Push & Topic Notifications**:
   - **Host Announcements**: Broadcast instantly to topic `room_<slug>` so all guests subscribed to the room receive real-time push alerts.
   - **RSVPs**: Push notifications sent directly to the host when a guest responds with attendance.
   - **Blessings & Guestbook**: Host notified in real-time when guests post blessings.
   - **Gift Contributions**: High-priority push alerts sent to the host and topic subscribers when a UPI contribution is fulfilled.

---

## 🚀 Quickstart Guide

### 1. Start the Backend
```bash
cd server
pnpm install
pnpm seed    # Seeds Aisha Wedding, Priya Ear Piercing, Sharma Housewarming
pnpm dev     # Runs Express on http://localhost:5000
```

### 2. Run the Flutter App
```bash
cd app
flutter pub get
flutter run -d chrome    # Or android / ios simulator
```

### 3. Demo Rooms Ready Out-of-the-Box
1. **Wedding**: `http://localhost:3000/r/aisha-kabir` (Room Code: `AISHA2027`)
2. **Ear Piercing (Private Child Event)**: `http://localhost:3000/r/priya-ear-piercing-4821` (Room Code: `PRIYA4821`)
3. **Housewarming**: `http://localhost:3000/r/sharma-griha-pravesh` (Room Code: `SHARMA55`)
