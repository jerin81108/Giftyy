class RoomMember {
  final String id;
  final String roomId;
  final String? userId;
  final String? guestId;
  final String displayName;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final String role; // 'host' | 'co_host' | 'member'
  final String status; // 'pending' | 'approved' | 'removed'
  final String rsvpStatus; // 'attending' | 'not_attending' | 'maybe' | 'none'
  final int guestCount;
  final DateTime joinedAt;

  RoomMember({
    required this.id,
    required this.roomId,
    this.userId,
    this.guestId,
    required this.displayName,
    this.phone,
    this.email,
    this.avatarUrl,
    required this.role,
    required this.status,
    required this.rsvpStatus,
    this.guestCount = 1,
    required this.joinedAt,
  });

  bool get isHost => role == 'host';
  bool get isCoHost => role == 'co_host';
  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';

  factory RoomMember.fromJson(Map<String, dynamic> json) {
    return RoomMember(
      id: json['_id'] ?? json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      userId: json['userId'],
      guestId: json['guestId'],
      displayName: json['displayName'] ?? 'Guest',
      phone: json['phone'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      role: json['role'] ?? 'member',
      status: json['status'] ?? 'approved',
      rsvpStatus: json['rsvpStatus'] ?? 'none',
      guestCount: (json['guestCount'] ?? 1) as int,
      joinedAt: json['joinedAt'] != null ? DateTime.parse(json['joinedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'userId': userId,
      'guestId': guestId,
      'displayName': displayName,
      'phone': phone,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role,
      'status': status,
      'rsvpStatus': rsvpStatus,
      'guestCount': guestCount,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}
