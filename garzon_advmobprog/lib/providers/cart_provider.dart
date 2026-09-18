import 'package:flutter/foundation.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  CartProvider({required this.userId, CartService? cartService})
    : _cartService = cartService ?? CartService();

  final int userId;

  final CartService _cartService;
  final Set<int> _updatingProductIds = <int>{};
  Cart? _cart;
  bool _isLoading = false;
  Object? _error;
  bool _isDisposed = false;

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  Object? get error => _error;
  bool isUpdating(int productId) =>
      _updatingProductIds.isNotEmpty || _isLoading;

  Future<void> loadCart() async {
    if (_isDisposed || _isLoading || _updatingProductIds.isNotEmpty) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Cart cart = await _cartService.getCartByUserId(userId);
      if (!_isDisposed) _cart = cart;
    } on Object catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> increaseQuantity(CartProduct product) {
    return _setQuantity(product, product.quantity + 1);
  }

  Future<void> decreaseQuantity(CartProduct product) {
    if (product.quantity <= 1) {
      throw const CartServiceException(
        'Confirm removal before reducing the quantity to zero.',
      );
    }
    return _setQuantity(product, product.quantity - 1);
  }

  Future<void> removeProduct(CartProduct product) async {
    final Cart currentCart = _requireCart();
    final List<CartProduct> products = currentCart.products
        .where((CartProduct item) => item.id != product.id)
        .toList(growable: false);
    await _saveProducts(product.id, products);
  }

  Future<void> addProduct(Product product) async {
    if (_cart == null) await loadCart();
    final Cart currentCart = _requireCart();
    if (_updatingProductIds.isNotEmpty || _isLoading) {
      throw const CartServiceException(
        'Please wait for the current cart update.',
      );
    }
    _setUpdating(product.id, true);

    try {
      final Cart response = await _cartService.addToCart(
        userId: currentCart.userId,
        productId: product.id,
        quantity: 1,
      );
      final CartProduct addedProduct = response.products.firstWhere(
        (CartProduct item) => item.id == product.id,
        orElse: () => CartProduct(
          id: product.id,
          title: product.title,
          price: product.price,
          quantity: 1,
          total: product.price,
          discountPercentage: product.discountPercentage,
          discountedTotal:
              product.price * (1 - (product.discountPercentage / 100)),
          thumbnail: product.thumbnail,
        ),
      );

      final List<CartProduct> products = <CartProduct>[];
      bool found = false;
      for (final CartProduct item in currentCart.products) {
        if (item.id == product.id) {
          products.add(item.copyWith(quantity: item.quantity + 1));
          found = true;
        } else {
          products.add(item);
        }
      }
      if (!found) products.add(addedProduct);
      if (!_isDisposed) _cart = _recalculate(currentCart, products);
    } finally {
      _setUpdating(product.id, false);
    }
  }

  Future<void> _setQuantity(CartProduct product, int quantity) async {
    final Cart currentCart = _requireCart();
    final List<CartProduct> products = currentCart.products
        .map(
          (CartProduct item) =>
              item.id == product.id ? item.copyWith(quantity: quantity) : item,
        )
        .toList(growable: false);
    await _saveProducts(product.id, products);
  }

  Future<void> _saveProducts(int productId, List<CartProduct> products) async {
    final Cart currentCart = _requireCart();
    if (_updatingProductIds.isNotEmpty || _isLoading) {
      throw const CartServiceException(
        'Please wait for the current cart update.',
      );
    }
    _setUpdating(productId, true);

    try {
      // DummyJSON does not persist new carts, so their subsequent edits stay local.
      if (currentCart.id != 0) {
        await _cartService.replaceCartProducts(
          cartId: currentCart.id,
          products: products,
        );
      }
      if (!_isDisposed) _cart = _recalculate(currentCart, products);
    } finally {
      _setUpdating(productId, false);
    }
  }

  Cart _requireCart() {
    final Cart? currentCart = _cart;
    if (_isDisposed || currentCart == null) {
      throw const CartServiceException('The cart has not loaded yet.');
    }
    return currentCart;
  }

  Cart _recalculate(Cart cart, List<CartProduct> products) {
    return Cart(
      id: cart.id,
      products: List<CartProduct>.unmodifiable(products),
      total: products.fold<double>(
        0,
        (double sum, CartProduct item) => sum + item.total,
      ),
      discountedTotal: products.fold<double>(
        0,
        (double sum, CartProduct item) => sum + item.discountedTotal,
      ),
      userId: cart.userId,
      totalProducts: products.length,
      totalQuantity: products.fold<int>(
        0,
        (int sum, CartProduct item) => sum + item.quantity,
      ),
    );
  }

  void _setUpdating(int productId, bool isUpdating) {
    if (_isDisposed) return;
    if (isUpdating) {
      _updatingProductIds.add(productId);
    } else {
      _updatingProductIds.remove(productId);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cartService.close();
    super.dispose();
  }
}
