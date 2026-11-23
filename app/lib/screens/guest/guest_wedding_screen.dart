import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/theme.dart';
import '../../core/network/api_service.dart';
import '../../providers/guest_provider.dart';
import '../../widgets/wishlist_card.dart';
import '../../widgets/guest_dots_grid.dart';
import '../../widgets/contribution_dialog.dart';

class GuestWeddingScreen extends StatefulWidget {
  final String slug;

  const GuestWeddingScreen({super.key, required this.slug});

  @override
  State<GuestWeddingScreen> createState() => _GuestWeddingScreenState();
}

class _GuestWeddingScreenState extends State<GuestWeddingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GuestProvider>(context, listen: false).loadWedding(widget.slug);
    });
  }

  void _openContributionSheet([dynamic item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContributionDialog(item: item),
    );
  }

  void _showReportDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Report this page',
          style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Giftyy protects couples and guests. If this wedding is fake, impersonating someone, or violating guidelines, let us know.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.textLight),
              decoration: const InputDecoration(hintText: 'Describe the issue...'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.reportWedding(
                slug: widget.slug,
                reason: reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : 'Suspicious activity',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted. Our security team will review it.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Submit Report'),
          ),
        ],
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
          'GIFTYY',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: AppTheme.accentYellow,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppTheme.textLight),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wedding link copied to clipboard!')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted),
            color: AppTheme.cardDark,
            onSelected: (value) {
              if (value == 'report') {
                _showReportDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 18, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Report this page', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<GuestProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentYellow),
              ),
            );
          }

          if (provider.errorMessage != null || provider.wedding == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sentiment_dissatisfied_rounded, size: 54, color: AppTheme.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage ?? 'Wedding not found',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, color: AppTheme.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.loadWedding(widget.slug),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final wedding = provider.wedding!;
          final items = provider.items;
          final formattedDate = DateFormat('MMMM d, yyyy').format(wedding.date);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Couple Hero Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.cardBorder),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1F1F1F),
                        AppTheme.cardDark,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Ring / Heart Monogram
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentYellow.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.accentYellow.withOpacity(0.4)),
                        ),
                        child: Text(
                          '${wedding.daysRemaining > 0 ? '${wedding.daysRemaining} DAYS TO GO' : 'JUST MARRIED'} ✨',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppTheme.accentYellow,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Couple Names
                      Text(
                        wedding.coupleTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Date & City
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${wedding.city} · $formattedDate',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Story Note
                      if (wedding.story.isNotEmpty)
                        Text(
                          '“${wedding.story}”',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textLight.withOpacity(0.85),
                            height: 1.4,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 200 Guests Multiplier Grid
                GuestDotsGrid(
                  totalDots: 200,
                  activeDots: wedding.contributorCount,
                ),

                const SizedBox(height: 28),

                // Wishlist Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DREAM GOALS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: AppTheme.accentYellow,
                      ),
                    ),
                    Text(
                      '${items.length} Goals',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Wishlist Cards (First Card is Primary Yellow, others are Dark Grey!)
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isPrimary = index == 0; // First item highlighted in yellow!

                  return WishlistCard(
                    item: item,
                    isPrimary: isPrimary,
                    onContribute: () => _openContributionSheet(item),
                  );
                }),

                const SizedBox(height: 20),

                // Recent Blessings / Messages
                if (provider.recentContributions.isNotEmpty) ...[
                  Text(
                    'RECENT BLESSINGS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: AppTheme.accentYellow,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...provider.recentContributions.take(4).map((c) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF222222),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite_rounded, size: 18, color: AppTheme.accentYellow),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      c.guestName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                    if (c.amount != null)
                                      Text(
                                        AppTheme.formatINR(c.amount!),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.accentYellow,
                                        ),
                                      ),
                                  ],
                                ),
                                if (c.message != null && c.message!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    c.message!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 80), // padding for floating action button
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          border: Border(top: BorderSide(color: AppTheme.cardBorder)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => _openContributionSheet(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentYellow,
              foregroundColor: AppTheme.textDark,
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.volunteer_activism_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Contribute Any Amount ✨',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
