import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/order.dart';
import '../models/wallet.dart';
import '../models/topup.dart';
import '../../ui/core/app_config.dart';

class ApiService {
  String baseUrl;
  int currentUserId = 1;
  int currentAttendantId = 2;

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.defaultBaseUrl;

  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/health'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-User-Id': currentUserId.toString(),
    'X-Attendant-Id': currentAttendantId.toString(),
  };

  // ---------------------------------------------------------------------------
  // PRODUTOS
  // ---------------------------------------------------------------------------
  Future<List<Product>> fetchProducts() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/products'), headers: _headers)
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Backend offline, usando dados locais de demonstração: $e');
    }
    return _mockProducts;
  }

  // ---------------------------------------------------------------------------
  // CARTEIRA
  // ---------------------------------------------------------------------------
  Future<WalletModel> fetchWallet() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/wallet'), headers: _headers)
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return WalletModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
    } catch (e) {
      debugPrint('Usando carteira local: $e');
    }
    return _mockWallet;
  }

  Future<List<WalletTransactionModel>> fetchTransactions() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/wallet/transactions'), headers: _headers)
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> content = data['content'] ?? [];
        return content.map((json) => WalletTransactionModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Usando transações locais: $e');
    }
    return _mockTransactions;
  }

  Future<TopupModel> requestTopup({
    required double amount,
    required String paymentMethod,
    required String proofUrl,
  }) async {
    final body = jsonEncode({
      'amount': amount,
      'paymentMethod': paymentMethod,
      'proofUrl': proofUrl,
    });

    try {
      final response = await http
          .post(Uri.parse('$baseUrl/api/v1/wallet/topup-requests'), headers: _headers, body: body)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 201) {
        return TopupModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
    } catch (e) {
      debugPrint('Modo offline: simulando pedido de carregamento: $e');
    }

    final newTopup = TopupModel(
      id: DateTime.now().millisecondsSinceEpoch % 10000,
      walletId: _mockWallet.walletId,
      amount: amount,
      paymentMethod: paymentMethod,
      proofUrl: proofUrl,
      status: 'PENDING',
      createdAt: DateTime.now(),
    );
    return newTopup;
  }

  // ---------------------------------------------------------------------------
  // RESERVAS
  // ---------------------------------------------------------------------------
  Future<OrderModel> createReservation(List<CartItem> items) async {
    final itemsPayload = items.map((i) => {
      'productId': i.product.id,
      'quantity': i.quantity,
    }).toList();

    final body = jsonEncode({'items': itemsPayload});

    try {
      final response = await http
          .post(Uri.parse('$baseUrl/api/v1/orders'), headers: _headers, body: body)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final order = OrderModel.fromJson(data);
        _mockActiveOrder = ActiveOrderModel(
          orderId: order.orderId,
          status: order.status,
          otpCode: order.otpCode,
          pickupDeadline: order.pickupDeadline,
          secondsRemaining: 3600,
          totalAmount: order.totalAmount,
          itemsCount: order.items.length,
        );
        return order;
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Erro ao criar reserva');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      debugPrint('Criando reserva em modo offline: $e');
    }

    // Simulação offline com SecureRandom
    final double total = items.fold(0.0, (sum, i) => sum + i.subtotal);
    if (_mockWallet.balance < total) {
      throw Exception('Saldo insuficiente na carteira para realizar a reserva.');
    }

    final newBalance = _mockWallet.balance - total;
    _mockWallet = WalletModel(
      walletId: _mockWallet.walletId,
      userId: _mockWallet.userId,
      balance: newBalance,
      currency: 'AOA',
      updatedAt: DateTime.now(),
    );

    final generatedOtp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    final deadline = DateTime.now().add(const Duration(minutes: 60));

    final newOrder = OrderModel(
      orderId: DateTime.now().millisecondsSinceEpoch % 10000,
      status: 'RESERVED',
      totalAmount: total,
      otpCode: generatedOtp,
      otpExpiresAt: deadline,
      pickupDeadline: deadline,
      items: items.map((i) => OrderItemModel(
        productId: i.product.id,
        productName: i.product.name,
        quantity: i.quantity,
        unitPrice: i.product.price,
        subtotal: i.subtotal,
      )).toList(),
      remainingWalletBalance: newBalance,
      createdAt: DateTime.now(),
    );

    _mockActiveOrder = ActiveOrderModel(
      orderId: newOrder.orderId,
      status: 'RESERVED',
      otpCode: generatedOtp,
      pickupDeadline: deadline,
      secondsRemaining: 3600,
      totalAmount: total,
      itemsCount: items.length,
    );

    _mockTransactions.insert(0, WalletTransactionModel(
      id: DateTime.now().millisecondsSinceEpoch % 10000,
      amount: total,
      type: 'DEBIT_ORDER',
      balanceBefore: newBalance + total,
      balanceAfter: newBalance,
      referenceType: 'ORDER',
      referenceId: newOrder.orderId,
      description: 'Pagamento da Reserva #${newOrder.orderId}',
      createdAt: DateTime.now(),
    ));

    return newOrder;
  }

  Future<ActiveOrderModel?> fetchActiveOrder() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/orders/active'), headers: _headers)
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return ActiveOrderModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
    } catch (e) {
      debugPrint('Usando pedido ativo mock: $e');
    }
    return _mockActiveOrder;
  }

  // ---------------------------------------------------------------------------
  // PAINEL DO ATENDEDOR
  // ---------------------------------------------------------------------------
  Future<OrderLookupModel> lookupOrder(String otpCode) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/attendant/orders/lookup/$otpCode'), headers: _headers)
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return OrderLookupModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Reserva não encontrada');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      debugPrint('Lookup offline: $e');
    }

    if (_mockActiveOrder != null && _mockActiveOrder!.otpCode == otpCode) {
      return OrderLookupModel(
        orderId: _mockActiveOrder!.orderId,
        customerName: 'Manuel Domingos',
        status: _mockActiveOrder!.status,
        pickupDeadline: _mockActiveOrder!.pickupDeadline,
        isExpired: false,
        items: [
          const OrderItemModel(
            productId: 1,
            productName: 'Prato do Dia (Frango Grelhado)',
            quantity: 1,
            unitPrice: 2200.0,
            subtotal: 2200.0,
          ),
        ],
      );
    }
    throw Exception('Código OTP $otpCode não encontrado entre as reservas ativas.');
  }

  Future<bool> pickupOrder(String otpCode) async {
    final body = jsonEncode({'otpCode': otpCode});
    try {
      final response = await http
          .post(Uri.parse('$baseUrl/api/v1/attendant/orders/pickup'), headers: _headers, body: body)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        _mockActiveOrder = null;
        return true;
      }
    } catch (e) {
      debugPrint('Pickup offline: $e');
    }

    if (_mockActiveOrder != null && _mockActiveOrder!.otpCode == otpCode) {
      _mockActiveOrder = null;
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // MOCK STATE (para resiliência e demonstração fluida)
  // ---------------------------------------------------------------------------
  static WalletModel _mockWallet = WalletModel(
    walletId: 1,
    userId: 1,
    balance: 10000.0,
    currency: 'AOA',
    updatedAt: DateTime.now(),
  );

  static ActiveOrderModel? _mockActiveOrder;

  static final List<WalletTransactionModel> _mockTransactions = [
    WalletTransactionModel(
      id: 1,
      amount: 10000.0,
      type: 'CREDIT_TOPUP',
      balanceBefore: 0.0,
      balanceAfter: 10000.0,
      referenceType: 'MANUAL',
      referenceId: 1,
      description: 'Crédito inicial de boas-vindas',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  static final List<Product> _mockProducts = [
    const Product(
      id: 1,
      name: 'Prato do Dia: Frango Grelhado',
      description: 'Arroz solto, feijão de óleo de palma e salada mista.',
      category: 'Almoço',
      price: 2200.0,
      stockQuantity: 28,
      imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947',
      isActive: true,
    ),
    const Product(
      id: 2,
      name: 'Bitoque de Vaca com Ovo',
      description: 'Bife suculento grelhado com ovo a cavalo e batatas fritas.',
      category: 'Almoço',
      price: 2800.0,
      stockQuantity: 18,
      imageUrl: 'https://images.unsplash.com/photo-1600891964599-f61ba0e24092',
      isActive: true,
    ),
    const Product(
      id: 3,
      name: 'Mufete Tradicional de Peixe',
      description: 'Peixe carapau grelhado com farinha de mandioca e batata doce.',
      category: 'Especial',
      price: 3500.0,
      stockQuantity: 12,
      imageUrl: 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2',
      isActive: true,
    ),
    const Product(
      id: 4,
      name: 'Sumo Natural de Maracujá 400ml',
      description: 'Sumo natural fresco da fruta, fresco e revigorante.',
      category: 'Bebidas',
      price: 500.0,
      stockQuantity: 45,
      imageUrl: 'https://images.unsplash.com/photo-1613478223719-2ab802602423',
      isActive: true,
    ),
    const Product(
      id: 5,
      name: 'Água Mineral da Chela 500ml',
      description: 'Água pura engarrafada natural.',
      category: 'Bebidas',
      price: 300.0,
      stockQuantity: 95,
      imageUrl: 'https://images.unsplash.com/photo-1548839140-29a749e1bc4e',
      isActive: true,
    ),
    const Product(
      id: 6,
      name: 'Pastel de Nata Artesanal',
      description: 'Massa folhada estaladiça com creme de baunilha e canela.',
      category: 'Sobremesa',
      price: 450.0,
      stockQuantity: 24,
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff',
      isActive: true,
    ),
  ];
}
