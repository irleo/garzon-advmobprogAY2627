import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import 'signin_screen.dart';

// Lab Activity 4 - Enhancement 3: Render the authenticated, saved User model.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.user, super.key});

  final User user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSigningOut = false;

  Future<void> _logout() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await context.read<UserService>().logout();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(SignInScreen.routeName, (_) => false);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final User user = widget.user;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: <Widget>[
        Card(
          color: colors.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: <Widget>[
                ClipOval(
                  child: Image.network(
                    user.image,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.square(
                      dimension: 96,
                      child: Icon(Icons.person_rounded, size: 64),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  user.fullName.isEmpty ? user.username : user.fullName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '@${user.username}',
                  style: TextStyle(color: colors.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Account details',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: <Widget>[
              _ProfileDetail(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: user.email,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ProfileDetail(
                icon: Icons.person_outline_rounded,
                label: 'Gender',
                value: user.gender,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ProfileDetail(
                icon: Icons.badge_outlined,
                label: 'User ID',
                value: '#${user.id}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _isSigningOut ? null : _logout,
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
            minimumSize: const Size.fromHeight(52),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: Text(_isSigningOut ? 'Signing out…' : 'Log out'),
        ),
      ],
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(label),
    subtitle: SelectableText(value.isEmpty ? 'Not provided' : value),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
  );
}
