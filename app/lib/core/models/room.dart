class Room {
  final String id;
  final String hostId;
  final String eventType;
  final String title;
  final String honoreeName;
  final String? partner2Name;
  final DateTime date;
  final String venue;
  final String city;
  final String? coverImageUrl;
  final String story;
  final String privacy; // 'public' | 'private'
  final String slug;
  final String roomCode;
  final String? qrUrl;
  final String status;
  final bool isWishlistEnabled;
  final bool showAmounts;
  final bool kycVerified;
  final int memberCount;
  final int totalTarget;
  final int totalRaised;
  final int contributorCount;
  final bool requiresApproval;

  Room({
    required this.id,
    required this.hostId,
    required this.eventType,
    required this.title,
    required this.honoreeName,
    this.partner2Name,
    required this.date,
    required this.venue,
    required this.city,
    this.coverImageUrl,
    required this.story,
    required this.privacy,
    required this.slug,
    required this.roomCode,
    this.qrUrl,
    required this.status,
    this.isWishlistEnabled = true,
    this.showAmounts = true,
    this.kycVerified = false,
    this.memberCount = 1,
    this.totalTarget = 0,
    this.totalRaised = 0,
    this.contributorCount = 0,
    this.requiresApproval = false,
  });

  bool get isPrivate => privacy == 'private';
  bool get isPublic => privacy == 'public';

  String get displayTitle {
    if (title.isNotEmpty) return title;
    if (partner2Name != null && partner2Name!.isNotEmpty) {
      return '$honoreeName & $partner2Name';
    }
    return '$honoreeName\'s Celebration';
  }

  double get overallProgress {
    if (totalTarget <= 0) return 0.0;
    return (totalRaised / totalTarget).clamp(0.0, 1.0);
  }

  int get overallPercent {
    return (overallProgress * 100).round();
  }

  int get daysRemaining {
    final now = DateTime.now();
    return date.difference(now).inDays;
  }

  bool get isChildEvent {
    return ['ear_piercing', 'baby_shower', 'birthday', 'coming_of_age'].contains(eventType);
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['_id'] ?? json['id'] ?? '',
      hostId: json['hostId'] ?? json['ownerId'] ?? '',
      eventType: json['eventType'] ?? 'wedding',
      title: json['title'] ?? '',
      honoreeName: json['honoreeName'] ?? json['partner1Name'] ?? 'Host',
      partner2Name: json['partner2Name'],
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      venue: json['venue'] ?? '',
      city: json['city'] ?? 'India',
      coverImageUrl: json['coverImageUrl'],
      story: json['story'] ?? '',
      privacy: json['privacy'] ?? (json['isPublic'] == false ? 'private' : 'public'),
      slug: json['slug'] ?? '',
      roomCode: json['roomCode'] ?? '',
      qrUrl: json['qrUrl'],
      status: json['status'] ?? 'active',
      isWishlistEnabled: json['isWishlistEnabled'] ?? true,
      showAmounts: json['showAmounts'] ?? true,
      kycVerified: json['kycVerified'] ?? false,
      memberCount: (json['memberCount'] ?? 1) as int,
      totalTarget: (json['totalTarget'] ?? 0) as int,
      totalRaised: (json['totalRaised'] ?? 0) as int,
      contributorCount: (json['contributorCount'] ?? 0) as int,
      requiresApproval: json['requiresApproval'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostId': hostId,
      'eventType': eventType,
      'title': title,
      'honoreeName': honoreeName,
      'partner2Name': partner2Name,
      'date': date.toIso8601String(),
      'venue': venue,
      'city': city,
      'coverImageUrl': coverImageUrl,
      'story': story,
      'privacy': privacy,
      'slug': slug,
      'roomCode': roomCode,
      'qrUrl': qrUrl,
      'status': status,
      'isWishlistEnabled': isWishlistEnabled,
      'showAmounts': showAmounts,
      'kycVerified': kycVerified,
      'memberCount': memberCount,
      'totalTarget': totalTarget,
      'totalRaised': totalRaised,
      'contributorCount': contributorCount,
      'requiresApproval': requiresApproval,
    };
  }
}
