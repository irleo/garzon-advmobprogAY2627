import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/product.dart';

class ProductService {
  ProductService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Product> getProductById(int productId) async {
    if (productId <= 0) {
      throw const ProductServiceException(
        'The product ID must be greater than zero.',
      );
    }

    final Uri endpoint = Uri.parse('$apiHost/products/$productId');

    try {
      final http.Response response = await _client
          .get(
            endpoint,
            headers: const <String, String>{'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ProductServiceException(
          'The product server returned ${response.statusCode}.',
        );
      }

      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ProductServiceException(
          'The product response has an invalid format.',
        );
      }
      return Product.fromJson(decoded);
    } on TimeoutException catch (error) {
      throw ProductServiceException(
        'The request timed out. Please try again.',
        error,
      );
    } on http.ClientException catch (error) {
      throw ProductServiceException(
        'Unable to reach the product server.',
        error,
      );
    } on FormatException catch (error) {
      throw ProductServiceException(
        'The server returned unreadable data.',
        error,
      );
    }
  }

  Future<List<Product>> getAllProducts() async {
    // Load the bounded full catalog page so every cart item is searchable.
    final Uri endpoint = Uri.parse('$apiHost/products?limit=70&skip=110');

    try {
      final http.Response response = await _client
          .get(
            endpoint,
            headers: const <String, String>{'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ProductServiceException(
          'The product server returned ${response.statusCode}.',
        );
      }

      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ProductServiceException(
          'The product response has an invalid format.',
        );
      }

      final Object? rawProducts = decoded['products'];
      if (rawProducts is! List<dynamic>) {
        throw const ProductServiceException(
          'The response does not contain products.',
        );
      }

      return rawProducts
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList(growable: false);
    } on TimeoutException catch (error) {
      throw ProductServiceException(
        'The request timed out. Please try again.',
        error,
      );
    } on http.ClientException catch (error) {
      throw ProductServiceException(
        'Unable to reach the product server.',
        error,
      );
    } on FormatException catch (error) {
      throw ProductServiceException(
        'The server returned unreadable data.',
        error,
      );
    }
  }

  void close() => _client.close();
}

class ProductServiceException implements Exception {
  const ProductServiceException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
