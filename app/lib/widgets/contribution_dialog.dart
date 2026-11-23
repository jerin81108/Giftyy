import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/theme.dart';
import '../core/models/wishlist_item.dart';
import '../providers/guest_provider.dart';
import 'ecard_dialog.dart';

class ContributionDialog extends StatefulWidget {
  final WishlistItem? item;

  const ContributionDialog({super.key, this.item});

  @override
  State<ContributionDialog> createState() => _ContributionDialogState();
}

class _ContributionDialogState extends State<ContributionDialog> {
  final List<int> _quickChips = [500, 2000, 5000];
  int _selectedAmount = 2000;
  bool _isCustom = false;
  final TextEditingController _customAmountController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isAnonymous = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _customAmountController.dispose();
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onChipSelected(int amount) {
    setState(() {
      _selectedAmount = amount;
      _isCustom = false;
      _customAmountController.clear();
    });
  }

  void _onCustomSelected() {
    setState(() {
      _isCustom = true;
    });
  }

  Future<void> _handlePayment() async {
    final amount = _isCustom
        ? (int.tryParse(_customAmountController.text) ?? 0)
        : _selectedAmount;

    if (amount < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount (minimum ₹10)')),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final guestProvider = Provider.of<GuestProvider>(context, listen: false);
    guestProvider.selectItem(widget.item);
    guestProvider.setAmount(amount, isCustom: _isCustom);
    guestProvider.setGuestDetails(
      name: _nameController.text.trim(),
      message: _messageController.text.trim(),
      isAnonymous: _isAnonymous,
    );

    final receipt = await guestProvider.processContribution();

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });

    if (receipt != null) {
      Navigator.pop(context); // close contribution sheet
      // Show celebration e-card dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => EcardDialog(receipt: receipt),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not complete payment. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemTitle = widget.item?.title ?? 'General Wedding Fund';

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppTheme.cardBorder, width: 1.5),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Item Name & Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONTRIBUTE TOWARDS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.accentYellow,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        itemTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Chips (₹500 / ₹2,000 / ₹5,000 / Custom)
            Text(
              'Select Amount',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ..._quickChips.map((amount) {
                  final isSelected = !_isCustom && _selectedAmount == amount;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _onChipSelected(amount),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.accentYellow : AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.accentYellow : AppTheme.cardBorder,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            AppTheme.formatINR(amount),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? AppTheme.textDark : AppTheme.textLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                // Custom Amount Chip
                Expanded(
                  child: GestureDetector(
                    onTap: _onCustomSelected,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isCustom ? AppTheme.accentYellow : AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isCustom ? AppTheme.accentYellow : AppTheme.cardBorder,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Custom',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _isCustom ? AppTheme.textDark : AppTheme.textLight,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_isCustom) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customAmountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentYellow,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accentYellow,
                  ),
                  hintText: 'Enter custom amount',
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Guest Name
            Text(
              'Your Name',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
              decoration: const InputDecoration(
                hintText: 'e.g. Rahul Sharma & Family',
                prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.textMuted),
              ),
            ),

            const SizedBox(height: 16),

            // Blessing Message
            Text(
              'Blessing / Message (Optional)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 2,
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
              decoration: const InputDecoration(
                hintText: 'Wishing you a lifetime of love and happiness! 💍',
                prefixIcon: Icon(Icons.favorite_outline_rounded, color: AppTheme.textMuted),
              ),
            ),

            const SizedBox(height: 12),

            // Anonymous Checkbox
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _isAnonymous,
              activeColor: AppTheme.accentYellow,
              checkColor: AppTheme.textDark,
              title: Text(
                'Keep my name anonymous to other guests',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                ),
              ),
              onChanged: (val) => setState(() => _isAnonymous = val ?? false),
            ),

            const SizedBox(height: 20),

            // Pay via UPI Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentYellow,
                  foregroundColor: AppTheme.textDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textDark),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.qr_code_2_rounded, size: 22, color: AppTheme.textDark),
                          const SizedBox(width: 8),
                          Text(
                            'Pay with UPI (GPay / PhonePe / Paytm)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 12),
            Center(
              child: Text(
                'Every contribution = closer to the dream ✨',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
