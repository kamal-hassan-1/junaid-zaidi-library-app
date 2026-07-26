import 'package:flutter/widgets.dart';

import 'repository_registry.dart';

/// Makes the app's repositories reachable from any widget below it — the same
/// InheritedWidget pattern `auth_scope.dart` and `app_tab_scope.dart` already
/// use for cross-tree access, so this introduces no new concept.
///
/// Installed once above the app (see `main.dart`, from Step 2 onward) with a
/// registry built from `DataSourceConfig`. Screens then ask for what they need
/// instead of constructing it, which is the seam the whole refactor exists to
/// create.
class RepositoryScope extends InheritedWidget {
  final RepositoryRegistry repositories;

  const RepositoryScope({
    super.key,
    required this.repositories,
    required super.child,
  });

  /// The repositories in scope, looked up **without** subscribing to changes.
  ///
  /// Uses [BuildContext.getInheritedWidgetOfExactType] rather than
  /// `dependOnInheritedWidgetOfExactType` for two reasons. The registry is
  /// built once at startup and never replaced, so there is no change to
  /// rebuild for. And it makes this safe to call from `initState`, which
  /// matters immediately: `OpacSearchScreen` loads its landing data there, and
  /// `dependOn…` throws when called that early.
  ///
  /// That is deliberately the opposite choice from `AuthScope`, which does
  /// subscribe — correctly, because its `isGuest` value changes at runtime.
  ///
  /// Returns the registry directly rather than the scope widget, so callers
  /// read `RepositoryScope.of(context).catalog`.
  static RepositoryRegistry of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<RepositoryScope>();
    assert(
      scope != null,
      'RepositoryScope.of() called with no RepositoryScope ancestor',
    );
    return scope!.repositories;
  }

  @override
  bool updateShouldNotify(RepositoryScope oldWidget) =>
      oldWidget.repositories != repositories;
}
