import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/cart_provider.dart';

import 'cart_screen.dart';
import 'chat_screen.dart';
import 'product_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.user, super.key});

  static const String routeName = '/home';
  final User user;

  @override
  Widget build(BuildContext context) {
    // Lab Activity 4 - Enhancement 3: Cart state belongs to this signed-in user.
    return ChangeNotifierProvider<CartProvider>(
      create: (_) => CartProvider(userId: user.id)..loadCart(),
      child: _HomeContent(user: user),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({required this.user});

  final User user;

  @override
  State<_HomeContent> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeContent> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = <Widget>[
    const ProductScreen(),
    ChatScreen(user: widget.user),
    ProfileScreen(user: widget.user),
  ];

  Future<void> _openSettings() async {
    try {
      await Navigator.pushNamed(context, SettingsScreen.routeName);
      if (!mounted) return;
      // Reload account details after edits made from Settings.
      setState(() {
        _pages[2] = ProfileScreen(key: UniqueKey(), user: widget.user);
      });
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open settings: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> titles = <String>['Discover', 'Chat', 'Profile'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        actions: <Widget>[
          IconButton(
            tooltip: 'Cart',
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              final CartProvider cart = context.read<CartProvider>();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChangeNotifierProvider<CartProvider>.value(
                    value: cart,
                    child: Scaffold(
                      appBar: AppBar(title: const Text('Cart')),
                      body: const CartScreen(),
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: HeroMode(
        enabled: _selectedIndex == 0,
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) =>
            setState(() => _selectedIndex = index),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
