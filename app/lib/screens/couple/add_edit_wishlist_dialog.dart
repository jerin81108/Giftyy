import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/theme.dart';
import '../../core/models/wishlist_item.dart';
import '../../providers/wedding_provider.dart';

class AddEditWishlistDialog extends StatefulWidget {
  final WishlistItem? itemToEdit;

  const AddEditWishlistDialog({super.key, this.itemToEdit});

  @override
  State<AddEditWishlistDialog> createState() => _AddEditWishlistDialogState();
}

class _AddEditWishlistDialogState extends State<AddEditWishlistDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();
  String _selectedIcon = 'gift';
  int _priority = 1;
  bool _isSaving = false;

  // Reel-inspired quick templates
  final List<Map<String, dynamic>> _templates = [
    {
      'title': 'Honeymoon in Europe',
      'desc': 'Rome, Paris & Swiss Alps romantic getaway',
      'icon': 'plane',
      'amount': 300000,
    },
    {
      'title': 'First Home Down Payment',
      'desc': 'Building our forever cozy home',
      'icon': 'house',
      'amount': 1000000,
    },
    {
      'title': 'Trip to Japan',
      'desc': 'Tokyo street food, Kyoto temples & Mt. Fuji',
      'icon': 'mountain',
      'amount': 250000,
    },
    {
      'title': 'Furniture & Living Room',
      'desc': 'Sofa, coffee table & warm lights for new home',
      'icon': 'furniture',
      'amount': 150000,
    },
    {
      'title': 'Charity Donation',
      'desc': 'Supporting education for underprivileged children',
      'icon': 'charity',
      'amount': 50000,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      final item = widget.itemToEdit!;
      _titleController.text = item.title;
      _descController.text = item.description;
      _targetAmountController.text = item.targetAmount.toString();
      _selectedIcon = item.icon;
      _priority = item.priority;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  void _applyTemplate(Map<String, dynamic> template) {
    setState(() {
      _titleController.text = template['title'];
      _descController.text = template['desc'];
      _targetAmountController.text = template['amount'].toString();
      _selectedIcon = template['icon'];
    });
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    final amount = int.tryParse(_targetAmountController.text.trim()) ?? 0;

    if (title.isEmpty || amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a goal title and target of at least ₹100')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = Provider.of<WeddingProvider>(context, listen: false);

    bool success;
    if (widget.itemToEdit != null) {
      success = await provider.updateWishlistItem(widget.itemToEdit!.id, {
        'title': title,
        'description': _descController.text.trim(),
        'icon': _selectedIcon,
        'targetAmount': amount,
        'priority': _priority,
      });
    } else {
      success = await provider.addWishlistItem(
        title: title,
        description: _descController.text.trim(),
        icon: _selectedIcon,
        targetAmount: amount,
        priority: _priority,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save dream goal. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;

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
        border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'EDIT DREAM GOAL' : 'ADD NEW DREAM GOAL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: AppTheme.accentYellow,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!isEditing) ...[
              // Templates Chips
              Text(
                'Popular Templates (1-Tap Fill)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _templates.map((tpl) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        backgroundColor: AppTheme.cardDark,
                        side: const BorderSide(color: AppTheme.cardBorder),
                        label: Text(
                          tpl['title'],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textLight,
                          ),
                        ),
                        onPressed: () => _applyTemplate(tpl),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Goal Title
            Text(
              'Goal Title',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
              decoration: const InputDecoration(hintText: 'e.g. Honeymoon in Europe'),
            ),
            const SizedBox(height: 16),

            // Target Amount
            Text(
              'Target Amount (₹ INR)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.accentYellow,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                prefixStyle: TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.bold),
                hintText: '300000',
              ),
            ),
            const SizedBox(height: 16),

            // Short Description
            Text(
              'Short Description / Memories to make',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
              decoration: const InputDecoration(
                hintText: 'Rome, Paris & Switzerland romantic getaway',
              ),
            ),
            const SizedBox(height: 16),

            // Icon Picker
            Text(
              'Select Icon',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildIconChoice('plane', Icons.flight_takeoff_rounded),
                _buildIconChoice('house', Icons.home_rounded),
                _buildIconChoice('mountain', Icons.landscape_rounded),
                _buildIconChoice('furniture', Icons.chair_rounded),
                _buildIconChoice('charity', Icons.volunteer_activism_rounded),
                _buildIconChoice('gift', Icons.card_giftcard_rounded),
              ],
            ),
            const SizedBox(height: 24),

            // Save CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const CircularProgressIndicator(color: AppTheme.textDark)
                    : Text(
                        isEditing ? 'Update Goal' : 'Add to Wishlist ✨',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconChoice(String iconKey, IconData iconData) {
    final isSelected = _selectedIcon == iconKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedIcon = iconKey),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentYellow : AppTheme.cardDark,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.accentYellow : AppTheme.cardBorder,
          ),
        ),
        child: Icon(
          iconData,
          color: isSelected ? AppTheme.textDark : AppTheme.textLight,
          size: 20,
        ),
      ),
    );
  }
}
