import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/signin_screen.dart';
import '../services/user_service.dart';

class LogoutButton extends StatefulWidget {
  const LogoutButton({super.key});

  @override
  State<LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<LogoutButton> {
  bool _busy = false;

  Future<void> _logout() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context.read<UserService>().signOut();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(SignInScreen.routeName, (_) => false);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: _busy ? null : _logout,
    icon: const Icon(Icons.logout_rounded),
    label: Text(_busy ? 'Signing out…' : 'Log out'),
  );
}
