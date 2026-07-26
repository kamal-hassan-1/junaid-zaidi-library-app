import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:junaid_zaidi_library_app/data/search_indexes.dart';
import 'package:junaid_zaidi_library_app/models/catalog_item.dart';
import 'package:junaid_zaidi_library_app/models/catalog_search_result.dart';
import 'package:junaid_zaidi_library_app/repositories/catalog_repository.dart';
import 'package:junaid_zaidi_library_app/repositories/mock/mock_catalog_repository.dart';
import 'package:junaid_zaidi_library_app/repositories/repository_registry.dart';
import 'package:junaid_zaidi_library_app/repositories/repository_scope.dart';
import 'package:junaid_zaidi_library_app/screens/opac/opac_search_screen.dart';
import 'package:junaid_zaidi_library_app/theme/theme.dart';
import 'package:junaid_zaidi_library_app/widgets/ui.dart';

/// How the OPAC search screen behaves when the catalog repository fails.
///
/// The mock repository never throws, so none of this was reachable before the
/// REST implementation existed — these tests stand in for the backend being
/// down, unreachable or misbehaving.
void main() {
  const networkMessage =
      'Could not reach the library catalog. Check your connection and try again.';
  const recordMessage = 'That record could not be found in the catalog.';

  /// Mounts the search screen over [catalog]. No Firebase app is needed because
  /// the screen is mounted directly rather than through RootShell.
  ///
  /// The Scaffold stands in for the one RootShell provides in the app; the
  /// search box's TextField requires a Material ancestor.
  Future<void> pumpSearch(WidgetTester tester, CatalogRepository catalog) async {
    await tester.pumpWidget(
      RepositoryScope(
        repositories: RepositoryRegistry(
          catalog: catalog,
          searchHistory: MockSearchHistoryRepository(),
        ),
        child: AppThemeProvider(
          child: const MaterialApp(
            home: Scaffold(body: OpacSearchScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
  }

  group('a failing landing shelf', () {
    testWidgets('shows the error state instead of throwing', (tester) async {
      await pumpSearch(
        tester,
        _StubCatalog(featuredErrors: [const CatalogException(networkMessage)]),
      );

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Catalog unavailable'), findsOneWidget);
      expect(find.text(networkMessage), findsOneWidget);
      // Nothing escaped as an unhandled async error, which is what used to
      // happen here.
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not leave the loading skeleton on screen', (tester) async {
      await pumpSearch(
        tester,
        _StubCatalog(featuredErrors: [const CatalogException(networkMessage)]),
      );

      expect(find.byType(ListSkeleton), findsNothing);
    });

    testWidgets('a not-found is reworded for a list of books', (tester) async {
      // getBiblio's wording is about one record, so it would read as a
      // non-sequitur on the shelf. featured() is not documented to throw this,
      // but the screen should not repeat it verbatim if it ever does.
      await pumpSearch(
        tester,
        _StubCatalog(
          featuredErrors: [const CatalogNotFoundException(recordMessage)],
        ),
      );

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text(recordMessage), findsNothing);
      expect(
        find.text(
          'The library catalog could not complete that request. Please try again.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unexpected exception falls back to generic wording', (tester) async {
      await pumpSearch(
        tester,
        _StubCatalog(featuredErrors: [StateError('bad state')]),
      );

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('retry reloads the shelf rather than running a search', (tester) async {
      final catalog = _StubCatalog(
        featuredErrors: [const CatalogException(networkMessage)],
      );
      await pumpSearch(tester, catalog);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsNothing);
      expect(find.text('Featured Book'), findsOneWidget);
      expect(catalog.featuredCalls, 2);
      expect(catalog.searchCalls, 0, reason: 'retry belongs to the shelf here');
    });

    testWidgets('the student can still search while the shelf is broken', (tester) async {
      // The search box stays visible in every state on purpose, so a failed
      // shelf must not be a dead end.
      await pumpSearch(
        tester,
        _StubCatalog(featuredErrors: [const CatalogException(networkMessage)]),
      );

      await search(tester, 'algorithms');

      expect(find.byType(ErrorState), findsNothing);
      expect(find.text('Result Book'), findsOneWidget);
    });

    testWidgets('clearing the search box recovers the shelf', (tester) async {
      // The shelf never loaded, so returning to it has to re-request rather
      // than reveal an empty list.
      final catalog = _StubCatalog(
        featuredErrors: [const CatalogException(networkMessage)],
      );
      await pumpSearch(tester, catalog);
      await search(tester, 'algorithms');

      await tester.tap(find.bySemanticsLabel('Clear search'));
      await tester.pumpAndSettle();

      expect(find.text('Featured Book'), findsOneWidget);
      expect(catalog.featuredCalls, 2);
    });
  });

  group('a failing search', () {
    testWidgets('shows the error state with the search wording', (tester) async {
      await pumpSearch(
        tester,
        _StubCatalog(searchError: const CatalogException(networkMessage)),
      );

      await search(tester, 'algorithms');

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Search unavailable'), findsOneWidget);
      expect(find.text(networkMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('retry repeats the search', (tester) async {
      final catalog = _StubCatalog(
        searchError: const CatalogException(networkMessage),
      );
      await pumpSearch(tester, catalog);
      await search(tester, 'algorithms');

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(catalog.searchCalls, 2);
      expect(catalog.featuredCalls, 1, reason: 'the shelf loaded fine');
    });

    testWidgets('an unexpected exception falls back to generic wording', (tester) async {
      await pumpSearch(tester, _StubCatalog(searchError: StateError('bad state')));

      await search(tester, 'algorithms');

      expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// A catalog that fails on demand.
///
/// [featuredErrors] is consumed one call at a time, so a retry can succeed
/// after an initial failure; [searchError] persists, since no test needs a
/// search to recover.
class _StubCatalog implements CatalogRepository {
  final List<Object> featuredErrors;
  final Object? searchError;

  int featuredCalls = 0;
  int searchCalls = 0;

  _StubCatalog({this.featuredErrors = const [], this.searchError});

  @override
  Future<List<CatalogItem>> featured() async {
    final call = featuredCalls++;
    if (call < featuredErrors.length) throw featuredErrors[call];
    return const [CatalogItem(id: '1', title: 'Featured Book')];
  }

  @override
  Future<CatalogSearchResult> search({
    required String query,
    SearchIndex index = defaultSearchIndex,
    int page = 1,
    int perPage = defaultCatalogPerPage,
  }) async {
    searchCalls++;
    final error = searchError;
    if (error != null) throw error;

    return const CatalogSearchResult(
      items: [CatalogItem(id: '2', title: 'Result Book')],
      page: 1,
      perPage: 20,
      totalResults: 1,
      hasMore: false,
    );
  }

  @override
  Future<CatalogItem> getBiblio(String id) async =>
      CatalogItem(id: id, title: 'Book $id');
}
