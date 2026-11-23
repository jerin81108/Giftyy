import 'package:flutter/material.dart';
import '../core/models/room.dart';
import '../core/models/room_member.dart';
import '../core/models/room_post.dart';
import '../core/models/wishlist_item.dart';
import '../core/network/api_service.dart';

class RoomProvider extends ChangeNotifier {
  bool _isLoading = false;
  Room? _currentRoom;
  List<WishlistItem> _wishlistItems = [];
  List<RoomMember> _members = [];
  List<RoomMember> _pendingRequests = [];
  List<RoomPost> _posts = [];

  String _membershipStatus = 'none'; // 'approved', 'pending', 'none'
  String _userRole = 'guest'; // 'host', 'co_host', 'member', 'guest'
  bool _isApproved = false;
  String? _errorMessage;

  Map<String, int> _rsvpTally = {
    'attending': 0,
    'maybe': 0,
    'notAttending': 0,
  };

  // Device guest ID
  late final String _guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';

  // Getters
  bool get isLoading => _isLoading;
  Room? get currentRoom => _currentRoom;
  List<WishlistItem> get wishlistItems => _wishlistItems;
  List<RoomMember> get members => _members;
  List<RoomMember> get pendingRequests => _pendingRequests;
  List<RoomPost> get posts => _posts;
  String get membershipStatus => _membershipStatus;
  String get userRole => _userRole;
  bool get isApproved => _isApproved;
  bool get isHost => _userRole == 'host';
  bool get isCoHost => _userRole == 'co_host';
  bool get canManage => isHost || isCoHost;
  String? get errorMessage => _errorMessage;
  Map<String, int> get rsvpTally => _rsvpTally;
  String get guestId => _guestId;

  // Load Room Details
  Future<bool> loadRoom(String slugOrCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.getRoom(slugOrCode.trim(), guestId: _guestId);
      _isLoading = false;

      if (res['success'] == true && res['room'] != null) {
        _currentRoom = Room.fromJson(res['room']);
        _membershipStatus = res['membershipStatus'] ?? 'none';
        _userRole = res['role'] ?? 'guest';
        _isApproved = res['isApproved'] == true || _membershipStatus == 'approved' || _userRole == 'host';

        // Load wishlist items if room is accessible & enabled
        if (_isApproved && _currentRoom!.isWishlistEnabled) {
          await _loadWishlistItems(_currentRoom!.id);
        }

        // Load members & posts
        if (_isApproved) {
          await _loadMembersAndPosts(_currentRoom!.id);
        }

        notifyListeners();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Could not find this event room.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Local fallback for demo / offline mode
      final clean = slugOrCode.toLowerCase().trim();
      if (_currentRoom != null && (_currentRoom!.slug.toLowerCase() == clean || _currentRoom!.roomCode.toLowerCase() == clean)) {
        _isLoading = false;
        notifyListeners();
        return true;
      }

      if (clean.contains('aisha') || clean == 'aisha2027') {
        _currentRoom = Room(
          id: 'demo_aisha',
          hostId: 'host_aisha',
          eventType: 'wedding',
          title: 'Aisha & Kabir Wedding',
          honoreeName: 'Aisha',
          partner2Name: 'Kabir',
          date: DateTime.now().add(const Duration(days: 45)),
          venue: 'Fateh Garh Palace',
          city: 'Udaipur, Rajasthan',
          coverImageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=1200&q=80',
          story: "Skip the gifts. Fund the dream! We're so blessed to have you in our lives. Help us fund our dream memories together! ✨",
          privacy: 'public',
          slug: 'aisha-kabir',
          roomCode: 'AISHA2027',
          status: 'active',
          isWishlistEnabled: true,
          totalTarget: 1550000,
          totalRaised: 441000,
          contributorCount: 79,
        );
        _wishlistItems = [
          WishlistItem(
            id: 'demo_w1',
            weddingId: 'demo_aisha',
            title: 'Honeymoon in Europe',
            description: 'Rome, Paris & Swiss Alps romantic getaway',
            icon: 'plane',
            targetAmount: 300000,
            raisedAmount: 216000,
            contributorCount: 48,
            priority: 1,
            status: 'active',
            percentFunded: 72,
            isFullyFunded: false,
          ),
          WishlistItem(
            id: 'demo_w2',
            weddingId: 'demo_aisha',
            title: 'First Home Down Payment',
            description: 'Building our cozy sanctuary together',
            icon: 'house',
            targetAmount: 1000000,
            raisedAmount: 180000,
            contributorCount: 22,
            priority: 2,
            status: 'active',
            percentFunded: 18,
            isFullyFunded: false,
          ),
        ];
        _membershipStatus = 'approved';
        _userRole = 'guest';
        _isApproved = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      if (clean.contains('priya') || clean == 'priya4821') {
        _currentRoom = Room(
          id: 'demo_priya',
          hostId: 'host_anita',
          eventType: 'ear_piercing',
          title: "Priya's Karnavedha Ceremony",
          honoreeName: 'Priya',
          date: DateTime.now().add(const Duration(days: 21)),
          venue: 'Sri Meenakshi Temple Mandapam',
          city: 'Bengaluru',
          coverImageUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=1200&q=80',
          story: "Our little Priya is turning two! We celebrate her sacred ear piercing ceremony with your heartfelt blessings.",
          privacy: 'private',
          slug: 'priya-ear-piercing-4821',
          roomCode: 'PRIYA4821',
          status: 'active',
          isWishlistEnabled: true,
        );
        _membershipStatus = 'approved';
        _userRole = 'host';
        _isApproved = true;
        _wishlistItems = [
          WishlistItem(
            id: 'demo_p1',
            weddingId: 'demo_priya',
            title: 'Traditional Gold Earrings',
            description: 'First 22K gold studs crafted with blessings',
            icon: 'gem',
            targetAmount: 25000,
            raisedAmount: 18000,
            contributorCount: 6,
            priority: 1,
            status: 'active',
            percentFunded: 72,
            isFullyFunded: false,
          ),
        ];
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _errorMessage = 'Could not load room. Please check room code.';
      notifyListeners();
      return false;
    }
  }

  Future<void> _loadWishlistItems(String roomId) async {
    try {
      final res = await ApiService.getWishlist(roomId);
      if (res['success'] == true && res['items'] != null) {
        _wishlistItems = (res['items'] as List)
            .map((item) => WishlistItem.fromJson(item))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _loadMembersAndPosts(String roomId) async {
    try {
      final membersRes = await ApiService.getRoomMembers(roomId, guestId: _guestId);
      if (membersRes['success'] == true) {
        if (membersRes['members'] != null) {
          _members = (membersRes['members'] as List)
              .map((m) => RoomMember.fromJson(m))
              .toList();
        }
        if (membersRes['pendingRequests'] != null) {
          _pendingRequests = (membersRes['pendingRequests'] as List)
              .map((m) => RoomMember.fromJson(m))
              .toList();
        }
      }

      final postsRes = await ApiService.getRoomPosts(roomId);
      if (postsRes['success'] == true && postsRes['posts'] != null) {
        _posts = (postsRes['posts'] as List)
            .map((p) => RoomPost.fromJson(p))
            .toList();
      }
    } catch (_) {}
  }

  // Join Room
  Future<bool> joinRoom({
    required String displayName,
    String? phone,
    String? email,
  }) async {
    if (_currentRoom == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.joinRoom(
        _currentRoom!.id,
        displayName: displayName,
        phone: phone,
        email: email,
        guestId: _guestId,
      );
      _isLoading = false;

      if (res['success'] == true) {
        final status = res['status'] ?? 'approved';
        _membershipStatus = status;
        _isApproved = status == 'approved';

        if (_isApproved) {
          await _loadWishlistItems(_currentRoom!.id);
          await _loadMembersAndPosts(_currentRoom!.id);
        }

        notifyListeners();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Failed to join room';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to submit join request';
      notifyListeners();
      return false;
    }
  }

  // Submit RSVP
  Future<bool> submitRsvp({
    required String rsvpStatus,
    int guestCount = 1,
    String? displayName,
  }) async {
    if (_currentRoom == null) return false;

    try {
      final res = await ApiService.submitRoomRsvp(
        _currentRoom!.id,
        rsvpStatus: rsvpStatus,
        guestCount: guestCount,
        displayName: displayName,
        guestId: _guestId,
      );

      if (res['success'] == true) {
        if (res['tally'] != null) {
          _rsvpTally = {
            'attending': (res['tally']['attendingCount'] ?? 0) as int,
            'maybe': (res['tally']['maybeCount'] ?? 0) as int,
            'notAttending': (res['tally']['notAttendingCount'] ?? 0) as int,
          };
        }
        await _loadMembersAndPosts(_currentRoom!.id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Post Blessing / Album Photo / Announcement
  Future<bool> createPost({
    required String type,
    required String content,
    String? mediaUrl,
    String? authorName,
  }) async {
    if (_currentRoom == null) return false;

    try {
      final res = await ApiService.createRoomPost(
        _currentRoom!.id,
        type: type,
        content: content,
        mediaUrl: mediaUrl,
        authorName: authorName,
      );

      if (res['success'] == true && res['post'] != null) {
        final newPost = RoomPost.fromJson(res['post']);
        _posts.insert(0, newPost);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Host Controls: Approve Member
  Future<bool> approveMember(String memberId) async {
    if (_currentRoom == null) return false;
    try {
      final res = await ApiService.updateMemberStatus(
        _currentRoom!.id,
        memberId,
        status: 'approved',
      );
      if (res['success'] == true) {
        await _loadMembersAndPosts(_currentRoom!.id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Host Controls: Remove Member
  Future<bool> removeMember(String memberId) async {
    if (_currentRoom == null) return false;
    try {
      final res = await ApiService.updateMemberStatus(
        _currentRoom!.id,
        memberId,
        status: 'removed',
      );
      if (res['success'] == true) {
        await _loadMembersAndPosts(_currentRoom!.id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Host Controls: Promote to Co-Host
  Future<bool> promoteToCoHost(String memberId) async {
    if (_currentRoom == null) return false;
    try {
      final res = await ApiService.updateMemberStatus(
        _currentRoom!.id,
        memberId,
        role: 'co_host',
      );
      if (res['success'] == true) {
        await _loadMembersAndPosts(_currentRoom!.id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Host Controls: Regenerate QR & Unguessable Link
  Future<Map<String, dynamic>?> regenerateQr() async {
    if (_currentRoom == null) return null;
    try {
      final res = await ApiService.regenerateRoomQr(_currentRoom!.id);
      if (res['success'] == true && res['room'] != null) {
        _currentRoom = Room.fromJson(res['room']);
        notifyListeners();
        return {
          'slug': res['slug'],
          'roomCode': res['roomCode'],
          'qrUrl': res['qrUrl'],
          'joinLink': res['joinLink'],
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Host Controls: Lock Room
  Future<bool> lockRoom() async {
    if (_currentRoom == null) return false;
    try {
      final res = await ApiService.lockRoom(_currentRoom!.id);
      if (res['success'] == true && res['room'] != null) {
        _currentRoom = Room.fromJson(res['room']);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Create Room
  Future<Map<String, dynamic>?> createRoom(Map<String, dynamic> roomData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.createRoom(roomData);
      _isLoading = false;

      if (res['success'] == true && res['room'] != null) {
        _currentRoom = Room.fromJson(res['room']);
        _membershipStatus = 'approved';
        _userRole = 'host';
        _isApproved = true;
        notifyListeners();
        return res;
      } else {
        _errorMessage = res['message'] ?? 'Failed to create room';
        notifyListeners();
        return null;
      }
    } catch (e) {
      // Local fallback in case backend server is offline or unreachable
      final honoree = (roomData['honoreeName'] as String?)?.trim().isNotEmpty == true
          ? (roomData['honoreeName'] as String).trim()
          : 'Celebration';
      final eventType = (roomData['eventType'] as String?) ?? 'wedding';
      final cleanName = honoree.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final cleanEvent = eventType.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
      final randomSuffix = (1000 + (DateTime.now().millisecond * 7) % 9000).toString();
      final slug = '$cleanName-$cleanEvent-$randomSuffix';
      final codePrefix = (cleanName.length >= 3 ? cleanName.substring(0, cleanName.length.clamp(3, 5)) : 'GIFT').toUpperCase();
      final roomCode = '$codePrefix$randomSuffix';

      final localRoom = Room(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        hostId: 'host_local',
        eventType: eventType,
        title: (roomData['title'] as String?) ?? '$honoree\'s Celebration',
        honoreeName: honoree,
        partner2Name: roomData['partner2Name'] as String?,
        date: roomData['date'] != null ? DateTime.parse(roomData['date'] as String) : DateTime.now().add(const Duration(days: 30)),
        venue: (roomData['venue'] as String?) ?? '',
        city: (roomData['city'] as String?) ?? 'India',
        coverImageUrl: roomData['coverImageUrl'] as String?,
        story: (roomData['story'] as String?) ?? '',
        privacy: (roomData['privacy'] as String?) ?? 'public',
        slug: slug,
        roomCode: roomCode,
        status: 'active',
        isWishlistEnabled: roomData['isWishlistEnabled'] == true,
      );

      _currentRoom = localRoom;
      _membershipStatus = 'approved';
      _userRole = 'host';
      _isApproved = true;

      // Seed local wishlist items if provided
      if (roomData['initialWishlist'] != null) {
        final list = roomData['initialWishlist'] as List;
        _wishlistItems = list.map((item) {
          final m = item as Map<String, dynamic>;
          return WishlistItem(
            id: 'item_${DateTime.now().millisecondsSinceEpoch}_${m['title']}',
            weddingId: localRoom.id,
            title: m['title'] ?? '',
            description: m['description'] ?? '',
            icon: m['icon'] ?? 'gift',
            targetAmount: (m['amount'] ?? 10000) as int,
            raisedAmount: 0,
            contributorCount: 0,
            priority: 1,
            status: 'active',
            percentFunded: 0,
            isFullyFunded: false,
          );
        }).toList();
      }

      _isLoading = false;
      notifyListeners();
      return {
        'success': true,
        'room': localRoom.toJson(),
        'joinLink': 'http://localhost:3000/r/$slug',
        'roomCode': roomCode,
        'isOffline': true,
      };
    }
  }
}
