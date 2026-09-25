import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../widgets/logout_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // Enhancement 3: Theme controls live on a dedicated settings page.
          Card(
            child: SwitchListTile.adaptive(
              secondary: Icon(
                themeProvider.isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
              ),
              title: const Text('Dark mode'),
              subtitle: const Text(
                'Use a darker color theme throughout the app.',
              ),
              value: themeProvider.isDark,
              onChanged: (bool enabled) =>
                  themeProvider.setDarkMode(enabled: enabled),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(
        minimum: EdgeInsets.all(16),
        child: LogoutButton(),
      ),
    );
  }
}
