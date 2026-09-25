import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/product_service.dart';
import '../utils/currency_formatter.dart';
import 'product_details_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ProductService _productService = ProductService();
  int? _busyProductId;

  @override
  void dispose() {
    _productService.close();
    super.dispose();
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
          builder: (_) =>
              ProductDetailsScreen(product: product, showAddToCart: false),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busyProductId = null);
    }
  }

  Future<void> _increase(CartProduct product) async {
    try {
      await context.read<CartProvider>().increaseQuantity(product);
    } on Object catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _decrease(CartProduct product) async {
    if (product.quantity == 1) {
      final bool shouldRemove =
          await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: const Text('Remove item?'),
              content: Text(
                'Reducing ${product.title} to zero will remove it from the cart.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ) ??
          false;
      if (!shouldRemove || !mounted) return;
    }

    try {
      final CartProvider provider = context.read<CartProvider>();
      if (product.quantity == 1) {
        await provider.removeProduct(product);
      } else {
        await provider.decreaseQuantity(product);
      }
    } on Object catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }

  Future<void> _checkout(Cart cart) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Confirm checkout'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Please confirm your order total:'),
                const SizedBox(height: 12),
                Text(
                  CurrencyFormatter.peso(cart.discountedTotal),
                  style: Theme.of(dialogContext).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Checkout confirmed.')));
  }

  @override
  Widget build(BuildContext context) {
    final CartProvider provider = context.watch<CartProvider>();
    final Cart? cart = provider.cart;

    if (provider.isLoading && cart == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && cart == null) {
      return _CartErrorState(error: provider.error, onRetry: provider.loadCart);
    }
    if (cart == null || cart.products.isEmpty) {
      return const Center(child: Text('Your cart is empty.'));
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: RefreshIndicator(
            onRefresh: provider.loadCart,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: cart.products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final CartProduct product = cart.products[index];
                return _CartProductCard(
                  product: product,
                  isBusy:
                      _busyProductId == product.id ||
                      provider.isUpdating(product.id),
                  onTap: () => _openProduct(product),
                  onIncrease: () => _increase(product),
                  onDecrease: () => _decrease(product),
                );
              },
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _CartSummary(cart: cart, onCheckout: () => _checkout(cart)),
          ),
        ),
      ],
    );
  }
}

class _CartProductCard extends StatelessWidget {
  const _CartProductCard({
    required this.product,
    required this.isBusy,
    required this.onTap,
    required this.onIncrease,
    required this.onDecrease,
  });

  final CartProduct product;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

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
                      '${CurrencyFormatter.peso(product.price)} each',
                      style: TextStyle(color: colors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quantity: ${product.quantity}  •  '
                      '${CurrencyFormatter.peso(product.discountedTotal)} total',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: <Widget>[
                  IconButton.filled(
                    tooltip: 'Increase quantity',
                    onPressed: isBusy ? null : onIncrease,
                    icon: const Icon(Icons.add_rounded),
                  ),
                  if (isBusy)
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      '${product.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  IconButton.outlined(
                    tooltip: 'Decrease quantity',
                    onPressed: isBusy ? null : onDecrease,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.cart, required this.onCheckout});

  final Cart cart;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _SummaryRow(label: 'Items', value: '${cart.totalQuantity}'),
            const SizedBox(height: 8),

            _SummaryRow(
              label: 'Subtotal',
              value: CurrencyFormatter.peso(cart.total),
            ),
            _SummaryRow(
              label: 'Discount',
              value: CurrencyFormatter.peso(cart.discount),
            ),
            const Divider(height: 24),
            _SummaryRow(
              label: 'Discounted total',
              value: CurrencyFormatter.peso(cart.discountedTotal),
              emphasized: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCheckout,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Checkout'),
              ),
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
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
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
