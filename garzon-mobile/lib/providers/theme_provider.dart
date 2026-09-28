import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeData get lightTheme => _theme(Brightness.light);
  ThemeData get darkTheme => _theme(Brightness.dark);

  // One palette for every route, including dialogs and account forms.
  ThemeData _theme(Brightness brightness) {
    final bool dark = brightness == Brightness.dark;
    final Color background = dark
        ? const Color(0xFF24211D)
        : const Color(0xFFF1EDDF);
    final Color foreground = dark
        ? const Color(0xFFF1EDDF)
        : const Color(0xFF2C261E);
    final Color muted = dark
        ? const Color(0xFFBDB5A7)
        : const Color(0xFF655D50);
    final Color accent = dark
        ? const Color(0xFFE7A0B0)
        : const Color(0xFF80132A);
    final Color container = dark
        ? const Color(0xFF5B2935)
        : const Color(0xFFF0DCE0);
    final Color surface = dark
        ? const Color(0xFF302C26)
        : const Color(0xFFF8F4E9);
    final Color elevated = dark
        ? const Color(0xFF403A31)
        : const Color(0xFFE6DEC7);
    final Color divider = dark
        ? const Color(0xFF514B40)
        : const Color(0xFFD6D0C2);
    final ColorScheme colors =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF80132A),
          brightness: brightness,
        ).copyWith(
          primary: accent,
          onPrimary: dark ? background : Colors.white,
          primaryContainer: container,
          onPrimaryContainer: dark
              ? const Color(0xFFFFD9E1)
              : const Color(0xFF571021),
          secondary: accent,
          onSecondary: dark ? background : Colors.white,
          secondaryContainer: elevated,
          onSecondaryContainer: foreground,
          tertiary: dark ? const Color(0xFFD5BF8D) : const Color(0xFF715D30),
          tertiaryContainer: elevated,
          onTertiaryContainer: foreground,
          surface: background,
          onSurface: foreground,
          onSurfaceVariant: muted,
          surfaceContainerLowest: background,
          surfaceContainerLow: surface,
          surfaceContainer: surface,
          surfaceContainerHigh: elevated,
          surfaceContainerHighest: elevated,
          surfaceTint: Colors.transparent,
          outline: muted,
          outlineVariant: divider,
        );
    final ThemeData base = ThemeData(useMaterial3: true, colorScheme: colors);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: base.textTheme.apply(
        bodyColor: foreground,
        displayColor: foreground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: foreground,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: surface,
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: container,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: colors.onPrimary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected) && dark
              ? background
              : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected) ? accent : elevated,
        ),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
        thumbIcon: const WidgetStatePropertyAll<Icon>(
          Icon(Icons.circle, color: Colors.transparent),
        ),
      ),
    );
  }

  void setDarkMode({required bool enabled}) {
    if (_isDark == enabled) return;
    _isDark = enabled;
    notifyListeners();
  }

  void toggleTheme() => setDarkMode(enabled: !_isDark);
}
