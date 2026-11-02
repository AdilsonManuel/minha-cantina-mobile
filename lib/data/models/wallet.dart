class WalletModel {
  final int walletId;
  final int userId;
  final double balance;
  final String currency;
  final DateTime updatedAt;

  const WalletModel({
    required this.walletId,
    required this.userId,
    required this.balance,
    required this.currency,
    required this.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      walletId: json['walletId'] as int,
      userId: json['userId'] as int,
      balance: (json['balance'] as num).toDouble(),
      currency: (json['currency'] as String?) ?? 'AOA',
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class WalletTransactionModel {
  final int id;
  final double amount;
  final String type;
  final double balanceBefore;
  final double balanceAfter;
  final String referenceType;
  final int referenceId;
  final String description;
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.referenceType,
    required this.referenceId,
    required this.description,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      balanceBefore: (json['balanceBefore'] as num).toDouble(),
      balanceAfter: (json['balanceAfter'] as num).toDouble(),
      referenceType: json['referenceType'] as String,
      referenceId: json['referenceId'] as int,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
