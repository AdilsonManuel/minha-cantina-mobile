class TopupModel {
  final int id;
  final int walletId;
  final double amount;
  final String paymentMethod;
  final String? proofUrl;
  final String status;
  final String? rejectionReason;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  const TopupModel({
    required this.id,
    required this.walletId,
    required this.amount,
    required this.paymentMethod,
    this.proofUrl,
    required this.status,
    this.rejectionReason,
    this.reviewedByName,
    this.reviewedAt,
    required this.createdAt,
  });

  factory TopupModel.fromJson(Map<String, dynamic> json) {
    return TopupModel(
      id: json['id'] as int,
      walletId: json['walletId'] as int,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      proofUrl: json['proofUrl'] as String?,
      status: json['status'] as String,
      rejectionReason: json['rejectionReason'] as String?,
      reviewedByName: json['reviewedByName'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
