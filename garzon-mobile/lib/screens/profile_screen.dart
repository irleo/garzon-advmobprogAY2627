import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import 'signin_screen.dart';
import 'signup_screen.dart';
import 'account_action_screen.dart';

// Lab Activity 4 - Enhancement 3: Render the authenticated, saved User model.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.user, super.key});

  final User user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _user = widget.user;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final User? user = await context.read<UserService>().getUserData();
      if (!mounted) return;
      if (user == null) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(SignInScreen.routeName, (_) => false);
      } else {
        setState(() => _user = user);
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _manage(AccountAction action) async {
    try {
      final bool? changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) =>
              AccountActionScreen(action: action, username: _user.username),
        ),
      );
      if (!mounted || changed != true) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account updated.')));
      await _refresh();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final User user = _user;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: <Widget>[
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) ...<Widget>[
          Text(_error!, style: TextStyle(color: colors.error)),
          TextButton(
            onPressed: _loading ? null : _refresh,
            child: const Text('Retry profile'),
          ),
        ],
        Card(
          color: colors.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: <Widget>[
                ClipOval(
                  child: user.image.isEmpty
                      ? const SizedBox.square(
                          dimension: 96,
                          child: Icon(Icons.person_rounded, size: 64),
                        )
                      : Image.network(
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
                icon: Icons.login_rounded,
                label: 'Login type',
                value: user.loginType == LoginType.firebase
                    ? 'Firebase'
                    : 'DummyJSON',
              ),
              _ProfileDetail(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: user.email,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              if (user.loginType == LoginType.dummyJson)
                _ProfileDetail(
                  icon: Icons.person_outline_rounded,
                  label: 'Gender',
                  value: user.gender,
                ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ProfileDetail(
                icon: Icons.badge_outlined,
                label: 'User ID',
                value: user.accountId,
              ),
              if (user.loginType == LoginType.firebase) ...<Widget>[
                _ProfileDetail(
                  icon: Icons.cake_outlined,
                  label: 'Age',
                  value: user.age?.toString() ?? '',
                ),
                _ProfileDetail(
                  icon: Icons.phone_outlined,
                  label: 'Contact number',
                  value: user.contactNo,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 28),
        if (user.loginType == LoginType.firebase) ...<Widget>[
          if (!user.profileComplete)
            FilledButton.tonal(
              onPressed: _loading
                  ? null
                  : () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => SignUpScreen(user: user),
                      ),
                    ),
              child: const Text('Complete your profile'),
            ),
          if (user.profileComplete)
            OutlinedButton(
              onPressed: _loading
                  ? null
                  : () => _manage(AccountAction.username),
              child: const Text('Update username'),
            ),
          OutlinedButton(
            onPressed: _loading ? null : () => _manage(AccountAction.password),
            child: const Text('Change password'),
          ),
          TextButton(
            onPressed: _loading ? null : () => _manage(AccountAction.delete),
            child: const Text('Delete account'),
          ),
          const SizedBox(height: 20),
        ] else
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'DummyJSON accounts are demo accounts. Create a Firebase account '
              'to manage your username, password, and account deletion.',
            ),
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
