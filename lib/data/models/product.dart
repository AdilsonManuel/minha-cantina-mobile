class Product {
  final int id;
  final String name;
  final String description;
  final String category;
  final String unit;
  final String? barcode;
  final double price;
  final int stockQuantity;
  final String? imageUrl;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.unit = 'un',
    this.barcode,
    required this.price,
    required this.stockQuantity,
    this.imageUrl,
    required this.isActive,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      category: json['category'] as String,
      unit: (json['unit'] as String?) ?? 'un',
      barcode: json['barcode'] as String?,
      price: (json['price'] as num).toDouble(),
      stockQuantity: json['stockQuantity'] as int,
      imageUrl: json['imageUrl'] as String?,
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'unit': unit,
      'barcode': barcode,
      'price': price,
      'stockQuantity': stockQuantity,
      'imageUrl': imageUrl,
      'isActive': isActive,
    };
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;
}
