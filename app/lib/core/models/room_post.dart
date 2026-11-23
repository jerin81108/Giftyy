class RoomPost {
  final String id;
  final String roomId;
  final String? memberId;
  final String authorName;
  final String authorRole; // 'host' | 'co_host' | 'member'
  final String type; // 'blessing' | 'photo' | 'announcement'
  final String content;
  final String? mediaUrl;
  final bool isPinned;
  final DateTime createdAt;

  RoomPost({
    required this.id,
    required this.roomId,
    this.memberId,
    required this.authorName,
    required this.authorRole,
    required this.type,
    required this.content,
    this.mediaUrl,
    this.isPinned = false,
    required this.createdAt,
  });

  bool get isAnnouncement => type == 'announcement';
  bool get isPhoto => type == 'photo';
  bool get isBlessing => type == 'blessing';

  factory RoomPost.fromJson(Map<String, dynamic> json) {
    return RoomPost(
      id: json['_id'] ?? json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      memberId: json['memberId'],
      authorName: json['authorName'] ?? 'Guest',
      authorRole: json['authorRole'] ?? 'member',
      type: json['type'] ?? 'blessing',
      content: json['content'] ?? '',
      mediaUrl: json['mediaUrl'],
      isPinned: json['isPinned'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'memberId': memberId,
      'authorName': authorName,
      'authorRole': authorRole,
      'type': type,
      'content': content,
      'mediaUrl': mediaUrl,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
