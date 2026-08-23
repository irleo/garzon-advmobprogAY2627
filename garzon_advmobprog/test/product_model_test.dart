import 'package:flutter_test/flutter_test.dart';
import 'package:garzon_advmobprog/models/product.dart';

void main() {
  test('Product.fromJson safely parses required product fields', () {
    final Product product = Product.fromJson(<String, dynamic>{
      'id': 1,
      'title': 'Test product',
      'price': 12.5,
      'dimensions': <String, dynamic>{'width': 1, 'height': 2, 'depth': 3},
      'meta': <String, dynamic>{},
    });

    expect(product.id, 1);
    expect(product.title, 'Test product');
    expect(product.price, 12.5);
    expect(product.tags, isEmpty);
  });
}
