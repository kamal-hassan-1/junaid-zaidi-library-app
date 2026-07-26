import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:junaid_zaidi_library_app/navigation/auth_scope.dart';
import 'package:junaid_zaidi_library_app/navigation/routes.dart';
import 'package:junaid_zaidi_library_app/repositories/repository_registry.dart';
import 'package:junaid_zaidi_library_app/repositories/repository_scope.dart';
import 'package:junaid_zaidi_library_app/screens/opac/book_detail_screen.dart';
import 'package:junaid_zaidi_library_app/screens/opac/opac_search_screen.dart';
import 'package:junaid_zaidi_library_app/screens/root_shell.dart';
import 'package:junaid_zaidi_library_app/theme/theme.dart';
import 'package:junaid_zaidi_library_app/widgets/ui.dart';

/// Covers how the OPAC module hangs off the Home tab: the auth guard on the
/// OPAC card, and the Home -> Search -> Detail -> back stack.
void main() {
  /// Auth routes the shell asked AuthGate to open, in order.
  final requestedAuthRoutes = <String>[];

  setUp(requestedAuthRoutes.clear);

  /// Mounts the shell under a stub AuthScope, since the real AuthGate needs a
  /// live Firebase app.
  Future<void> pumpShell(WidgetTester tester, {required bool isGuest}) async {
    // The More tab constructs a FirebaseAuthService as soon as it mounts and
    // IndexedStack builds every tab up front, so mounting the shell without a
    // Firebase app logs [core/no-app] from a tab these tests never open. It's
    // also why test/widget_test.dart can't mount the shell at all.
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is FirebaseException) return;
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.pumpWidget(
      // Mirrors main.dart: the OPAC screens read their CatalogRepository from
      // this scope, so the shell needs one above it. fromConfig() gives the
      // same mock implementation the app runs on, latency included.
      RepositoryScope(
        repositories: RepositoryRegistry.fromConfig(),
        child: AppThemeProvider(
          child: MaterialApp(
            home: AuthScope(
              isGuest: isGuest,
              onLogout: () async {},
              onRequestAuth: (routeName) async {
                requestedAuthRoutes.add(routeName);
              },
              child: const RootShell(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapOpacCard(WidgetTester tester) async {
    await tester.tap(find.text('OPAC'));
    await tester.pumpAndSettle();
  }

  /// Routes underneath the top one stay in the element tree, so finders have
  /// to be scoped to the screen under test or they also match the Home
  /// screen's widgets.
  Finder inOpacSearch(Finder matching) =>
      find.descendant(of: find.byType(OpacSearchScreen), matching: matching);

  /// The same platform message Android's back button sends.
  Future<void> pressSystemBack(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  /// True when the shell is letting the platform handle back, meaning the
  /// active tab has nothing left of its own to pop.
  bool backBelongsToPlatform(WidgetTester tester) {
    final popScope = tester.widget(
      find
          .descendant(
            of: find.byType(RootShell),
            // Matched by predicate rather than byType because the shell's
            // PopScope has an inferred type argument.
            matching: find.byWidgetPredicate((widget) => widget is PopScope),
          )
          .first,
    );
    return (popScope as PopScope).canPop;
  }

  group('OPAC auth guard', () {
    testWidgets('a signed-in student goes straight to the catalog', (tester) async {
      await pumpShell(tester, isGuest: false);

      await tapOpacCard(tester);

      expect(find.byType(OpacSearchScreen), findsOneWidget);
      expect(find.text('Sign in Required'), findsNothing);

      // Pushed inside the Home tab, so the shell's tab bar stays put.
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('a guest is prompted instead of navigated', (tester) async {
      await pumpShell(tester, isGuest: true);

      await tapOpacCard(tester);

      expect(find.text('Sign in Required'), findsOneWidget);
      expect(find.byType(OpacSearchScreen), findsNothing);
      expect(requestedAuthRoutes, isEmpty);
    });

    testWidgets('"Sign In" opens the existing email login screen', (tester) async {
      await pumpShell(tester, isGuest: true);
      await tapOpacCard(tester);

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(requestedAuthRoutes, [AuthRoutes.emailLogin]);
      expect(find.text('Sign in Required'), findsNothing);
    });

    testWidgets('"Create Account" opens the existing signup screen', (tester) async {
      await pumpShell(tester, isGuest: true);
      await tapOpacCard(tester);

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(requestedAuthRoutes, [AuthRoutes.signupEmail]);
      expect(find.text('Sign in Required'), findsNothing);
    });

    testWidgets('"Maybe Later" only closes the dialog', (tester) async {
      await pumpShell(tester, isGuest: true);
      await tapOpacCard(tester);

      await tester.tap(find.text('Maybe Later'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in Required'), findsNothing);
      expect(requestedAuthRoutes, isEmpty);
      expect(find.byType(OpacSearchScreen), findsNothing);
      expect(find.text('Resources'), findsOneWidget, reason: 'still on Home');
    });
  });

  group('OPAC stack', () {
    testWidgets('back from a book returns to the results that were open', (tester) async {
      await pumpShell(tester, isGuest: false);
      await tapOpacCard(tester);

      await tester.enterText(inOpacSearch(find.byType(TextField)), 'algorithms');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      final resultsSummary = inOpacSearch(find.textContaining('for "algorithms"'));
      expect(resultsSummary, findsOneWidget);

      await tester.tap(inOpacSearch(find.byType(ListRow)).first);
      await tester.pumpAndSettle();
      expect(find.byType(BookDetailScreen), findsOneWidget);

      await pressSystemBack(tester);

      expect(find.byType(BookDetailScreen), findsNothing);
      // The search screen was never disposed, so its results are still on
      // screen rather than reset to the landing state.
      expect(resultsSummary, findsOneWidget);
    });

    testWidgets('back unwinds the Home tab before the platform sees it', (tester) async {
      await pumpShell(tester, isGuest: false);
      expect(
        backBelongsToPlatform(tester),
        isTrue,
        reason: 'Home is at its root, so nothing local to pop',
      );

      await tapOpacCard(tester);
      expect(
        backBelongsToPlatform(tester),
        isFalse,
        reason: 'the shell has to claim back while the catalog is open',
      );

      await pressSystemBack(tester);

      expect(find.byType(OpacSearchScreen), findsNothing);
      expect(find.text('Resources'), findsOneWidget);
      // Back is the platform's again, which is what lets Android close the
      // app from Home instead of the shell swallowing the gesture.
      expect(backBelongsToPlatform(tester), isTrue);
    });
  });
}
