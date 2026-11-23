class WishlistItem {
  final String id;
  final String weddingId;
  final String title;
  final String description;
  final String icon;
  final int targetAmount;
  final int raisedAmount;
  final int contributorCount;
  final int priority;
  final String status;
  final int percentFunded;
  final bool isFullyFunded;

  WishlistItem({
    required this.id,
    required this.weddingId,
    required this.title,
    required this.description,
    required this.icon,
    required this.targetAmount,
    required this.raisedAmount,
    required this.contributorCount,
    required this.priority,
    required this.status,
    required this.percentFunded,
    required this.isFullyFunded,
  });

  double get progressRatio {
    if (targetAmount <= 0) return 0.0;
    return (raisedAmount / targetAmount).clamp(0.0, 1.0);
  }

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    final target = (json['targetAmount'] ?? 0) as int;
    final raised = (json['raisedAmount'] ?? 0) as int;
    final calculatedPercent = target > 0 ? ((raised / target) * 100).round() : 0;

    return WishlistItem(
      id: json['_id'] ?? json['id'] ?? '',
      weddingId: json['weddingId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'gift',
      targetAmount: target,
      raisedAmount: raised,
      contributorCount: (json['contributorCount'] ?? 0) as int,
      priority: (json['priority'] ?? 1) as int,
      status: json['status'] ?? 'active',
      percentFunded: json['percentFunded'] ?? calculatedPercent,
      isFullyFunded: json['isFullyFunded'] ?? (raised >= target),
    );
  }
}
