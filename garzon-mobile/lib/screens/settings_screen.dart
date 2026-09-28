import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/theme_provider.dart';
import '../services/user_service.dart';
import '../widgets/logout_button.dart';
import 'account_action_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const String routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Preview preferences stay local until notification services are connected.
  bool _pushNotifications = true;
  bool _emailOffers = false;
  bool _openingAccount = false;

  Future<void> _showInfo(String title, String message) async {
    try {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'settings',
        ),
      );
    }
  }

  Future<void> _openAccount({AccountAction? action}) async {
    if (_openingAccount) return;
    setState(() => _openingAccount = true);
    try {
      final User? user = await context.read<UserService>().getUserData();
      if (!mounted) return;
      if (user == null) {
        await _showInfo(
          'Session expired',
          'Sign in again to manage your account.',
        );
      } else if (action == null) {
        await _showInfo(
          'Linked NU email',
          'Account email: ${user.email}\n\nNU email linking is coming soon.',
        );
      } else if (user.loginType != LoginType.firebase) {
        await _showInfo(
          'Demo account',
          'Sign in with Firebase to manage or delete your account.',
        );
      } else {
        final bool? changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) =>
                AccountActionScreen(action: action, username: user.username),
          ),
        );
        if (mounted && changed == true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Account updated.')));
        }
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open account settings: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _openingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider preferences = context.watch<ThemeProvider>();
    final Color muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('NU Exchange')),
      body: SafeArea(
        top: false,
        child: ListView(
          children: <Widget>[
            _SectionHeading('Preferences', color: muted),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 28),
              title: const Text('Dark mode'),
              value: preferences.isDark,
              onChanged: (bool enabled) =>
                  preferences.setDarkMode(enabled: enabled),
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 28),
              title: const Text('Push notifications'),
              value: _pushNotifications,
              onChanged: (bool enabled) =>
                  setState(() => _pushNotifications = enabled),
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 28),
              title: const Text('Email offers'),
              value: _emailOffers,
              onChanged: (bool enabled) =>
                  setState(() => _emailOffers = enabled),
            ),
            const Divider(),
            _SectionHeading('Account', color: muted),
            if (_openingAccount) const LinearProgressIndicator(minHeight: 2),
            _SettingsRow(
              'Edit profile',
              onTap: _openingAccount
                  ? null
                  : () => _openAccount(action: AccountAction.username),
            ),
            const Divider(),
            _SettingsRow(
              'Change password',
              onTap: _openingAccount
                  ? null
                  : () => _openAccount(action: AccountAction.password),
            ),
            const Divider(),
            _SettingsRow(
              'Linked NU email',
              onTap: _openingAccount ? null : () => _openAccount(),
            ),
            const Divider(),
            _SettingsRow(
              'Delete account',
              destructive: true,
              onTap: _openingAccount
                  ? null
                  : () => _openAccount(action: AccountAction.delete),
            ),
            const Divider(),
            _SectionHeading('Support', color: muted),
            _SettingsRow(
              'Help center',
              onTap: () => _showInfo(
                'Help center',
                'Browse items in Shop, manage your Cart, and connect with other members in Chat. '
                    'You can update your username and password under Account.\n\n'
                    'Push notifications and email offers are preview preferences for now.',
              ),
            ),
            const Divider(),
            _SettingsRow(
              'About NU Exchange',
              onTap: () => _showInfo(
                'About NU Exchange',
                'A place for the NU community to discover items and connect.\n\n'
                    'Built for Advanced Mobile Programming.',
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
              child: const LogoutButton(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: Text(
                'NU Exchange · Made for campus life',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title, {required this.color});
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 18, 28, 12),
    child: Text(
      title,
      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow(
    this.title, {
    required this.onTap,
    this.destructive = false,
  });
  final String title;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 28),
    minTileHeight: 56,
    textColor: destructive ? Theme.of(context).colorScheme.error : null,
    iconColor: destructive ? Theme.of(context).colorScheme.error : null,
    title: Text(title),
    trailing: const Icon(Icons.chevron_right_rounded, size: 22),
    onTap: onTap,
    enabled: onTap != null,
  );
}
