import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/product_service.dart';
import '../utils/currency_formatter.dart';
import 'product_details_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Product>> _productsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _productsFuture = _productService.getAllProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _productService.close();
    super.dispose();
  }

  void _retry() =>
      setState(() => _productsFuture = _productService.getAllProducts());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: <Widget>[
          // Lab Activity 2 - Enhancement 1: Search filters products by title, brand, and category.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search products, brands, or categories',
              leading: const Icon(Icons.search_rounded),
              trailing: <Widget>[
                if (_query.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
              ],
              onChanged: (String value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<Product>> snapshot,
                  ) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _ErrorState(
                        error: snapshot.error,
                        onRetry: _retry,
                      );
                    }

                    final List<Product> allProducts =
                        snapshot.data ?? const <Product>[];
                    final List<Product> products = allProducts
                        .where(_matchesSearch)
                        .toList(growable: false);
                    if (products.isEmpty) {
                      return _EmptyState(hasSearch: _query.isNotEmpty);
                    }

                    return RefreshIndicator(
                      onRefresh: () async => _retry(),
                      child: GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 240,
                              mainAxisExtent: 300,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: products.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Product product = products[index];
                          return _ProductCard(
                            product: product,
                            // Lab Activity 2 - Enhancement 2: Tapping a card opens a complete details page.
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ChangeNotifierProvider<CartProvider>.value(
                                      value: context.read<CartProvider>(),
                                      child: ProductDetailsScreen(
                                        product: product,
                                      ),
                                    ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesSearch(Product product) {
    if (_query.isEmpty) return true;
    return product.title.toLowerCase().contains(_query) ||
        product.brand.toLowerCase().contains(_query) ||
        product.category.toLowerCase().contains(_query);
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Hero(
                tag: 'product-${product.id}',
                child: Container(
                  width: double.infinity,
                  color: colors.surfaceContainerHighest,
                  child: Image.network(
                    product.thumbnail,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
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
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          CurrencyFormatter.peso(product.price),
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: Colors.amber,
                      ),
                      Text(product.rating.toStringAsFixed(1)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

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
            const Icon(Icons.cloud_off_rounded, size: 52),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        hasSearch ? 'No products match your search.' : 'No products found.',
      ),
    );
  }
}
