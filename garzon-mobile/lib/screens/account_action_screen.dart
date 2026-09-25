import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/signup_data.dart';
import '../services/user_service.dart';
import '../utils/auth_input_formatters.dart';
import 'signin_screen.dart';

enum AccountAction { username, password, delete }

class AccountActionScreen extends StatefulWidget {
  const AccountActionScreen({
    required this.action,
    required this.username,
    super.key,
  });
  final AccountAction action;
  final String username;

  @override
  State<AccountActionScreen> createState() => _AccountActionScreenState();
}

class _AccountActionScreenState extends State<AccountActionScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _current = TextEditingController();
  final TextEditingController _value = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  String get _title => switch (widget.action) {
    AccountAction.username => 'Update username',
    AccountAction.password => 'Change password',
    AccountAction.delete => 'Delete account',
  };

  @override
  void initState() {
    super.initState();
    if (widget.action == AccountAction.username) _value.text = widget.username;
  }

  Future<void> _save() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final UserService service = context.read<UserService>();
      switch (widget.action) {
        case AccountAction.username:
          await service.updateUsername(_value.text);
        case AccountAction.password:
          await service.resetPasswordFromCurrentPassword(
            _current.text,
            _value.text,
          );
        case AccountAction.delete:
          await service.deleteAccount(_current.text);
      }
      if (!mounted) return;
      if (widget.action == AccountAction.delete) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(SignInScreen.routeName, (_) => false);
      } else {
        Navigator.of(context).pop(true);
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _value.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                if (widget.action == AccountAction.delete) ...<Widget>[
                  const Text(
                    'This permanently deletes your Firebase account and profile. '
                    'Enter your current password and type DELETE to confirm.',
                  ),
                  const SizedBox(height: 24),
                ],
                if (widget.action != AccountAction.username) ...<Widget>[
                  TextFormField(
                    controller: _current,
                    enabled: !_busy,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Current password',
                    ),
                    validator: (String? value) => value == null || value.isEmpty
                        ? 'Enter your current password.'
                        : null,
                  ),
                  const SizedBox(height: 20),
                ],
                if (widget.action != AccountAction.delete) ...<Widget>[
                  TextFormField(
                    controller: _value,
                    inputFormatters: widget.action == AccountAction.username
                        ? AuthInputFormatters.username
                        : AuthInputFormatters.password,
                    enabled: !_busy,
                    obscureText: widget.action == AccountAction.password,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: widget.action == AccountAction.username
                          ? 'Username'
                          : 'New password',
                    ),
                    validator: widget.action == AccountAction.username
                        ? AuthValidation.username
                        : AuthValidation.password,
                  ),
                  const SizedBox(height: 20),
                ],
                if (widget.action != AccountAction.username)
                  TextFormField(
                    controller: _confirm,
                    inputFormatters: widget.action == AccountAction.delete
                        ? AuthInputFormatters.deletion
                        : AuthInputFormatters.password,
                    enabled: !_busy,
                    obscureText: widget.action == AccountAction.password,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: widget.action == AccountAction.delete
                          ? 'Type DELETE'
                          : 'Confirm new password',
                    ),
                    validator: (String? value) =>
                        value !=
                            (widget.action == AccountAction.delete
                                ? 'DELETE'
                                : _value.text)
                        ? 'Confirmation does not match.'
                        : null,
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
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
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  style: widget.action == AccountAction.delete
                      ? FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onError,
                        )
                      : null,
                  child: Text(_busy ? 'Please wait…' : _title),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
