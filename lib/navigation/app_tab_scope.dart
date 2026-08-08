import 'package:flutter/widgets.dart';

/// Bottom tab indices.
class AppTabs {
  const AppTabs._();

  static const int home = 0;
  static const int search = 1;
  static const int services = 2;
  static const int spaces = 3;
  static const int more = 4;
}

/// Lets a leaf screen switch the active bottom tab without knowing how
/// RootShell is implemented.
class AppTabScope extends InheritedWidget {
  final ValueChanged<int> goToTab;

  /// Switch to the Search (OPAC) tab. When [query] is non-null, OPAC
  /// applies it (e.g. Home search box submit).
  final void Function([String? query]) openSearch;

  /// Switch to the More tab and push [routeName] on More's nested Navigator
  /// (e.g. [MoreRoutes.about]), so stack titles and named sub-routes work.
  final void Function(String routeName) openMoreRoute;

  const AppTabScope({
    super.key,
    required this.goToTab,
    required this.openSearch,
    required this.openMoreRoute,
    required super.child,
  });

  static AppTabScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppTabScope>();
    assert(scope != null, 'AppTabScope.of() called outside of AppTabScope');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppTabScope oldWidget) =>
      oldWidget.goToTab != goToTab ||
      oldWidget.openSearch != openSearch ||
      oldWidget.openMoreRoute != openMoreRoute;
}
