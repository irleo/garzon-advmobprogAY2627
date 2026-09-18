import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/cart.dart';

class CartService {
  CartService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Lab Activity 4 - Enhancement 3: Select the first cart owned by the saved user.
  Future<Cart> getCartByUserId(int userId) async {
    if (userId <= 0) {
      throw const CartServiceException('A signed-in user is required.');
    }
    final Map<String, dynamic> data = await _send(
      () => _client.get(Uri.parse('$apiHost/carts/user/$userId?limit=1')),
    );
    final Object? carts = data['carts'];
    if (carts is! List<dynamic>) {
      throw const CartServiceException(
        'The server returned an invalid cart list.',
      );
    }
    if (carts.isEmpty) {
      // ID zero represents a local cart until the demo API simulates creation.
      return Cart(
        id: 0,
        products: const <CartProduct>[],
        total: 0,
        discountedTotal: 0,
        userId: userId,
        totalProducts: 0,
        totalQuantity: 0,
      );
    }
    final Object? first = carts.first;
    if (first is! Map<String, dynamic>) {
      throw const CartServiceException('The server returned an invalid cart.');
    }
    final Cart cart = Cart.fromJson(first);
    if (cart.userId != userId || cart.id <= 0) {
      throw const CartServiceException(
        'The cart does not belong to this user.',
      );
    }
    return cart;
  }

  // Lab Activity 3 - Enhancement 3: Load one cart by its cart ID.
  Future<Cart> getCartById(int cartId) async {
    if (cartId <= 0) {
      throw const CartServiceException(
        'The cart ID must be greater than zero.',
      );
    }

    final Map<String, dynamic> data = await _send(
      () => _client.get(
        Uri.parse('$apiHost/carts/$cartId'),
        headers: const <String, String>{'Accept': 'application/json'},
      ),
    );
    return Cart.fromJson(data);
  }

  // Lab Activity 3 - Enhancement 3: Pass product values to POST /carts/add.
  Future<Cart> addToCart({
    required int userId,
    required int productId,
    required int quantity,
  }) async {
    if (userId <= 0 || productId <= 0 || quantity <= 0) {
      throw const CartServiceException(
        'User, product, and quantity values must be greater than zero.',
      );
    }

    final Map<String, dynamic> data = await _send(
      () => _client.post(
        Uri.parse('$apiHost/carts/add'),
        headers: const <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'userId': userId,
          'products': <Map<String, int>>[
            <String, int>{'id': productId, 'quantity': quantity},
          ],
        }),
      ),
    );
    return Cart.fromJson(data);
  }

  Future<void> replaceCartProducts({
    required int cartId,
    required List<CartProduct> products,
  }) async {
    if (cartId <= 0) {
      throw const CartServiceException(
        'The cart ID must be greater than zero.',
      );
    }

    await _send(
      () => _client.patch(
        Uri.parse('$apiHost/carts/$cartId'),
        headers: const <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'merge': false,
          'products': products
              .map(
                (CartProduct product) => <String, int>{
                  'id': product.id,
                  'quantity': product.quantity,
                },
              )
              .toList(growable: false),
        }),
      ),
    );
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final http.Response response = await request().timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CartServiceException(
          'The cart server returned ${response.statusCode}.',
        );
      }

      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const CartServiceException(
          'The cart response has an invalid format.',
        );
      }
      return decoded;
    } on TimeoutException catch (error) {
      throw CartServiceException('The cart request timed out.', error);
    } on http.ClientException catch (error) {
      throw CartServiceException('Unable to reach the cart server.', error);
    } on FormatException catch (error) {
      throw CartServiceException('The server returned unreadable data.', error);
    }
  }

  void close() => _client.close();
}

class CartServiceException implements Exception {
  const CartServiceException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
