import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/signup_data.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../utils/auth_input_formatters.dart';
import 'home_screen.dart';
import 'signin_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({this.user, super.key});
  final User? user;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields =
      <String, TextEditingController>{
        for (final String key in <String>[
          'firstName',
          'lastName',
          'age',
          'contact',
          'username',
          'email',
          'password',
          'confirm',
        ])
          key: TextEditingController(),
      };
  bool _busy = false;
  final Set<String> _visiblePasswords = <String>{};
  String? _error;

  @override
  void initState() {
    super.initState();
    final User? user = widget.user;
    if (user != null) {
      _fields['firstName']!.text = user.firstName;
      _fields['lastName']!.text = user.lastName;
      _fields['age']!.text = user.age?.toString() ?? '';
      _fields['contact']!.text = user.contactNo;
      _fields['username']!.text = user.username;
      _fields['email']!.text = user.email;
    }
  }

  String _text(String key) => _fields[key]!.text;

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final User user = await context.read<UserService>().createAccount(
        SignUpData(
          firstName: _text('firstName'),
          lastName: _text('lastName'),
          age: int.parse(_text('age')),
          contactNo: _text('contact'),
          username: _text('username'),
          email: _text('email'),
          password: _text('password'),
        ),
        completingProfile: widget.user != null,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        widget.user == null ? SignInScreen.routeName : HomeScreen.routeName,
        (_) => false,
        arguments: widget.user == null
            ? AccountCreatedNotice(user.email)
            : user,
      );
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _field(
    String key,
    String label,
    String? Function(String?) validator, {
    TextInputType keyboard = TextInputType.text,
    bool secret = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: _fields[key],
      enabled: !_busy,
      readOnly: key == 'email' && widget.user != null,
      keyboardType: keyboard,
      inputFormatters: switch (key) {
        'firstName' || 'lastName' => AuthInputFormatters.name,
        'username' => AuthInputFormatters.username,
        'age' => AuthInputFormatters.age,
        'contact' => AuthInputFormatters.contact,
        'email' => AuthInputFormatters.email,
        _ => AuthInputFormatters.password,
      },
      obscureText: secret && !_visiblePasswords.contains(key),
      autocorrect: !secret && keyboard == TextInputType.text,
      enableSuggestions: !secret,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: secret ? const Icon(Icons.lock_outline_rounded) : null,
        suffixIcon: secret
            ? IconButton(
                tooltip: _visiblePasswords.contains(key)
                    ? 'Hide password'
                    : 'Show password',
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        if (!_visiblePasswords.add(key)) {
                          _visiblePasswords.remove(key);
                        }
                      }),
                icon: Icon(
                  _visiblePasswords.contains(key)
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              )
            : null,
      ),
      validator: validator,
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.user == null ? 'Create account' : 'Complete your profile',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              Text(
                widget.user == null
                    ? 'Sign up with Firebase using your email address.'
                    : 'Save your details using your current account password.',
              ),
              const SizedBox(height: 24),
              Form(
                key: _form,
                child: Column(
                  children: <Widget>[
                    _field('firstName', 'First name', AuthValidation.name),
                    _field('lastName', 'Last name', AuthValidation.name),
                    _field(
                      'age',
                      'Age',
                      AuthValidation.age,
                      keyboard: TextInputType.number,
                    ),
                    _field(
                      'contact',
                      'Contact number',
                      AuthValidation.contact,
                      keyboard: TextInputType.phone,
                    ),
                    _field('username', 'Username', AuthValidation.username),
                    _field(
                      'email',
                      'Email address',
                      AuthValidation.email,
                      keyboard: TextInputType.emailAddress,
                    ),
                    _field(
                      'password',
                      widget.user == null ? 'Password' : 'Current password',
                      widget.user == null
                          ? AuthValidation.password
                          : (String? value) => value == null || value.isEmpty
                                ? 'Enter your current password.'
                                : null,
                      secret: true,
                    ),
                    _field(
                      'confirm',
                      'Confirm password',
                      (String? value) => value != _text('password')
                          ? 'Passwords do not match.'
                          : null,
                      secret: true,
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(
                  _busy
                      ? 'Saving…'
                      : widget.user == null
                      ? 'Create account'
                      : 'Save profile',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
