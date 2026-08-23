import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import 'product_details_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({this.userId = 5, super.key});

  final int userId;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final ProductService _productService = ProductService();
  late Future<Cart> _cartFuture;
  int? _busyProductId;

  @override
  void initState() {
    super.initState();
    _cartFuture = _cartService.getCartByUserId(widget.userId);
  }

  @override
  void dispose() {
    _cartService.close();
    _productService.close();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _cartFuture = _cartService.getCartByUserId(widget.userId);
    });
  }

  // Lab Activity 3 - Enhancement 1: A cart item opens the same product details screen.
  Future<void> _openProduct(CartProduct cartProduct) async {
    if (_busyProductId != null) return;
    setState(() => _busyProductId = cartProduct.id);

    try {
      final Product product = await _productService.getProductById(
        cartProduct.id,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProductDetailsScreen(product: product),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _busyProductId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Cart>(
      future: _cartFuture,
      builder: (BuildContext context, AsyncSnapshot<Cart> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _CartErrorState(error: snapshot.error, onRetry: _retry);
        }

        final Cart? cart = snapshot.data;
        if (cart == null || cart.products.isEmpty) {
          return const Center(child: Text('This user cart is empty.'));
        }

        return RefreshIndicator(
          onRefresh: () async => _retry(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: cart.products.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              if (index == cart.products.length) {
                return _CartSummary(cart: cart);
              }

              final CartProduct product = cart.products[index];
              return _CartProductCard(
                product: product,
                isBusy: _busyProductId == product.id,
                onTap: () => _openProduct(product),
              );
            },
          ),
        );
      },
    );
  }
}

class _CartProductCard extends StatelessWidget {
  const _CartProductCard({
    required this.product,
    required this.isBusy,
    required this.onTap,
  });

  final CartProduct product;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.surfaceContainerLow,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              SizedBox.square(
                dimension: 88,
                child: ColoredBox(
                  color: colors.surfaceContainerHighest,
                  child: Image.network(
                    product.thumbnail,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$${product.price.toStringAsFixed(2)} each',
                      style: TextStyle(color: colors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quantity: ${product.quantity}  •  '
                      '\$${product.discountedTotal.toStringAsFixed(2)} total',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isBusy)
                const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            _SummaryRow(label: 'Items', value: '${cart.totalQuantity}'),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Subtotal', value: '\$${cart.total.toStringAsFixed(2)}'),
            const Divider(height: 24),
            _SummaryRow(
              label: 'Discounted total',
              value: '\$${cart.discountedTotal.toStringAsFixed(2)}',
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = emphasized
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          )
        : null;
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}

class _CartErrorState extends StatelessWidget {
  const _CartErrorState({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.shopping_cart_checkout_rounded, size: 52),
            const SizedBox(height: 12),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
