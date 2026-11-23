import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/theme.dart';
import 'room/create_room_screen.dart';
import 'room/qr_scanner_screen.dart';
import 'room/room_screen.dart';
import 'couple/phone_login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Icon Badge
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.accentYellow,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentYellow.withAlpha(70),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  size: 42,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'GIFTYY',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle / Tagline
              Text(
                'Skip the gifts. Fund the dream ✨',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentYellow,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                'Every occasion is an Event Room. Scan QR to join, RSVP, share blessings & contribute via UPI.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              // Action 1: Create an Event Room
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateRoomScreen()),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  label: Text(
                    'Create an Event Room',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentYellow,
                    foregroundColor: AppTheme.textDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Action 2: Scan QR or Enter Code
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppTheme.accentYellow),
                  label: Text(
                    'Scan QR / Enter Room Code',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textLight,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.cardBorder, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Demo Rooms Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'EXPLORE SAMPLE OCCASION ROOMS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.accentYellow,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Demo Room 1: Wedding
              _buildDemoRoomTile(
                context,
                title: 'Aisha & Kabir Wedding',
                badge: 'WEDDING · 72% FUNDED',
                badgeColor: AppTheme.accentYellow,
                roomCode: 'AISHA2027',
                slug: 'aisha-kabir',
                icon: Icons.favorite_rounded,
              ),

              const SizedBox(height: 10),

              // Demo Room 2: Ear Piercing (Private Child Event)
              _buildDemoRoomTile(
                context,
                title: "Priya's Karnavedha Ceremony",
                badge: 'CHILD EVENT · PRIVATE',
                badgeColor: Colors.amberAccent,
                roomCode: 'PRIYA4821',
                slug: 'priya-ear-piercing-4821',
                icon: Icons.child_care_rounded,
              ),

              const SizedBox(height: 10),

              // Demo Room 3: Housewarming
              _buildDemoRoomTile(
                context,
                title: 'Sharma Family Griha Pravesh',
                badge: 'HOUSEWARMING · RSVP OPEN',
                badgeColor: Colors.lightGreenAccent,
                roomCode: 'SHARMA55',
                slug: 'sharma-griha-pravesh',
                icon: Icons.home_rounded,
              ),

              const SizedBox(height: 24),

              // Host Login
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
                  );
                },
                child: Text(
                  'Host Login with OTP / KYC Dashboard →',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoRoomTile(
    BuildContext context, {
    required String title,
    required String badge,
    required Color badgeColor,
    required String roomCode,
    required String slug,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RoomScreen(slugOrCode: slug)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: badgeColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  roomCode,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppTheme.accentYellow,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
