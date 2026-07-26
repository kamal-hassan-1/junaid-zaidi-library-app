import 'package:flutter/material.dart';

/// Lets any widget below AuthGate — e.g. ProfileScreen, deep inside
/// RootShell's More tab — trigger a logout (which also correctly exits
/// guest mode, see AuthGate) and check whether the current session is a
/// real account or just guest browsing. Same InheritedWidget pattern
/// app_tab_scope.dart already uses for switching bottom tabs.
class AuthScope extends InheritedWidget {
  final Future<void> Function() onLogout;

  /// Leaves guest mode and reopens the auth flow at [routeName] (an
  /// [AuthRoutes] value), with Welcome still behind it to go back to.
  ///
  /// Needed because the auth flow's Navigator only exists while AuthGate is
  /// signed out, so a guest sitting inside RootShell can't simply push a
  /// login route — the gate itself has to swap over first.
  final Future<void> Function(String routeName) onRequestAuth;

  final bool isGuest;

  const AuthScope({
    super.key,
    required this.onLogout,
    required this.onRequestAuth,
    required this.isGuest,
    required super.child,
  });

  /// True only for a real account. Gated features (the OPAC catalog, and
  /// later the patron account) check this before navigating, since a guest
  /// has no Firebase ID token to authorize the backend with.
  bool get isAuthenticated => !isGuest;

  static AuthScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope.of() called with no AuthScope ancestor');
    return scope!;
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) =>
      oldWidget.onLogout != onLogout ||
      oldWidget.onRequestAuth != onRequestAuth ||
      oldWidget.isGuest != isGuest;
}
