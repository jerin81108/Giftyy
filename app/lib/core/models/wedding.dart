class Wedding {
  final String id;
  final String slug;
  final String partner1Name;
  final String partner2Name;
  final DateTime date;
  final String city;
  final String? coverImageUrl;
  final String story;
  final int totalTarget;
  final int totalRaised;
  final int contributorCount;
  final bool showAmounts;
  final bool kycVerified;
  final String status;
  final String? invitationCardUrl;

  Wedding({
    required this.id,
    required this.slug,
    required this.partner1Name,
    required this.partner2Name,
    required this.date,
    required this.city,
    this.coverImageUrl,
    required this.story,
    required this.totalTarget,
    required this.totalRaised,
    required this.contributorCount,
    this.showAmounts = true,
    this.kycVerified = false,
    this.status = 'draft',
    this.invitationCardUrl,
  });

  String get coupleTitle => '$partner1Name & $partner2Name';

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

  factory Wedding.fromJson(Map<String, dynamic> json) {
    return Wedding(
      id: json['_id'] ?? json['id'] ?? '',
      slug: json['slug'] ?? '',
      partner1Name: json['partner1Name'] ?? '',
      partner2Name: json['partner2Name'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      city: json['city'] ?? 'India',
      coverImageUrl: json['coverImageUrl'],
      story: json['story'] ?? '',
      totalTarget: (json['totalTarget'] ?? 0) as int,
      totalRaised: (json['totalRaised'] ?? 0) as int,
      contributorCount: (json['contributorCount'] ?? 0) as int,
      showAmounts: json['showAmounts'] ?? true,
      kycVerified: json['kycVerified'] ?? false,
      status: json['status'] ?? 'draft',
      invitationCardUrl: json['invitationCardUrl'],
    );
  }
}
