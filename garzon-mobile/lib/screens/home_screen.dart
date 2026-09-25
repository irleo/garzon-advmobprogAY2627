import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/cart_provider.dart';

import 'cart_screen.dart';
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
    const CartScreen(),
    ProfileScreen(user: widget.user),
  ];

  @override
  Widget build(BuildContext context) {
    final List<String> titles = <String>['Discover', 'Cart', 'Profile'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        actions: <Widget>[
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, SettingsScreen.routeName),
          ),
        ],
      ),
      body: HeroMode(
        enabled: _selectedIndex == 0,
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      // Lab Activity 3 - Enhancement 2: Chat is a FAB and is hidden on Cart.
      floatingActionButton: _selectedIndex == 1
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const _ChatScreen()),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Chat'),
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
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart_rounded),
            label: 'Cart',
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

class _ChatScreen extends StatelessWidget {
  const _ChatScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const <Widget>[
                _MessageBubble(
                  message: 'Hi! Is the item in my cart still available?',
                  sentByUser: true,
                ),
                _MessageBubble(
                  message: 'Yes, it is currently in stock and ready to order.',
                  sentByUser: false,
                ),
                _MessageBubble(
                  message: 'Great! How long does delivery usually take?',
                  sentByUser: true,
                ),
                _MessageBubble(
                  message:
                      'Standard delivery usually takes three to five days.',
                  sentByUser: false,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: TextField(
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  prefixIcon: const Icon(Icons.add_circle_outline_rounded),
                  suffixIcon: IconButton.filled(
                    tooltip: 'Send message',
                    onPressed: () {},
                    icon: const Icon(Icons.send_rounded),
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.sentByUser});

  final String message;
  final bool sentByUser;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Align(
      alignment: sentByUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: sentByUser
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(message),
      ),
    );
  }
}
