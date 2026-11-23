import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/theme.dart';
import '../core/models/wishlist_item.dart';
import 'progress_bar.dart';

class WishlistCard extends StatelessWidget {
  final WishlistItem item;
  final bool isPrimary; // First card is highlighted in bold yellow with black text!
  final VoidCallback onContribute;

  const WishlistCard({
    super.key,
    required this.item,
    required this.isPrimary,
    required this.onContribute,
  });

  IconData _getIconData(String icon) {
    switch (icon.toLowerCase()) {
      case 'plane':
      case 'flight':
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'house':
      case 'home':
        return Icons.home_rounded;
      case 'mountain':
      case 'adventure':
        return Icons.landscape_rounded;
      case 'japan':
      case 'torii':
        return Icons.temple_buddhist_rounded;
      case 'gem':
      case 'jewelry':
        return Icons.diamond_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'furniture':
        return Icons.chair_rounded;
      case 'charity':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.card_giftcard_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isPrimary ? AppTheme.accentYellow : AppTheme.cardDark;
    final titleColor = isPrimary ? AppTheme.textDark : AppTheme.textLight;
    final amountColor = isPrimary ? AppTheme.textDark : AppTheme.accentYellow;
    final iconBg = isPrimary ? Colors.black.withOpacity(0.12) : const Color(0xFF222222);
    final iconColor = isPrimary ? AppTheme.textDark : AppTheme.accentYellow;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary ? AppTheme.accentYellow : AppTheme.cardBorder,
          width: isPrimary ? 2 : 1,
        ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: AppTheme.accentYellow.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onContribute,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Circular icon, Title, Target Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Circular Icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconData(item.icon),
                        color: iconColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title and Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: isPrimary
                                    ? AppTheme.textDark.withOpacity(0.7)
                                    : AppTheme.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Target Amount in INR
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppTheme.formatINR(item.targetAmount),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: amountColor,
                          ),
                        ),
                        if (item.isFullyFunded)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPrimary ? AppTheme.textDark : AppTheme.successGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'FUNDED',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isPrimary ? AppTheme.accentYellow : Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress Bar with dot marker & label
                CustomProgressBar(
                  progress: item.progressRatio,
                  percent: item.percentFunded,
                  goalAmount: item.targetAmount,
                  isPrimaryCard: isPrimary,
                ),
                const SizedBox(height: 16),
                // Contribute CTA Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.contributorCount} friends contributed',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPrimary
                            ? AppTheme.textDark.withOpacity(0.8)
                            : AppTheme.textMuted,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isPrimary ? AppTheme.textDark : AppTheme.accentYellow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Contribute',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isPrimary ? AppTheme.accentYellow : AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: isPrimary ? AppTheme.accentYellow : AppTheme.textDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
