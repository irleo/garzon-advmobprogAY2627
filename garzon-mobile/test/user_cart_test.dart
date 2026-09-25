import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garzon_advmobprog/models/product.dart';
import 'package:garzon_advmobprog/providers/cart_provider.dart';
import 'package:garzon_advmobprog/screens/cart_screen.dart';
import 'package:garzon_advmobprog/services/cart_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

Map<String, dynamic> _cartData(int userId, {int count = 1}) =>
    <String, dynamic>{
      'id': 12,
      'userId': userId,
      'total': count * 10,
      'discountedTotal': count * 9,
      'totalProducts': count,
      'totalQuantity': count,
      'products': List<Map<String, dynamic>>.generate(
        count,
        (int index) => <String, dynamic>{
          'id': index + 1,
          'title': 'Item ${index + 1}',
          'price': 10,
          'quantity': 1,
          'total': 10,
          'discountedTotal': 9,
          'discountPercentage': 10,
          'thumbnail': '',
        },
      ),
    };

http.Response _cartResponse(int userId, {int count = 1}) => http.Response(
  jsonEncode(<String, Object>{
    'carts': <Map<String, dynamic>>[_cartData(userId, count: count)],
  }),
  200,
);

void main() {
  test(
    'cart requests use the authenticated user ID, not a fixed cart ID',
    () async {
      final CartProvider provider = CartProvider(
        userId: 7,
        cartService: CartService(
          client: MockClient((http.Request request) async {
            expect(request.url.path, '/carts/user/7');
            expect(request.url.queryParameters['limit'], '1');
            return _cartResponse(7);
          }),
        ),
      );
      addTearDown(provider.dispose);
      await provider.loadCart();
      expect(provider.cart?.userId, 7);
      expect(provider.cart?.id, 12);
    },
  );

  test('a cart belonging to another account is rejected', () async {
    final CartProvider provider = CartProvider(
      userId: 7,
      cartService: CartService(
        client: MockClient((_) async => _cartResponse(8)),
      ),
    );
    addTearDown(provider.dispose);
    await provider.loadCart();
    expect(provider.cart, isNull);
    expect(provider.error, isA<CartServiceException>());
  });

  test('a user without a cart can add and edit a local demo cart', () async {
    final List<String> paths = <String>[];
    final CartProvider provider = CartProvider(
      userId: 7,
      cartService: CartService(
        client: MockClient((http.Request request) async {
          paths.add(request.url.path);
          if (request.method == 'GET') {
            return http.Response('{"carts":[]}', 200);
          }
          expect(
            (jsonDecode(request.body) as Map<String, dynamic>)['userId'],
            7,
          );
          return http.Response(jsonEncode(_cartData(7)), 201);
        }),
      ),
    );
    addTearDown(provider.dispose);
    await provider.loadCart();
    expect(provider.cart?.products, isEmpty);
    await provider.addProduct(
      Product.fromJson(<String, dynamic>{
        'id': 1,
        'title': 'Item 1',
        'price': 10,
      }),
    );
    await provider.increaseQuantity(provider.cart!.products.first);
    expect(provider.cart?.totalQuantity, 2);
    expect(paths, <String>['/carts/user/7', '/carts/add']);
  });

  test('existing cart updates use the returned cart ID', () async {
    final CartProvider provider = CartProvider(
      userId: 7,
      cartService: CartService(
        client: MockClient((http.Request request) async {
          if (request.method == 'GET') return _cartResponse(7);
          expect(request.method, 'PATCH');
          expect(request.url.path, '/carts/12');
          return http.Response('{}', 200);
        }),
      ),
    );
    addTearDown(provider.dispose);
    await provider.loadCart();
    await provider.increaseQuantity(provider.cart!.products.first);
    expect(provider.cart?.totalQuantity, 2);
    expect(provider.cart?.discountedTotal, 18);
  });

  test('logout disposal safely ignores an in-flight response', () async {
    final Completer<http.Response> pending = Completer<http.Response>();
    final CartProvider provider = CartProvider(
      userId: 7,
      cartService: CartService(client: MockClient((_) => pending.future)),
    );
    final Future<void> loading = provider.loadCart();
    provider.dispose();
    pending.complete(_cartResponse(7));
    await loading;
    expect(provider.cart, isNull);
  });

  testWidgets('checkout remains pinned while cart products scroll', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final CartProvider provider = CartProvider(
      userId: 7,
      cartService: CartService(
        client: MockClient((_) async => _cartResponse(7, count: 15)),
      ),
    );
    addTearDown(provider.dispose);
    await provider.loadCart();
    await tester.pumpWidget(
      ChangeNotifierProvider<CartProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Cart')),
            body: const CartScreen(),
            bottomNavigationBar: const SizedBox(height: 80),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final Offset before = tester.getCenter(find.text('Checkout'));
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.text('Checkout')), before);
    expect(find.text('Checkout').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
