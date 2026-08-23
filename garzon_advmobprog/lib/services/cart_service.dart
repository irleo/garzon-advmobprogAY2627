import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/cart.dart';

class CartService {
  CartService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Lab Activity 3 - Enhancement 3: Load only the cart owned by one user ID.
  Future<Cart> getCartByUserId(int userId) async {
    if (userId <= 0) {
      throw const CartServiceException('The user ID must be greater than zero.');
    }

    final Map<String, dynamic> data = await _send(
      () => _client.get(
        Uri.parse('$apiHost/carts/user/$userId'),
        headers: const <String, String>{'Accept': 'application/json'},
      ),
    );
    final Object? rawCarts = data['carts'];
    if (rawCarts is! List<dynamic> || rawCarts.isEmpty) {
      throw CartServiceException('No cart was found for user $userId.');
    }

    final Object? firstCart = rawCarts.first;
    if (firstCart is! Map<String, dynamic>) {
      throw const CartServiceException('The cart response has an invalid format.');
    }
    return Cart.fromJson(firstCart);
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
