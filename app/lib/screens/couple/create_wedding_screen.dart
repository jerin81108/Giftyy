import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/theme.dart';
import '../../providers/wedding_provider.dart';
import 'couple_dashboard_screen.dart';

class CreateWeddingScreen extends StatefulWidget {
  const CreateWeddingScreen({super.key});

  @override
  State<CreateWeddingScreen> createState() => _CreateWeddingScreenState();
}

class _CreateWeddingScreenState extends State<CreateWeddingScreen> {
  final TextEditingController _partner1Controller = TextEditingController();
  final TextEditingController _partner2Controller = TextEditingController();
  final TextEditingController _slugController = TextEditingController();
  final TextEditingController _cityController = TextEditingController(text: 'Mumbai');
  final TextEditingController _storyController = TextEditingController(
    text: "We're so blessed to celebrate our new beginning with you. Instead of boxed gifts, help us fund our dream memories!",
  );
  DateTime _weddingDate = DateTime.now().add(const Duration(days: 60));
  bool _isSubmitting = false;

  @override
  void dispose() {
    _partner1Controller.dispose();
    _partner2Controller.dispose();
    _slugController.dispose();
    _cityController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  void _updateSlug() {
    final p1 = _partner1Controller.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final p2 = _partner2Controller.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (p1.isNotEmpty && p2.isNotEmpty) {
      _slugController.text = '$p1-$p2';
    }
  }

  Future<void> _handleCreate() async {
    final p1 = _partner1Controller.text.trim();
    final p2 = _partner2Controller.text.trim();
    final slug = _slugController.text.trim().toLowerCase();
    final city = _cityController.text.trim();

    if (p1.isEmpty || p2.isEmpty || slug.isEmpty || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required wedding details')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = Provider.of<WeddingProvider>(context, listen: false);
    final success = await provider.createWedding(
      partner1Name: p1,
      partner2Name: p2,
      slug: slug,
      date: _weddingDate,
      city: city,
      story: _storyController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      // Add default template wishlist items matching the reel!
      await provider.addWishlistItem(
        title: 'Honeymoon in Europe',
        description: 'Rome, Paris & Switzerland romantic getaway',
        icon: 'plane',
        targetAmount: 300000,
        priority: 1,
      );
      await provider.addWishlistItem(
        title: 'First Home Down Payment',
        description: 'Building our cozy sanctuary together',
        icon: 'house',
        targetAmount: 1000000,
        priority: 2,
      );
      await provider.addWishlistItem(
        title: 'Trip to Japan',
        description: 'Tokyo, Kyoto & Mount Fuji spring cherry blossoms',
        icon: 'mountain',
        targetAmount: 250000,
        priority: 3,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CoupleDashboardScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Could not create wedding')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMMM d, yyyy').format(_weddingDate);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          'CREATE WEDDING',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: AppTheme.accentYellow,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us about your Big Day',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'We will generate your unique UPI contribution page & printable QR invitation.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 28),

              // Partner 1 Name
              Text(
                'Partner 1 Name',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _partner1Controller,
                onChanged: (_) => _updateSlug(),
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
                decoration: const InputDecoration(hintText: 'e.g. Aisha'),
              ),
              const SizedBox(height: 18),

              // Partner 2 Name
              Text(
                'Partner 2 Name',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _partner2Controller,
                onChanged: (_) => _updateSlug(),
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
                decoration: const InputDecoration(hintText: 'e.g. Kabir'),
              ),
              const SizedBox(height: 18),

              // Custom URL Slug
              Text(
                'Custom Wishlist URL Slug',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _slugController,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.accentYellow, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  prefixText: 'dreamwishlist.in/w/',
                  prefixStyle: TextStyle(color: AppTheme.textMuted),
                  hintText: 'aisha-kabir',
                ),
              ),
              const SizedBox(height: 18),

              // Date Picker
              Text(
                'Wedding Date',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _weddingDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (picked != null) {
                    setState(() => _weddingDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedDate,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const Icon(Icons.calendar_today_rounded, color: AppTheme.accentYellow, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // City
              Text(
                'City / Destination',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cityController,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
                decoration: const InputDecoration(
                  hintText: 'e.g. Udaipur / Mumbai / Goa',
                  prefixIcon: Icon(Icons.location_city_rounded, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 18),

              // Story Note
              Text(
                'Couple Story / Message to Guests',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _storyController,
                maxLines: 3,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
                decoration: const InputDecoration(
                  hintText: 'Share a heartfelt note with your guests...',
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleCreate,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: AppTheme.textDark)
                      : Text(
                          'Launch Wishlist ✨',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
