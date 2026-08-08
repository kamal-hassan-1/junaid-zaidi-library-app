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

/// Supplies semantic colors from the app's explicit light/dark choice.
class AppThemeProvider extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;

  const AppThemeProvider({
    super.key,
    required this.child,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = isDarkMode ? darkColors : lightColors;
    return _InheritedAppTheme(colors: colors, child: child);
  }
}

/// Active semantic color set for the current brightness.
SemanticColors useTheme(BuildContext context) {
  final inherited = context.dependOnInheritedWidgetOfExactType<_InheritedAppTheme>();
  assert(inherited != null, 'useTheme() must be called within an AppThemeProvider');
  return inherited!.colors;
}
