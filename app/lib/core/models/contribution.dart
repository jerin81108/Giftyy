class Contribution {
  final String id;
  final String weddingId;
  final String? itemId;
  final String? itemTitle;
  final String guestName;
  final int? amount;
  final String? message;
  final DateTime createdAt;
  final String? status;

  Contribution({
    required this.id,
    required this.weddingId,
    this.itemId,
    this.itemTitle,
    required this.guestName,
    this.amount,
    this.message,
    required this.createdAt,
    this.status,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['_id'] ?? json['id'] ?? '',
      weddingId: json['weddingId'] ?? '',
      itemId: json['itemId'],
      itemTitle: json['itemTitle'],
      guestName: json['guestName'] ?? 'Generous Friend',
      amount: json['amount'] != null ? (json['amount'] as num).toInt() : null,
      message: json['message'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      status: json['status'] ?? 'paid',
    );
  }
}
