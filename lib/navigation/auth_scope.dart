import 'package:flutter/material.dart';

/// Lets any widget below AuthGate — e.g. ProfileScreen, deep inside
/// RootShell's More tab — trigger a Koha logout without holding a direct
/// reference to AuthGate. Same InheritedWidget pattern app_tab_scope.dart
/// already uses for switching bottom tabs from anywhere.
class AuthScope extends InheritedWidget {
  final Future<void> Function() onLogout;

  const AuthScope({
    super.key,
    required this.onLogout,
    required super.child,
  });

  static AuthScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope.of() called with no AuthScope ancestor');
    return scope!;
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) => oldWidget.onLogout != onLogout;
}