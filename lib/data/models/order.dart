class OrderItemModel {
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }
}

class OrderModel {
  final int orderId;
  final String status;
  final double totalAmount;
  final String otpCode;
  final DateTime otpExpiresAt;
  final DateTime pickupDeadline;
  final List<OrderItemModel> items;
  final double remainingWalletBalance;
  final DateTime createdAt;

  const OrderModel({
    required this.orderId,
    required this.status,
    required this.totalAmount,
    required this.otpCode,
    required this.otpExpiresAt,
    required this.pickupDeadline,
    required this.items,
    required this.remainingWalletBalance,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['orderId'] as int,
      status: json['status'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      otpCode: json['otpCode'] as String,
      otpExpiresAt: DateTime.parse(json['otpExpiresAt'] as String),
      pickupDeadline: DateTime.parse(json['pickupDeadline'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      remainingWalletBalance:
          (json['remainingWalletBalance'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ActiveOrderModel {
  final int orderId;
  final String status;
  final String otpCode;
  final DateTime pickupDeadline;
  final int secondsRemaining;
  final double totalAmount;
  final int itemsCount;

  const ActiveOrderModel({
    required this.orderId,
    required this.status,
    required this.otpCode,
    required this.pickupDeadline,
    required this.secondsRemaining,
    required this.totalAmount,
    required this.itemsCount,
  });

  factory ActiveOrderModel.fromJson(Map<String, dynamic> json) {
    return ActiveOrderModel(
      orderId: json['orderId'] as int,
      status: json['status'] as String,
      otpCode: json['otpCode'] as String,
      pickupDeadline: DateTime.parse(json['pickupDeadline'] as String),
      secondsRemaining: json['secondsRemaining'] as int,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      itemsCount: json['itemsCount'] as int,
    );
  }
}

class OrderLookupModel {
  final int orderId;
  final String customerName;
  final String status;
  final DateTime pickupDeadline;
  final bool isExpired;
  final List<OrderItemModel> items;

  const OrderLookupModel({
    required this.orderId,
    required this.customerName,
    required this.status,
    required this.pickupDeadline,
    required this.isExpired,
    required this.items,
  });

  factory OrderLookupModel.fromJson(Map<String, dynamic> json) {
    return OrderLookupModel(
      orderId: json['orderId'] as int,
      customerName: json['customerName'] as String,
      status: json['status'] as String,
      pickupDeadline: DateTime.parse(json['pickupDeadline'] as String),
      isExpired: (json['isExpired'] as bool?) ?? false,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
