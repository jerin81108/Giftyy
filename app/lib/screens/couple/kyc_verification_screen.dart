import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/theme.dart';
import '../../providers/kyc_provider.dart';
import '../../providers/wedding_provider.dart';

class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _aadhaarOtpController = TextEditingController();

  bool _consentAgreed = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KycProvider>(context, listen: false).fetchKycStatus();
    });
  }

  @override
  void dispose() {
    _panController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _aadhaarController.dispose();
    _aadhaarOtpController.dispose();
    super.dispose();
  }

  Future<void> _handlePanVerification() async {
    final pan = _panController.text.trim().toUpperCase();
    final name = _nameController.text.trim();

    if (pan.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-character PAN number (e.g. ABCDE1234F)')),
      );
      return;
    }

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name as on your PAN card')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final kyc = Provider.of<KycProvider>(context, listen: false);

    // Accept consent if not already recorded
    if (!kyc.hasConsent) {
      await kyc.acceptConsent('v1.0');
    }

    final success = await kyc.verifyPan(
      panNumber: pan,
      fullName: name,
      dob: _dobController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      // Refresh wedding status
      Provider.of<WeddingProvider>(context, listen: false).fetchMyWedding();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.accentYellow,
          content: Text(
            'Identity verified successfully! Your wedding page is now public ✨',
            style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kyc.errorMessage ?? 'Verification failed')),
      );
    }
  }

  Future<void> _handleAadhaarVerification() async {
    final aadhaar = _aadhaarController.text.replaceAll(RegExp(r'\D'), '');
    final otp = _aadhaarOtpController.text.trim();

    if (aadhaar.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aadhaar number must be 12 digits')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final kyc = Provider.of<KycProvider>(context, listen: false);

    final success = await kyc.verifyAadhaar(
      aadhaarNumber: aadhaar,
      otp: otp.isNotEmpty ? otp : '123456',
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aadhaar eKYC completed via DigiLocker!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kyc.errorMessage ?? 'Aadhaar verification failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kyc = Provider.of<KycProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          'IDENTITY VERIFICATION (KYC)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: AppTheme.accentYellow,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            _buildStatusCard(kyc),

            const SizedBox(height: 24),

            if (kyc.isVerified) ...[
              // Verified Confirmation View
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accentYellow),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppTheme.accentYellow, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'KYC Verified Host',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Verified Name: ${kyc.verifiedName ?? "Host"}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textLight),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Masked PAN: ${kyc.maskedPan ?? "ABCDE****F"}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textMuted),
                    ),
                    if (kyc.aadhaarLast4 != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Aadhaar: XXXX-XXXX-${kyc.aadhaarLast4}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textMuted),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      '✅ Your wedding page is live, public, and authorized to accept UPI contributions and withdraw payouts.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.accentYellow,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // DPDP Consent Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: AppTheme.accentYellow, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'DPDP Act 2023 & UIDAI Compliance',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'To protect guests from fraud and comply with Indian RBI payment regulations, hosts must verify their identity. Giftyy never stores full Aadhaar numbers and encrypts all sensitive data with AES-256.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: _consentAgreed || kyc.hasConsent,
                          activeColor: AppTheme.accentYellow,
                          checkColor: AppTheme.textDark,
                          onChanged: (val) => setState(() => _consentAgreed = val ?? false),
                        ),
                        Expanded(
                          child: Text(
                            'I consent to identity verification via licensed KYC provider.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textLight),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // PAN Verification Form
              Text(
                'PAN Card Verification (Mandatory)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Required by RBI to link your bank account and receive wedding gifts.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAN Number (10 characters)',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _panController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 10,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.accentYellow,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'ABCDE1234F',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'Full Name (As printed on PAN Card)',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
                      decoration: const InputDecoration(hintText: 'e.g. Aisha Sharma'),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'Date of Birth',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _dobController,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
                      decoration: const InputDecoration(hintText: 'DD/MM/YYYY'),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting || (!_consentAgreed && !kyc.hasConsent)
                            ? null
                            : _handlePanVerification,
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: AppTheme.textDark)
                            : Text(
                                'Verify PAN & Publish Page ✨',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Aadhaar DigiLocker Option
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  collapsedBackgroundColor: AppTheme.cardDark,
                  backgroundColor: AppTheme.cardDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  leading: const Icon(Icons.fingerprint_rounded, color: AppTheme.accentYellow),
                  title: Text(
                    'DigiLocker / Aadhaar eKYC (Optional)',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textLight),
                  ),
                  subtitle: Text(
                    'Instant verification without physical documents',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _aadhaarController,
                            keyboardType: TextInputType.number,
                            maxLength: 12,
                            style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
                            decoration: const InputDecoration(
                              hintText: 'Enter 12-digit Aadhaar number',
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _aadhaarOtpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            style: GoogleFonts.plusJakartaSans(color: AppTheme.accentYellow),
                            decoration: const InputDecoration(
                              hintText: 'Enter OTP (or 123456 in dev)',
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _isSubmitting ? null : _handleAadhaarVerification,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.accentYellow),
                              ),
                              child: Text(
                                'Verify via DigiLocker',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.accentYellow,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(KycProvider kyc) {
    Color badgeColor;
    String statusTitle;
    String statusDesc;
    IconData icon;

    switch (kyc.status) {
      case 'verified':
        badgeColor = AppTheme.successGreen;
        statusTitle = 'IDENTITY VERIFIED';
        statusDesc = 'Your wedding page is published and active.';
        icon = Icons.check_circle_rounded;
        break;
      case 'pending':
        badgeColor = const Color(0xFFFF9500);
        statusTitle = 'VERIFICATION UNDER REVIEW';
        statusDesc = 'Our compliance team is processing your documents.';
        icon = Icons.hourglass_top_rounded;
        break;
      case 'rejected':
      case 'needs_resubmission':
        badgeColor = Colors.redAccent;
        statusTitle = 'VERIFICATION REJECTED';
        statusDesc = kyc.rejectionReason ?? 'Name mismatch or invalid ID. Please resubmit.';
        icon = Icons.error_outline_rounded;
        break;
      default:
        badgeColor = AppTheme.accentYellow;
        statusTitle = 'ACTION REQUIRED: VERIFY IDENTITY';
        statusDesc = 'Your wedding is currently in draft. Complete KYC to publish your page.';
        icon = Icons.warning_amber_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: badgeColor, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: badgeColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusDesc,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
