import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/theme.dart';
import '../../core/constants/event_templates.dart';
import '../../providers/room_provider.dart';
import 'room_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  int _selectedTemplateIndex = 0;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _honoreeController;
  late TextEditingController _partner2Controller;
  late TextEditingController _venueController;
  late TextEditingController _cityController;
  late TextEditingController _storyController;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  bool _isPrivate = false;
  bool _isWishlistEnabled = true;

  @override
  void initState() {
    super.initState();
    final template = EventTemplates.all[_selectedTemplateIndex];
    _honoreeController = TextEditingController(text: 'Priya');
    _titleController = TextEditingController(text: 'Priya\'s ${template.label}');
    _partner2Controller = TextEditingController(text: '');
    _venueController = TextEditingController(text: 'Grand Palace');
    _cityController = TextEditingController(text: 'Bengaluru');
    _storyController = TextEditingController(text: template.defaultStory);
    _isPrivate = template.isPrivateByDefault;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _honoreeController.dispose();
    _partner2Controller.dispose();
    _venueController.dispose();
    _cityController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  void _onTemplateSelected(int index) {
    setState(() {
      _selectedTemplateIndex = index;
      final template = EventTemplates.all[index];
      _storyController.text = template.defaultStory;
      _isPrivate = template.isPrivateByDefault;
      if (_honoreeController.text.isNotEmpty) {
        _titleController.text = '${_honoreeController.text}\'s ${template.label}';
      } else {
        _titleController.text = '${template.label} Celebration';
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accentYellow,
              onPrimary: AppTheme.textDark,
              surface: AppTheme.cardBackground,
              onSurface: AppTheme.textLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitRoom() async {
    if (_honoreeController.text.trim().isEmpty) {
      _honoreeController.text = 'Host';
    }
    if (_titleController.text.trim().isEmpty) {
      _titleController.text = '${_honoreeController.text}\'s ${EventTemplates.all[_selectedTemplateIndex].label}';
    }
    if (_cityController.text.trim().isEmpty) {
      _cityController.text = 'Bengaluru';
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check the form fields')),
      );
      return;
    }

    final template = EventTemplates.all[_selectedTemplateIndex];
    final roomProvider = context.read<RoomProvider>();

    final roomData = {
      'eventType': template.type,
      'title': _titleController.text.trim(),
      'honoreeName': _honoreeController.text.trim(),
      if (_partner2Controller.text.trim().isNotEmpty) 'partner2Name': _partner2Controller.text.trim(),
      'date': _selectedDate.toIso8601String(),
      'venue': _venueController.text.trim(),
      'city': _cityController.text.trim(),
      'coverImageUrl': template.defaultCoverUrl,
      'story': _storyController.text.trim(),
      'privacy': _isPrivate ? 'private' : 'public',
      'isWishlistEnabled': _isWishlistEnabled,
      'initialWishlist': template.suggestedWishlist.map((item) => {
        'title': item.title,
        'description': item.description,
        'icon': item.icon,
        'amount': item.amount,
      }).toList(),
    };

    final result = await roomProvider.createRoom(roomData);

    if (result != null && mounted) {
      final room = result['room'];
      final slug = room['slug'] ?? '';
      final roomCode = room['roomCode'] ?? '';
      final joinLink = result['joinLink'] ?? '';

      _showSuccessDialog(slug, roomCode, joinLink);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(roomProvider.errorMessage ?? 'Failed to create room')),
      );
    }
  }

  void _showSuccessDialog(String slug, String roomCode, String joinLink) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.accentYellow, size: 28),
            const SizedBox(width: 10),
            Text(
              'Room Created! 🎉',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Share your room link or room code with your guests:',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accentYellow.withAlpha(80)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ROOM CODE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentYellow,
                        ),
                      ),
                      Text(
                        roomCode,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppTheme.accentYellow),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Room code copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                joinLink,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => RoomScreen(slugOrCode: slug)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentYellow,
              foregroundColor: AppTheme.textDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              'Enter Room Now',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTemplate = EventTemplates.all[_selectedTemplateIndex];
    final isLoading = context.watch<RoomProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Event Room',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textLight,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Template Selector Carousel
              Text(
                'CHOOSE OCCASION TEMPLATE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.accentYellow,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: EventTemplates.all.length,
                  itemBuilder: (context, idx) {
                    final t = EventTemplates.all[idx];
                    final isSelected = idx == _selectedTemplateIndex;

                    return GestureDetector(
                      onTap: () => _onTemplateSelected(idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 130,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.accentYellow : AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? AppTheme.accentYellow : Colors.white12,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (t.isChildEvent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.textDark : AppTheme.accentYellow,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'CHILD SAFE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected ? AppTheme.accentYellow : AppTheme.textDark,
                                  ),
                                ),
                              ),
                            Text(
                              t.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? AppTheme.textDark : AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Honoree / Host Name
              _buildSectionHeader('WHO ARE WE CELEBRATING?'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _honoreeController,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
                decoration: _inputDecoration('Honoree or Host Name (e.g. Priya or Rahul)'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a name' : null,
                onChanged: (val) {
                  if (val.trim().isNotEmpty) {
                    _titleController.text = '$val\'s ${currentTemplate.label}';
                  }
                },
              ),

              if (currentTemplate.type == 'wedding' || currentTemplate.type == 'anniversary') ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _partner2Controller,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
                  decoration: _inputDecoration('Partner Name (optional)'),
                ),
              ],

              const SizedBox(height: 20),

              // Room Title
              _buildSectionHeader('EVENT TITLE'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
                decoration: _inputDecoration('Event Title'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
              ),

              const SizedBox(height: 20),

              // Date Picker
              _buildSectionHeader('DATE OF CELEBRATION'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: AppTheme.accentYellow),
                          const SizedBox(width: 12),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Venue & City
              _buildSectionHeader('LOCATION'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _venueController,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
                decoration: _inputDecoration('Venue / Temple / Address (e.g. Palm Meadows)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
                decoration: _inputDecoration('City (e.g. Bengaluru)'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a city' : null,
              ),

              const SizedBox(height: 20),

              // Invitation Story / Note
              _buildSectionHeader('INVITATION MESSAGE'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _storyController,
                maxLines: 3,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
                decoration: _inputDecoration('Short story or invitation note for guests...'),
              ),

              const SizedBox(height: 20),

              // Privacy Switch (Crucial for Child Events)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isPrivate ? AppTheme.accentYellow.withAlpha(120) : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                      color: _isPrivate ? AppTheme.accentYellow : AppTheme.textMuted,
                      size: 26,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isPrivate ? 'Private Room (Host Approval)' : 'Public Room (Instant Join)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isPrivate
                                ? 'Guests must request to join. Photos & details are hidden until you approve them.'
                                : 'Anyone with link or QR code can view and join immediately.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPrivate,
                      activeColor: AppTheme.accentYellow,
                      onChanged: (val) => setState(() => _isPrivate = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Wishlist Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard_rounded, color: AppTheme.accentYellow, size: 26),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable Wishlist & UPI Gifts',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pre-fills suggested dream goals from the template. Guests contribute via UPI directly to you.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isWishlistEnabled,
                      activeColor: AppTheme.accentYellow,
                      onChanged: (val) => setState(() => _isWishlistEnabled = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Create Room CTA
              ElevatedButton(
                onPressed: isLoading ? null : _submitRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentYellow,
                  foregroundColor: AppTheme.textDark,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.textDark),
                      )
                    : Text(
                        'Create Room & Get Link',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: AppTheme.accentYellow,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 14),
      filled: true,
      fillColor: AppTheme.surfaceDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.accentYellow, width: 2),
      ),
    );
  }
}
