class Cart {
  const Cart({
    required this.id,
    required this.products,
    required this.total,
    required this.discountedTotal,
    required this.userId,
    required this.totalProducts,
    required this.totalQuantity,
  });

  final int id;
  final List<CartProduct> products;
  final double total;
  final double discountedTotal;
  final int userId;
  final int totalProducts;
  final int totalQuantity;

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: _asInt(json['id']),
      products: _asList(json['products'])
          .whereType<Map<String, dynamic>>()
          .map(CartProduct.fromJson)
          .toList(growable: false),
      total: _asDouble(json['total']),
      discountedTotal: _asDouble(json['discountedTotal']),
      userId: _asInt(json['userId']),
      totalProducts: _asInt(json['totalProducts']),
      totalQuantity: _asInt(json['totalQuantity']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'products': products.map((CartProduct product) => product.toJson()).toList(),
    'total': total,
    'discountedTotal': discountedTotal,
    'userId': userId,
    'totalProducts': totalProducts,
    'totalQuantity': totalQuantity,
  };
}

class CartProduct {
  const CartProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
    required this.total,
    required this.discountPercentage,
    required this.discountedTotal,
    required this.thumbnail,
  });

  final int id;
  final String title;
  final double price;
  final int quantity;
  final double total;
  final double discountPercentage;
  final double discountedTotal;
  final String thumbnail;

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    return CartProduct(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      price: _asDouble(json['price']),
      quantity: _asInt(json['quantity']),
      total: _asDouble(json['total']),
      discountPercentage: _asDouble(json['discountPercentage']),
      discountedTotal: _asDouble(
        json['discountedTotal'] ?? json['discountedPrice'],
      ),
      thumbnail: _asString(json['thumbnail']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'price': price,
    'quantity': quantity,
    'total': total,
    'discountPercentage': discountPercentage,
    'discountedTotal': discountedTotal,
    'thumbnail': thumbnail,
  };
}

String _asString(Object? value) => value?.toString() ?? '';

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

List<dynamic> _asList(Object? value) =>
    value is List<dynamic> ? value : const <dynamic>[];
