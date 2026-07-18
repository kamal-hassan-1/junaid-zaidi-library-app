import 'package:flutter/widgets.dart';

/// Bottom tab indices (mirrors app/(tabs)/_layout.js's tab order).
class AppTabs {
  const AppTabs._();

  static const int home = 0;
  static const int libraryResources = 1;
  static const int exploreSpaces = 2;
  static const int more = 3;
}

/// Lets a leaf screen (e.g. Home's "Explore Spaces" resource card) switch
/// the active bottom tab without knowing how RootShell is implemented.
/// Mirrors the original app's `router.push("/(tabs)/explore-spaces")`,
/// which is a tab switch rather than a stack push.
class AppTabScope extends InheritedWidget {
  final ValueChanged<int> goToTab;

  const AppTabScope({super.key, required this.goToTab, required super.child});

  static AppTabScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppTabScope>();
    assert(scope != null, 'AppTabScope.of() called outside of AppTabScope');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppTabScope oldWidget) => oldWidget.goToTab != goToTab;
}
