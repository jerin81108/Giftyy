import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/theme.dart';
import '../../providers/wedding_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/wishlist_card.dart';
import '../guest/guest_wedding_screen.dart';
import 'add_edit_wishlist_dialog.dart';
import 'payout_screen.dart';
import 'kyc_verification_screen.dart';

class CoupleDashboardScreen extends StatefulWidget {
  const CoupleDashboardScreen({super.key});

  @override
  State<CoupleDashboardScreen> createState() => _CoupleDashboardScreenState();
}

class _CoupleDashboardScreenState extends State<CoupleDashboardScreen> {
  int _guestCountEstimate = 200; // Default reel calculator

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WeddingProvider>(context, listen: false).fetchMyWedding();
    });
  }

  void _openAddGoalDialog([dynamic item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditWishlistDialog(itemToEdit: item),
    );
  }

  void _showQrDialog(String slug, String coupleNames) {
    final url = 'http://localhost:3000/w/$slug';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.accentYellow, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'WEDDING QR CODE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: AppTheme.accentYellow,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                coupleNames,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 220.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Guests scan to contribute with UPI ✨',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Printable invitation card PDF downloading...')),
                    );
                  },
                  child: const Text('Export Print-Ready PDF Card'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          'COUPLE DASHBOARD',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            color: AppTheme.accentYellow,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user_rounded, color: AppTheme.accentYellow),
            tooltip: 'Identity Verification (KYC)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KycVerificationScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.accentYellow),
            tooltip: 'Payouts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PayoutScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textMuted),
            tooltip: 'Logout',
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Consumer<WeddingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.wedding == null) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentYellow),
              ),
            );
          }

          final wedding = provider.wedding;
          if (wedding == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No wedding wishlist found', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => provider.fetchMyWedding(),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          final items = provider.wishlistItems;
          final totalTarget = wedding.totalTarget;
          final totalRaised = wedding.totalRaised;
          final perGuestSuggested = _guestCountEstimate > 0 ? (totalTarget / _guestCountEstimate).round() : 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KYC Status Notice
                if (!wedding.kycVerified)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2200),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accentYellow, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppTheme.accentYellow, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'PAGE IN DRAFT · IDENTITY VERIFICATION REQUIRED',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: AppTheme.accentYellow,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your wedding link is currently hidden from guests. Verify your PAN/ID to publish your page and accept gifts.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.textLight.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 38,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const KycVerificationScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentYellow,
                              foregroundColor: AppTheme.textDark,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: const Text('Complete Verification (KYC)'),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Top Couple Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            wedding.coupleTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textLight,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GuestWeddingScreen(slug: wedding.slug),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.accentYellow.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.accentYellow),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.visibility_rounded, size: 14, color: AppTheme.accentYellow),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Guest Preview',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.accentYellow,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'URL: dreamwishlist.in/w/${wedding.slug}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 20),

                      // Raised vs Target
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL RAISED',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppTheme.formatINR(totalRaised),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.accentYellow,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'OVERALL GOAL',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppTheme.formatINR(totalTarget),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Quick Share Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showQrDialog(wedding.slug, wedding.coupleTitle),
                              icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                              label: const Text('Show QR Code'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textLight,
                                side: const BorderSide(color: AppTheme.cardBorder),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('WhatsApp message opened!')),
                                );
                              },
                              icon: const Icon(Icons.send_rounded, size: 16),
                              label: const Text('WhatsApp Share'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Reel's 200 Guests Calculator
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131313),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentYellow.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '200 GUESTS CALCULATOR',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: AppTheme.accentYellow,
                            ),
                          ),
                          Text(
                            '$_guestCountEstimate Guests',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Goal ÷ $_guestCountEstimate guests = ${AppTheme.formatINR(perGuestSuggested)} per guest funded! ✨',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Slider(
                        value: _guestCountEstimate.toDouble(),
                        min: 50,
                        max: 500,
                        divisions: 45,
                        activeColor: AppTheme.accentYellow,
                        inactiveColor: const Color(0xFF333333),
                        onChanged: (val) => setState(() => _guestCountEstimate = val.round()),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Wishlist Items Header + Add Goal Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'WISHLIST GOALS (${items.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: AppTheme.accentYellow,
                      ),
                    ),
                    InkWell(
                      onTap: () => _openAddGoalDialog(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentYellow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add_rounded, size: 16, color: AppTheme.textDark),
                            const SizedBox(width: 4),
                            Text(
                              'Add Goal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Wishlist Cards
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isPrimary = index == 0;

                  return Stack(
                    children: [
                      WishlistCard(
                        item: item,
                        isPrimary: isPrimary,
                        onContribute: () => _openAddGoalDialog(item),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit_rounded,
                                size: 18,
                                color: isPrimary ? AppTheme.textDark : AppTheme.textMuted,
                              ),
                              onPressed: () => _openAddGoalDialog(item),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: isPrimary ? AppTheme.textDark : Colors.redAccent,
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    backgroundColor: AppTheme.cardDark,
                                    title: const Text('Delete Goal?'),
                                    content: Text('Are you sure you want to remove "${item.title}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await provider.deleteWishlistItem(item.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 24),

                // Contributor Blessings & History
                if (provider.contributions.isNotEmpty) ...[
                  Text(
                    'CONTRIBUTOR BLESSINGS (${provider.contributions.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: AppTheme.accentYellow,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...provider.contributions.map((c) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                c.guestName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textLight,
                                ),
                              ),
                              Text(
                                AppTheme.formatINR(c.amount ?? 0),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.accentYellow,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'For: ${c.itemTitle ?? "General Fund"}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          if (c.message != null && c.message!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              '“${c.message!}”',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: AppTheme.textLight.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
