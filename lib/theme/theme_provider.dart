import 'package:flutter/widgets.dart';

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

/// Resolves light/dark semantic colors for the whole app.
///
/// The original Expo app pins `userInterfaceStyle: "light"` in app.json, so
/// dark mode is wired through (see theme/semantic/dark.dart) but not
/// actually reachable on-device yet. This mirrors that by always resolving
/// to [lightColors] — swap the `colors:` line below to wire up a future
/// manual theme toggle.
class AppThemeProvider extends StatelessWidget {
  final Widget child;

  const AppThemeProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return _InheritedAppTheme(colors: lightColors, child: child);
  }
}

/// `useTheme(context).colors` — the active semantic color set.
SemanticColors useTheme(BuildContext context) {
  final inherited = context.dependOnInheritedWidgetOfExactType<_InheritedAppTheme>();
  assert(inherited != null, 'useTheme() must be called within an AppThemeProvider');
  return inherited!.colors;
}
