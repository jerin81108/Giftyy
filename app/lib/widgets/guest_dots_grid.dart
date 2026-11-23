import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/theme.dart';

class GuestDotsGrid extends StatelessWidget {
  final int totalDots; // Default 200 as per reel
  final int activeDots;

  const GuestDotsGrid({
    super.key,
    this.totalDots = 200,
    required this.activeDots,
  });

  @override
  Widget build(BuildContext context) {
    final filledCount = activeDots.clamp(0, totalDots);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentYellow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '200 GUESTS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GOAL MULTIPLIER',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              Text(
                '$filledCount / $totalDots',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.accentYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The math: 200 guests × small contribution = dream funded! ✨',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textLight.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          // 200 Dots Grid (20 columns x 10 rows)
          LayoutBuilder(
            builder: (context, constraints) {
              final dotSize = (constraints.maxWidth - (19 * 4)) / 20;

              return Wrap(
                spacing: 4,
                runSpacing: 4,
                children: List.generate(totalDots, (index) {
                  final isFilled = index < filledCount;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: dotSize.clamp(6.0, 14.0),
                    height: dotSize.clamp(6.0, 14.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? AppTheme.accentYellow : const Color(0xFF222222),
                      border: Border.all(
                        color: isFilled ? AppTheme.accentYellow : const Color(0xFF333333),
                        width: 1,
                      ),
                      boxShadow: isFilled
                          ? [
                              BoxShadow(
                                color: AppTheme.accentYellow.withOpacity(0.4),
                                blurRadius: 4,
                                spreadRadius: 0.5,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
