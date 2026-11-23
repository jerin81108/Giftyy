# Giftyy – Database Architecture, Security Rules & KYC Compliance

## 1. MongoDB Production Indexes

```javascript
// Weddings Collection
db.weddings.createIndex({ "slug": 1 }, { unique: true }); // Fast O(1) slug lookups e.g. /w/aisha-kabir
db.weddings.createIndex({ "ownerId": 1 });                // Couple host lookups
db.weddings.createIndex({ "kycVerified": 1, "isPublic": 1 }); // Gated public listing filter
db.weddings.createIndex({ "status": 1 });                 // draft | published | flagged | suspended

// Users Collection
db.users.createIndex({ "phone": 1 }, { unique: true });   // 10-digit Indian phone login
db.users.createIndex({ "panLast4": 1 }, { sparse: true });// Anti-fraud: Duplicate PAN prevention
db.users.createIndex({ "kycStatus": 1 });                 // not_started | pending | verified | rejected
db.users.createIndex({ "role": 1 });

// KYC Records Collection (Restricted access, audit logged)
db.kycrecords.createIndex({ "userId": 1, "createdAt": -1 });
db.kycrecords.createIndex({ "referenceId": 1 }, { unique: true });

// Audit Logs Collection
db.auditlogs.createIndex({ "timestamp": -1 });
db.auditlogs.createIndex({ "actorId": 1, "action": 1 });
db.auditlogs.createIndex({ "targetId": 1 }, { sparse: true });

// Contributions Collection
db.contributions.createIndex({ "orderId": 1 }, { unique: true }); // Idempotency check for Razorpay
db.contributions.createIndex({ "weddingId": 1, "status": 1, "createdAt": -1 }); // Real-time blessing feed
db.contributions.createIndex({ "paymentId": 1 }, { sparse: true }); // Payout & dispute tracking

// Wishlist Items Collection
db.wishlistitems.createIndex({ "weddingId": 1, "priority": 1 }); // Sort by priority (highlight yellow card)
db.wishlistitems.createIndex({ "weddingId": 1, "status": 1 });   // Active goals filter

// Payouts Collection
db.payouts.createIndex({ "weddingId": 1, "status": 1 });

// Reports Collection (Abuse / Fake Wedding Detection)
db.reports.createIndex({ "weddingId": 1, "status": 1 });
```

---

## 2. Identity Verification (KYC) & DPDP Act 2023 Compliance

### 1. Mandatory Host KYC Verification
- Couples must complete identity verification before their wedding page can go live or receive payouts.
- **Accepted IDs**: PAN card (mandatory for payouts), Aadhaar via DigiLocker / OTP eKYC, Passport, Driving Licence.
- **Verification States**: `not_started -> pending -> verified -> rejected -> needs_resubmission`.

### 2. UIDAI & Aadhaar Privacy Guidelines
- **NEVER Store 12-Digit Aadhaar Numbers**: Only the last 4 digits (`aadhaarLast4`) and provider's reference ID are retained.
- Masked display on screen (`XXXX-XXXX-9012`).

### 3. Bank Penny-Drop Name Matching
- Account holder name on bank details must match the verified ID name with threshold (>= 70%) to prevent third-party fund diversion.

### 4. Data Protection & Encryption (DPDP Act 2023)
- Sensitive fields are encrypted at rest with **AES-256-CBC**.
- Explicit consent screen prior to ID collection with `consentVersion` and timestamp recorded.
- **Right to Erasure ("Delete My Data")**: Complete purging and anonymization endpoint for host records upon verified request.

### 5. Anti-Fraud Protections
- **Duplicate PAN Prevention**: The same PAN cannot create multiple active wedding campaigns.
- **Review Queue & Flagging**: Guests can report suspicious or fake wedding pages. Three reports automatically flag the page into draft for admin audit.
- **Audit Logs**: Every login, KYC verification, payout request, and admin view is permanently audit-logged with IP and timestamp.
