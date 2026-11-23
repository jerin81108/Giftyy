import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/theme.dart';

class CustomProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int percent;
  final int goalAmount;
  final bool isPrimaryCard; // if inside primary yellow card, colors invert

  const CustomProgressBar({
    super.key,
    required this.progress,
    required this.percent,
    required this.goalAmount,
    this.isPrimaryCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = isPrimaryCard ? AppTheme.textDark : AppTheme.accentYellow;
    final trackColor = isPrimaryCard ? Colors.black.withOpacity(0.15) : const Color(0xFF262626);
    final labelColor = isPrimaryCard ? AppTheme.textDark.withOpacity(0.8) : AppTheme.textMuted;
    final valueColor = isPrimaryCard ? AppTheme.textDark : AppTheme.textLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Track and Animated Fill
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.02, 1.0),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      color: isPrimaryCard ? AppTheme.accentYellow : AppTheme.background,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Labels matching the reel
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$percent% FUNDED',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: valueColor,
              ),
            ),
            Text(
              'GOAL ${AppTheme.formatINR(goalAmount)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: labelColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
