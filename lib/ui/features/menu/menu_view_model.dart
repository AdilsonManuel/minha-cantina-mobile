import 'package:flutter/material.dart';
import 'package:minha_cantina_app/data/models/product.dart';
import 'package:minha_cantina_app/data/models/order.dart';
import 'package:minha_cantina_app/data/services/api_service.dart';

class MenuViewModel extends ChangeNotifier {
  final ApiService apiService;

  MenuViewModel({required this.apiService});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Product> _products = [];
  List<Product> get products => _products;

  String _selectedCategory = 'Todos';
  String get selectedCategory => _selectedCategory;

  final Map<int, CartItem> _cart = {};
  List<CartItem> get cartItems => _cart.values.toList();

  int get cartCount => _cart.values.fold(0, (sum, item) => sum + item.quantity);
  double get cartTotal => _cart.values.fold(0.0, (sum, item) => sum + item.subtotal);

  List<String> get categories {
    final set = {'Todos', ..._products.map((p) => p.category)};
    return set.toList();
  }

  List<Product> get filteredProducts {
    if (_selectedCategory == 'Todos') return _products;
    return _products.where((p) => p.category == _selectedCategory).toList();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await apiService.fetchProducts();
    } catch (e) {
      _errorMessage = 'Falha ao carregar produtos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void addToCart(Product product) {
    if (_cart.containsKey(product.id)) {
      if (_cart[product.id]!.quantity < product.stockQuantity) {
        _cart[product.id]!.quantity++;
      }
    } else {
      if (product.stockQuantity > 0) {
        _cart[product.id] = CartItem(product: product, quantity: 1);
      }
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    if (!_cart.containsKey(productId)) return;
    if (_cart[productId]!.quantity > 1) {
      _cart[productId]!.quantity--;
    } else {
      _cart.remove(productId);
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Future<OrderModel?> checkoutReservation() async {
    if (_cart.isEmpty) return null;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = await apiService.createReservation(cartItems);
      _cart.clear();
      return order;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
