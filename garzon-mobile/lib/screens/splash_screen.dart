import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import 'home_screen.dart';
import 'signin_screen.dart';
import '../widgets/logout_button.dart';

// Lab Activity 4 - Enhancement 1: NU splash UI with persistent session routing.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = '/';
  static const Duration minimumDisplayDuration = Duration(seconds: 2);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    setState(() => _error = null);
    try {
      // Check the session during the splash delay instead of adding the delay
      // after a potentially slow authentication request.
      final List<User?> results = await Future.wait<User?>(<Future<User?>>[
        context.read<UserService>().restoreSession(),
        Future<User?>.delayed(SplashScreen.minimumDisplayDuration, () => null),
      ]);
      final User? user = results.first;
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        user == null ? SignInScreen.routeName : HomeScreen.routeName,
        arguments: user,
      );
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Image.asset(
                  'assets/images/nuicon.png',
                  width: 128,
                  height: 128,
                ),
                const SizedBox(height: 24),
                Text(
                  'NU Exchange',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your campus. Your finds.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 36),
                if (_error == null) ...<Widget>[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Checking your saved sign-in…'),
                ] else ...<Widget>[
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _checkAuthentication,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                  const SizedBox(height: 12),
                  const LogoutButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
