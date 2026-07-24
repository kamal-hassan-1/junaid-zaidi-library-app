import 'package:flutter/material.dart';

/// Lets any widget below AuthGate — e.g. ProfileScreen, deep inside
/// RootShell's More tab — trigger a logout (which also correctly exits
/// guest mode, see AuthGate) and check whether the current session is a
/// real account or just guest browsing. Same InheritedWidget pattern
/// app_tab_scope.dart already uses for switching bottom tabs.
class AuthScope extends InheritedWidget {
  final Future<void> Function() onLogout;
  final bool isGuest;

  const AuthScope({
    super.key,
    required this.onLogout,
    required this.isGuest,
    required super.child,
  });

  static AuthScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope.of() called with no AuthScope ancestor');
    return scope!;
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) =>
      oldWidget.onLogout != onLogout || oldWidget.isGuest != isGuest;
}