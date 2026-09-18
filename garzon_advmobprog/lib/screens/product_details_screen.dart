import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../utils/currency_formatter.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    required this.product,
    this.showAddToCart = true,
    super.key,
  });

  final Product product;
  final bool showAddToCart;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _isAddingToCart = false;

  // Lab Activity 3 - Enhancement 3: Send this product's values to /carts/add.
  Future<void> _addToCart() async {
    if (_isAddingToCart) return;
    setState(() => _isAddingToCart = true);

    try {
      await context.read<CartProvider>().addProduct(widget.product);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product.title} was sent to the cart.'),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Product product = widget.product;

    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          Hero(
            tag: 'product-${product.id}',
            child: AspectRatio(
              aspectRatio: 1.25,
              child: ColoredBox(
                color: colors.surfaceContainerHighest,
                child: Image.network(
                  product.images.isNotEmpty
                      ? product.images.first
                      : product.thumbnail,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  product.category.toUpperCase(),
                  style: TextStyle(color: colors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  product.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Text(
                      CurrencyFormatter.peso(product.price),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const Spacer(),
                    const Icon(Icons.star_rounded, color: Colors.amber),
                    Text(
                      '${product.rating.toStringAsFixed(1)} (${product.reviews.length})',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  product.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (widget.showAddToCart) ...<Widget>[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isAddingToCart ? null : _addToCart,
                      icon: _isAddingToCart
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_shopping_cart_rounded),
                      label: Text(
                        _isAddingToCart ? 'Adding...' : 'Add to cart',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _InfoChip(
                      icon: Icons.inventory_2_outlined,
                      label: '${product.stock} in stock',
                    ),
                    _InfoChip(
                      icon: Icons.local_shipping_outlined,
                      label: product.shippingInformation,
                    ),
                    _InfoChip(
                      icon: Icons.verified_user_outlined,
                      label: product.warrantyInformation,
                    ),
                  ],
                ),
                if (product.reviews.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 28),
                  Text(
                    'Latest reviews',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ...product.reviews
                      .take(3)
                      .map(
                        (ProductReview review) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text('${review.rating}★'),
                          ),
                          title: Text(review.reviewerName),
                          subtitle: Text(review.comment),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}
