import 'package:flutter/material.dart';

import '../models/product.dart';

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

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
                      '\$${product.price.toStringAsFixed(2)}',
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
