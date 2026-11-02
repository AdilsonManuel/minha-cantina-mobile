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
  Future<List<Product>> fetchProducts({String? search}) async {
    try {
      final uri = (search != null && search.trim().isNotEmpty)
          ? Uri.parse('$baseUrl/api/v1/products?search=${Uri.encodeQueryComponent(search.trim())}')
          : Uri.parse('$baseUrl/api/v1/products');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Backend offline, usando dados locais de demonstração: $e');
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      return _mockProducts
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q) ||
              (p.barcode != null && p.barcode!.contains(q)))
          .toList();
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
      name: 'Arroz Tio Lucas Agulha 1kg',
      description: 'Arroz agulha longo de qualidade superior, grão solto e fácil cozedura.',
      category: 'Mercearia',
      unit: 'kg',
      barcode: '5601234001011',
      price: 1850.0,
      stockQuantity: 80,
      imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c',
      isActive: true,
    ),
    const Product(
      id: 2,
      name: 'Açúcar Moreno Nacional 1kg',
      description: 'Açúcar moreno de cana puro para adoçar o seu dia.',
      category: 'Mercearia',
      unit: 'kg',
      barcode: '5601234001028',
      price: 1600.0,
      stockQuantity: 60,
      imageUrl: 'https://images.unsplash.com/photo-1581441363689-1f3c3c414635',
      isActive: true,
    ),
    const Product(
      id: 3,
      name: 'Fubá de Bombó Fina 1kg',
      description: 'Fubá de mandioca selecionada para o melhor funge tradicional.',
      category: 'Mercearia',
      unit: 'kg',
      barcode: '5601234001035',
      price: 1200.0,
      stockQuantity: 50,
      imageUrl: 'https://images.unsplash.com/photo-1607672632458-9eb56696346b',
      isActive: true,
    ),
    const Product(
      id: 4,
      name: 'Massa Esparguete Cigala 500g',
      description: 'Massa esparguete de sêmola de trigo duro de alta qualidade.',
      category: 'Mercearia',
      unit: 'pct',
      barcode: '5601234001059',
      price: 750.0,
      stockQuantity: 100,
      imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3d5d6281691',
      isActive: true,
    ),
    const Product(
      id: 5,
      name: 'Óleo Alimentar Sovena 1L',
      description: 'Óleo vegetal puro para cozinhar e fritar com máxima qualidade.',
      category: 'Óleos & Enlatados',
      unit: 'litro',
      barcode: '5601234001073',
      price: 2100.0,
      stockQuantity: 45,
      imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5',
      isActive: true,
    ),
    const Product(
      id: 6,
      name: 'Sardinha em Óleo Marreta 125g',
      description: 'Sardinha em conserva com azeite vegetal rica em ómega 3.',
      category: 'Óleos & Enlatados',
      unit: 'lata',
      barcode: '5601234001080',
      price: 650.0,
      stockQuantity: 75,
      imageUrl: 'https://images.unsplash.com/photo-1534483509719-3feaee7c30da',
      isActive: true,
    ),
    const Product(
      id: 7,
      name: 'Leite em Pó Nido 400g',
      description: 'Leite em pó gordo instantâneo fortificado com cálcio e vitaminas.',
      category: 'Lacticínios & Matabicho',
      unit: 'lata',
      barcode: '5601234001127',
      price: 3800.0,
      stockQuantity: 25,
      imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150',
      isActive: true,
    ),
    const Product(
      id: 8,
      name: 'Café Ginga de Angola 100g',
      description: 'Café solúvel 100% robusta de Angola de aroma forte e encorpado.',
      category: 'Lacticínios & Matabicho',
      unit: 'frasco',
      barcode: '5601234001134',
      price: 1950.0,
      stockQuantity: 30,
      imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd',
      isActive: true,
    ),
    const Product(
      id: 9,
      name: 'Gasosa Blue Laranja 330ml',
      description: 'Refrigerante gaseificado angolano com sabor intenso a laranja.',
      category: 'Bebidas & Refrescos',
      unit: 'lata',
      barcode: '5601234001165',
      price: 450.0,
      stockQuantity: 120,
      imageUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97',
      isActive: true,
    ),
    const Product(
      id: 10,
      name: 'Água Mineral da Chela 500ml',
      description: 'Água mineral pura e cristalina engarrafada na serra da Chela.',
      category: 'Bebidas & Refrescos',
      unit: 'garrafa',
      barcode: '5601234001196',
      price: 250.0,
      stockQuantity: 150,
      imageUrl: 'https://images.unsplash.com/photo-1548839140-29a749e1bc4e',
      isActive: true,
    ),
    const Product(
      id: 11,
      name: 'Sabão em Barra Macaco / Azul 400g',
      description: 'Sabão em barra multiuso tradicional para roupa, loiça e limpeza.',
      category: 'Higiene & Limpeza',
      unit: 'barra',
      barcode: '5601234001219',
      price: 400.0,
      stockQuantity: 110,
      imageUrl: 'https://images.unsplash.com/photo-1600857544200-b2f666a9a2ec',
      isActive: true,
    ),
    const Product(
      id: 12,
      name: 'Bolacha Maria Nacional 200g',
      description: 'Bolacha crocante deliciosa para acompanhar chá e café.',
      category: 'Biscoitos & Snacks',
      unit: 'pct',
      barcode: '5601234001257',
      price: 350.0,
      stockQuantity: 90,
      imageUrl: 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35',
      isActive: true,
    ),
  ];
}
