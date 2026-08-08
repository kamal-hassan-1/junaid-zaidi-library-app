import 'package:flutter/widgets.dart';

/// Lets any screen toggle light/dark mode without depending on [MaterialApp]
/// internals. Theme defaults to light and ignores the OS setting.
class ThemeScope extends InheritedWidget {
  final bool isDarkMode;
  final Future<void> Function(bool isDarkMode) setDarkMode;

  const ThemeScope({
    super.key,
    required this.isDarkMode,
    required this.setDarkMode,
    required super.child,
  });

  static ThemeScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope.of() called outside of ThemeScope');
    return scope!;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) =>
      oldWidget.isDarkMode != isDarkMode ||
      oldWidget.setDarkMode != setDarkMode;
}
