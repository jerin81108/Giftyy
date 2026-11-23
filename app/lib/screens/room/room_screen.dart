import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/theme.dart';
import '../../core/models/room.dart';
import '../../core/models/wishlist_item.dart';
import '../../providers/room_provider.dart';

class RoomScreen extends StatefulWidget {
  final String slugOrCode;

  const RoomScreen({super.key, required this.slugOrCode});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _joinNameController = TextEditingController();
  final TextEditingController _blessingController = TextEditingController();

  String _currentRsvp = 'none';
  final int _rsvpGuestCount = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomProvider>().loadRoom(widget.slugOrCode);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _joinNameController.dispose();
    _blessingController.dispose();
    super.dispose();
  }

  void _onRsvpPressed(String status) async {
    setState(() => _currentRsvp = status);
    final provider = context.read<RoomProvider>();
    final success = await provider.submitRsvp(
      rsvpStatus: status,
      guestCount: _rsvpGuestCount,
      displayName: _joinNameController.text.isNotEmpty ? _joinNameController.text : null,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('RSVP updated: ${status.toUpperCase()}!')),
      );
    }
  }

  void _submitBlessing() async {
    final text = _blessingController.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<RoomProvider>();
    final success = await provider.createPost(
      type: 'blessing',
      content: text,
      authorName: _joinNameController.text.isNotEmpty ? _joinNameController.text : 'A Well-Wisher',
    );

    if (success) {
      _blessingController.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blessing posted to guestbook! ✨')),
        );
      }
    }
  }

  void _showAddPhotoDialog() {
    final urlController = TextEditingController();
    final captionController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Photo to Shared Album',
          style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
              decoration: const InputDecoration(
                hintText: 'Photo Image URL',
                hintStyle: TextStyle(color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: captionController,
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
              decoration: const InputDecoration(
                hintText: 'Short caption / memory note',
                hintStyle: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (urlController.text.trim().isNotEmpty) {
                await context.read<RoomProvider>().createPost(
                  type: 'photo',
                  content: captionController.text.trim(),
                  mediaUrl: urlController.text.trim(),
                );
                if (mounted) Navigator.pop(dialogCtx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentYellow,
              foregroundColor: AppTheme.textDark,
            ),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  void _showQrDialog(Room room) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              room.displayTitle,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppTheme.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 180, color: Colors.black),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ROOM CODE: ${room.roomCode}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: AppTheme.accentYellow,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContributeSheet(WishlistItem item) {
    int selectedAmount = 2000;
    final nameController = TextEditingController(text: _joinNameController.text);
    final msgController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Contribute to ${item.title}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Skip the gifts. Fund the dream via UPI ✨',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.accentYellow),
              ),
              const SizedBox(height: 16),
              // Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [500, 2000, 5000].map((amt) {
                  final isSelected = selectedAmount == amt;
                  return ChoiceChip(
                    label: Text('₹${amt.toString()}'),
                    selected: isSelected,
                    selectedColor: AppTheme.accentYellow,
                    backgroundColor: AppTheme.surfaceDark,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      color: isSelected ? AppTheme.textDark : AppTheme.textLight,
                      fontWeight: FontWeight.w800,
                    ),
                    onSelected: (_) => setSheetState(() => selectedAmount = amt),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: const InputDecoration(
                  hintText: 'Your Name',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.surfaceDark,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: msgController,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: const InputDecoration(
                  hintText: 'Blessing / wish for host...',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.surfaceDark,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.cardBackground,
                      content: Text(
                        '🎉 Payment of ₹$selectedAmount simulated via UPI! Contribution recorded.',
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.accentYellow, fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentYellow,
                  foregroundColor: AppTheme.textDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Pay ₹$selectedAmount via UPI',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
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
    final provider = context.watch<RoomProvider>();
    final room = provider.currentRoom;

    if (provider.isLoading && room == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accentYellow),
        ),
      );
    }

    if (room == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 60, color: AppTheme.textMuted),
                const SizedBox(height: 16),
                Text(
                  provider.errorMessage ?? 'Room Not Found',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentYellow,
                    foregroundColor: AppTheme.textDark,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Collapsible Header with Cover Image & Title
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_rounded, color: AppTheme.accentYellow),
                onPressed: () => _showQrDialog(room),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (room.coverImageUrl != null)
                    Image.network(
                      room.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceDark),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withAlpha(50), AppTheme.background],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentYellow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            room.eventType.toUpperCase().replaceAll('_', ' '),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          room.displayTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${room.city} · ${room.date.day}/${room.date.month}/${room.date.year}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'CODE: ${room.roomCode}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.accentYellow,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // If Private Room and visitor is NOT approved
          if (room.isPrivate && !provider.isApproved)
            SliverToBoxAdapter(
              child: _buildPrivateGate(context, provider),
            )
          else ...[
            // RSVP Action Card
            SliverToBoxAdapter(
              child: _buildRsvpCard(provider),
            ),

            // Tab Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.accentYellow,
                  indicatorWeight: 3,
                  labelColor: AppTheme.accentYellow,
                  unselectedLabelColor: AppTheme.textMuted,
                  isScrollable: true,
                  labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                  tabs: [
                    const Tab(text: 'Overview'),
                    Tab(text: room.isWishlistEnabled ? 'Wishlist Goals' : 'Details'),
                    const Tab(text: 'Guestbook'),
                    const Tab(text: 'Album'),
                    Tab(text: provider.canManage ? 'Host & Members' : 'Members'),
                  ],
                ),
              ),
            ),

            // Tab View Body
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(room),
                  _buildWishlistTab(provider),
                  _buildGuestbookTab(provider),
                  _buildAlbumTab(provider),
                  _buildMembersTab(provider),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Private Room Gate ---
  Widget _buildPrivateGate(BuildContext context, RoomProvider provider) {
    final isPending = provider.membershipStatus == 'pending';

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentYellow.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_rounded, color: AppTheme.accentYellow, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Private Family Event Room',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isPending
                ? 'Your join request has been sent! The host will review and approve your access shortly.'
                : 'This ceremony room is private to family & close friends. Please enter your name to request access from the host.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          if (!isPending) ...[
            TextField(
              controller: _joinNameController,
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
              decoration: InputDecoration(
                hintText: 'Your Full Name (e.g. Kavita Aunty)',
                hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final name = _joinNameController.text.trim();
                if (name.isNotEmpty) {
                  provider.joinRoom(displayName: name);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentYellow,
                foregroundColor: AppTheme.textDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Request Access to Room',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentYellow),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Awaiting host approval...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentYellow,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- RSVP Card ---
  Widget _buildRsvpCard(RoomProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WILL YOU BE ATTENDING?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.accentYellow,
                ),
              ),
              Text(
                '${provider.rsvpTally['attending'] ?? 0} Attending',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRsvpButton('Attending', 'attending', Icons.check_circle_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRsvpButton('Maybe', 'maybe', Icons.help_outline_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRsvpButton('Decline', 'not_attending', Icons.cancel_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRsvpButton(String label, String value, IconData icon) {
    final isSelected = _currentRsvp == value;
    return GestureDetector(
      onTap: () => _onRsvpPressed(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentYellow : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: isSelected ? AppTheme.textDark : AppTheme.textMuted),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppTheme.textDark : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Tab 1: Overview ---
  Widget _buildOverviewTab(Room room) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (room.story.isNotEmpty) ...[
          Text(
            'HOST INVITATION MESSAGE',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.accentYellow),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.cardBackground, borderRadius: BorderRadius.circular(16)),
            child: Text(
              room.story,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textLight, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
        ],

        Text(
          'VENUE & TIMINGS',
          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.accentYellow),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.cardBackground, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                room.venue.isNotEmpty ? room.venue : 'Venue TBA',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textLight),
              ),
              const SizedBox(height: 4),
              Text(
                room.city,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Tab 2: Wishlist Goals (Reel Dark & Yellow Design) ---
  Widget _buildWishlistTab(RoomProvider provider) {
    final items = provider.wishlistItems;

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No wishlist goals added to this room.',
          style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, idx) {
        final item = items[idx];
        final isFirst = idx == 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isFirst ? AppTheme.accentYellow : Colors.white12,
              width: isFirst ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isFirst)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentYellow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'TOP DREAM GOAL',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              Text(
                item.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.description,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: item.progressRatio,
                  minHeight: 10,
                  backgroundColor: AppTheme.surfaceDark,
                  color: AppTheme.accentYellow,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${item.raisedAmount} raised',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accentYellow,
                    ),
                  ),
                  Text(
                    'Target: ₹${item.targetAmount}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showContributeSheet(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFirst ? AppTheme.accentYellow : AppTheme.surfaceDark,
                  foregroundColor: isFirst ? AppTheme.textDark : AppTheme.textLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size.fromHeight(46),
                ),
                child: Text(
                  'Contribute via UPI ✨',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Tab 3: Guestbook Blessings ---
  Widget _buildGuestbookTab(RoomProvider provider) {
    final blessings = provider.posts.where((p) => p.isBlessing).toList();

    return Column(
      children: [
        // Blessings List
        Expanded(
          child: blessings.isEmpty
              ? Center(
                  child: Text(
                    'Be the first to leave a warm blessing! ✨',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: blessings.length,
                  itemBuilder: (context, idx) {
                    final post = blessings[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                post.authorName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.accentYellow,
                                ),
                              ),
                              Text(
                                '${post.createdAt.day}/${post.createdAt.month}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            post.content,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppTheme.textLight, height: 1.4),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Bottom Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _blessingController,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight),
                  decoration: InputDecoration(
                    hintText: 'Write a heartfelt blessing...',
                    hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppTheme.accentYellow),
                onPressed: _submitBlessing,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Tab 4: Shared Album ---
  Widget _buildAlbumTab(RoomProvider provider) {
    final photos = provider.posts.where((p) => p.isPhoto).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPhotoDialog,
        backgroundColor: AppTheme.accentYellow,
        foregroundColor: AppTheme.textDark,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: Text('Add Photo', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
      ),
      body: photos.isEmpty
          ? Center(
              child: Text(
                'No photos shared yet. Tap below to add moments!',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              itemCount: photos.length,
              itemBuilder: (context, idx) {
                final photo = photos[idx];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (photo.mediaUrl != null)
                        Image.network(
                          photo.mediaUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceDark),
                        ),
                      if (photo.content.isNotEmpty)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.black.withAlpha(160),
                            child: Text(
                              photo.content,
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // --- Tab 5: Members & Host Controls ---
  Widget _buildMembersTab(RoomProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Pending Requests Queue (Host view)
        if (provider.canManage && provider.pendingRequests.isNotEmpty) ...[
          Text(
            'PENDING JOIN REQUESTS (${provider.pendingRequests.length})',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppTheme.accentYellow,
            ),
          ),
          const SizedBox(height: 10),
          ...provider.pendingRequests.map((req) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accentYellow.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.surfaceDark,
                      child: Text(
                        req.displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: AppTheme.accentYellow),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        req.displayName,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppTheme.textLight),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                      onPressed: () => provider.approveMember(req.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent),
                      onPressed: () => provider.removeMember(req.id),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),
        ],

        // Approved Members
        Text(
          'MEMBERS IN ROOM (${provider.members.length})',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppTheme.accentYellow,
          ),
        ),
        const SizedBox(height: 10),
        ...provider.members.map((m) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.cardBackground, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.surfaceDark,
                    child: Text(
                      m.displayName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: AppTheme.accentYellow),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.displayName,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppTheme.textLight),
                        ),
                        if (m.rsvpStatus != 'none')
                          Text(
                            'RSVP: ${m.rsvpStatus.toUpperCase()}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: m.isHost ? AppTheme.accentYellow : AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      m.role.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: m.isHost ? AppTheme.textDark : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) {
    return false;
  }
}
