import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../models/signup_data.dart';
import '../services/user_service.dart';
import '../utils/auth_input_formatters.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

// Lab Activity 4 - Enhancement 2: Custom sign-in UI using UserService.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  static const String routeName = '/signin';

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isLoading = false;
  bool _hidePassword = true;
  String? _error;
  LoginType _loginType = LoginType.dummyJson;

  Future<void> _login() async {
    if (_isLoading || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final User user = await context.read<UserService>().signIn(
        _username.text,
        _password.text,
        loginType: _loginType,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        HomeScreen.routeName,
        (_) => false,
        arguments: user,
      );
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Image.asset(
                        'assets/images/nuicon.png',
                        width: 88,
                        height: 88,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome back',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your NU Exchange account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),
                    SegmentedButton<LoginType>(
                      segments: const <ButtonSegment<LoginType>>[
                        ButtonSegment(
                          value: LoginType.dummyJson,
                          label: Text('DummyJSON'),
                        ),
                        ButtonSegment(
                          value: LoginType.firebase,
                          label: Text('Firebase'),
                        ),
                      ],
                      selected: <LoginType>{_loginType},
                      onSelectionChanged: _isLoading
                          ? null
                          : (Set<LoginType> selection) {
                              setState(() {
                                _loginType = selection.single;
                                _error = null;
                                _username.clear();
                                _password.clear();
                                _formKey.currentState?.reset();
                              });
                            },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _username,
                      inputFormatters: _loginType == LoginType.firebase
                          ? AuthInputFormatters.email
                          : AuthInputFormatters.username,
                      enabled: !_isLoading,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      keyboardType: _loginType == LoginType.firebase
                          ? TextInputType.emailAddress
                          : TextInputType.text,
                      decoration: InputDecoration(
                        labelText: _loginType == LoginType.firebase
                            ? 'Email address'
                            : 'Username',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                      validator: (String? value) =>
                          _loginType == LoginType.firebase
                          ? AuthValidation.email(value)
                          : value == null || value.trim().isEmpty
                          ? 'Enter your username.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      enabled: !_isLoading,
                      obscureText: _hidePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _hidePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (String? value) =>
                          value == null || value.isEmpty
                          ? 'Enter your password.'
                          : null,
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: TextStyle(color: colors.error),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isLoading ? null : _login,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: _isLoading
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign in'),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => const SignUpScreen(),
                              ),
                            ),
                      child: const Text('Create a Firebase account'),
                    ),
                    Text(
                      'NU EXCHANGE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
