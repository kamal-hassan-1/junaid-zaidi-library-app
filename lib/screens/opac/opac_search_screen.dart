import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../data/search_indexes.dart';
import '../../models/catalog_item.dart';
import '../../models/catalog_search_result.dart';
import '../../repositories/catalog_repository.dart';
import '../../repositories/repository_scope.dart';
import '../../repositories/search_history_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';
import 'book_detail_screen.dart';

/// Which block occupies the area below the search controls. The search
/// box and index chips are always visible — only what sits underneath
/// them swaps, so the student never loses the ability to search from
/// whichever state they're in (including the error state).
enum _OpacView { landing, loading, results, empty, error }

/// OPAC catalog search. Replaces the desktop OPAC's masthead dropdown
/// with always-visible index chips, and its dense results table with the
/// app's existing ListRow.
class OpacSearchScreen extends StatefulWidget {
  const OpacSearchScreen({super.key});

  @override
  State<OpacSearchScreen> createState() => _OpacSearchScreenState();
}

class _OpacSearchScreenState extends State<OpacSearchScreen> {
  // Resolved in initState rather than at field-initializer time, since both
  // need a BuildContext. Safe there because RepositoryScope.of does not
  // register a dependency — see its doc comment.
  late final CatalogRepository _catalog;
  late final SearchHistoryRepository _searchHistory;

  String _query = '';
  SearchIndex _index = defaultSearchIndex;
  _OpacView _view = _OpacView.landing;

  CatalogSearchResult? _result;
  String _submittedQuery = '';
  String _errorMessage = '';

  List<String> _recentSearches = const [];
  List<CatalogItem> _featured = const [];
  bool _isLoadingLanding = true;

  @override
  void initState() {
    super.initState();
    final repositories = RepositoryScope.of(context);
    _catalog = repositories.catalog;
    _searchHistory = repositories.searchHistory;
    _loadLanding();
  }

  Future<void> _loadLanding() async {
    final recent = await _searchHistory.recent();
    final featured = await _catalog.featured();
    if (!mounted) return;
    setState(() {
      _recentSearches = recent;
      _featured = featured;
      _isLoadingLanding = false;
    });
  }

  Future<void> _runSearch(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      _resetToLanding();
      return;
    }

    setState(() {
      _query = query;
      _submittedQuery = query;
      _view = _OpacView.loading;
    });

    try {
      final result = await _catalog.search(query: query, index: _index);
      await _searchHistory.record(query);
      final recent = await _searchHistory.recent();
      if (!mounted) return;
      setState(() {
        _result = result;
        _recentSearches = recent;
        _view = result.isEmpty ? _OpacView.empty : _OpacView.results;
      });
    } on CatalogException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _view = _OpacView.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _view = _OpacView.error;
      });
    }
  }

  void _resetToLanding() {
    setState(() {
      _query = '';
      _submittedQuery = '';
      _result = null;
      _view = _OpacView.landing;
    });
  }

  void _handleIndexSelected(int position) {
    final next = searchIndexes[position];
    if (next == _index) return;

    setState(() => _index = next);

    // Re-run the current query against the newly selected field, so
    // switching chips reads as "search this instead" rather than
    // silently leaving stale results from the previous field on screen.
    if (_submittedQuery.isNotEmpty) _runSearch(_submittedQuery);
  }

  void _handleResultTap(CatalogItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookDetailScreen(biblioId: item.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ScreenContainer(
        scroll: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _OpacHeader(),
            const SizedBox(height: AppSpacing.lg),
            SearchInput(
              value: _query,
              placeholder: _index.placeholder,
              isSearching: _view == _OpacView.loading,
              onChanged: (value) => setState(() => _query = value),
              onSubmitted: _runSearch,
              onClear: _resetToLanding,
            ),
            const SizedBox(height: AppSpacing.ms),
            AppFilterChips(
              labels: [for (final index in searchIndexes) index.label],
              selectedIndex: searchIndexes.indexOf(_index),
              onSelected: _handleIndexSelected,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_view) {
      case _OpacView.loading:
        return const ListSkeleton();

      case _OpacView.error:
        return _OpacErrorView(
          message: _errorMessage,
          onRetry: () => _runSearch(_submittedQuery),
        );

      case _OpacView.empty:
        return _OpacEmptyView(query: _submittedQuery);

      case _OpacView.results:
        return _ResultsView(
          result: _result!,
          query: _submittedQuery,
          onSelected: _handleResultTap,
        );

      case _OpacView.landing:
        return _LandingView(
          isLoading: _isLoadingLanding,
          recentSearches: _recentSearches,
          featured: _featured,
          onRecentSelected: _runSearch,
          onBookSelected: _handleResultTap,
        );
    }
  }
}

class _OpacHeader extends StatelessWidget {
  const _OpacHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Heading(level: 4, text: 'Library Catalog'),
        SizedBox(height: AppSpacing.xs),
        AppText(
          'Search books, authors and ISBNs held at the Junaid Zaidi Library.',
          variant: 'bodySmall',
          tone: 'secondary',
        ),
      ],
    );
  }
}

/// Section label matching the More tab's grouped-list headings, so the
/// OPAC's sections read as the same kind of thing.
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Heading(level: 5, tone: 'tertiary', text: text),
    );
  }
}

/// Shared by the landing shelf and the results list, so a book looks
/// identical wherever it appears.
class _BookList extends StatelessWidget {
  final List<CatalogItem> items;
  final ValueChanged<CatalogItem> onSelected;

  const _BookList({required this.items, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            ListRow(
              icon: LucideIcons.book,
              accent: AppAccent.brand,
              label: items[i].title,
              secondaryLabel: items[i].subtitleLine,
              // The badge occupies the trailing slot, so the chevron is
              // suppressed rather than competing with it for width.
              showChevron: false,
              badge: AppBadge(
                label: items[i].availabilityLabel,
                intent: items[i].availabilityBadgeIntent,
              ),
              showDivider: i < items.length - 1,
              onTap: () => onSelected(items[i]),
            ),
        ],
      ),
    );
  }
}

class _LandingView extends StatelessWidget {
  final bool isLoading;
  final List<String> recentSearches;
  final List<CatalogItem> featured;
  final ValueChanged<String> onRecentSelected;
  final ValueChanged<CatalogItem> onBookSelected;

  const _LandingView({
    required this.isLoading,
    required this.recentSearches,
    required this.featured,
    required this.onRecentSelected,
    required this.onBookSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const ListSkeleton(rows: 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recentSearches.isNotEmpty) ...[
          const _SectionLabel('Recent searches'),
          AppFilterChips(
            labels: recentSearches,
            wrap: true,
            onSelected: (i) => onRecentSelected(recentSearches[i]),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        const _SectionLabel('Popular right now'),
        _BookList(items: featured, onSelected: onBookSelected),
      ],
    );
  }
}

class _ResultsView extends StatelessWidget {
  final CatalogSearchResult result;
  final String query;
  final ValueChanged<CatalogItem> onSelected;

  const _ResultsView({
    required this.result,
    required this.query,
    required this.onSelected,
  });

  String get _summary {
    final count = result.totalResults;
    final noun = count == 1 ? 'result' : 'results';
    return '$count $noun for "$query"';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AppText(_summary, variant: 'bodySmall', tone: 'secondary'),
        ),
        _BookList(items: result.items, onSelected: onSelected),
        // Phase 1 loads a single page. The service already paginates, so
        // this note is replaced by infinite scroll rather than reworked.
        if (result.hasMore) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: AppText(
              'Showing the first ${result.items.length} of ${result.totalResults}. '
              'Narrow your search to see more.',
              variant: 'caption',
              tone: 'tertiary',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}

class _OpacEmptyView extends StatelessWidget {
  final String query;

  const _OpacEmptyView({required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: EmptyState(
        icon: LucideIcons.search_x,
        title: 'No matches found',
        description: 'Nothing in the catalog matched "$query". Check the '
            'spelling, or switch the search field above.',
      ),
    );
  }
}

class _OpacErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _OpacErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: ErrorState(
        title: 'Search unavailable',
        description: message,
        onRetry: onRetry,
      ),
    );
  }
}
