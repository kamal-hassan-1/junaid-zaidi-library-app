import 'package:flutter/widgets.dart';

import 'semantic/dark.dart';
import 'semantic/light.dart';
import 'semantic/semantic_colors.dart';

/// The only part of the theme that actually varies at runtime is color —
/// spacing, radius and typography are structural and identical in both
/// modes (see AppSpacing/AppRadius/AppTypography in theme/tokens/), so
/// widgets import those static token classes directly instead of routing
/// them through this provider. This mirrors `useTheme()` in the original
/// app, minus the token groups that never change.
class _InheritedAppTheme extends InheritedWidget {
  final SemanticColors colors;

  const _InheritedAppTheme({required this.colors, required super.child});

  @override
  bool updateShouldNotify(_InheritedAppTheme oldWidget) => oldWidget.colors != colors;
}

/// Resolves light/dark semantic colors from the OS (or Material) brightness.
///
/// Prefer mounting this inside [MaterialApp.builder] so [brightness] comes from
/// `ThemeMode.system`. If [brightness] is omitted, falls back to
/// [MediaQuery.platformBrightnessOf].
class AppThemeProvider extends StatelessWidget {
  final Widget child;
  final Brightness? brightness;

  const AppThemeProvider({super.key, required this.child, this.brightness});

  @override
  Widget build(BuildContext context) {
    final resolved = brightness ?? MediaQuery.platformBrightnessOf(context);
    final colors = resolved == Brightness.dark ? darkColors : lightColors;
    return _InheritedAppTheme(colors: colors, child: child);
  }
}

/// Active semantic color set for the current brightness.
SemanticColors useTheme(BuildContext context) {
  final inherited = context.dependOnInheritedWidgetOfExactType<_InheritedAppTheme>();
  assert(inherited != null, 'useTheme() must be called within an AppThemeProvider');
  return inherited!.colors;
}
