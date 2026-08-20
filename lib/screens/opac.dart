import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../config/api_constants.dart';
import '../models/availability.dart';
import '../models/biblio.dart';
import '../services/biblio_service.dart';
import '../services/book_bag_service.dart';
import '../services/circulation_service.dart';
import '../services/mock_biblio_service.dart';
import '../services/search_history_service.dart';
import '../services/watchlist_service.dart';
import '../theme/theme.dart';
import '../widgets/ui.dart';
import 'advanced_search_screen.dart';
import 'barcode_scanner_screen.dart';
import 'book_bag_screen.dart';

/// OPAC (Online Public Access Catalog) — full catalog search screen.
///
/// Hosted as the Search tab (so the bottom nav stays visible). Also opened
/// from Home's search box / OPAC quick link via [queryGeneration].
class OpacScreen extends StatefulWidget {
  const OpacScreen({
    super.key,
    this.initialQuery,
    this.queryGeneration = 0,
  });

  final String? initialQuery;

  /// Bumped by RootShell when Home seeds a new query so [didUpdateWidget]
  /// re-applies even if the query string is unchanged.
  final int queryGeneration;

  @override
  State<OpacScreen> createState() => _OpacScreenState();
}

class _OpacScreenState extends State<OpacScreen> with TickerProviderStateMixin {
  /// Debounce so each keystroke doesn't fire its own Koha search request.
  static const _searchDebounce = Duration(milliseconds: 350);

  /// Item-type filter options shown in the dropdown. `code: null` is "All
  /// types". BK/EBK/CF are confirmed real itemtype codes for this
  /// library, read directly off the live OPAC's search facets; THESIS is
  /// still an unconfirmed guess (see deferred.md) — no thesis-like code
  /// showed up in the facets checked so far.
  static const List<({String? code, String label})> _typeFilters = [
    (code: null, label: 'All types'),
    (code: 'BK', label: 'Books'),
    (code: 'EBK', label: 'eBooks'),
    (code: 'CF', label: 'Computer Files'),
    (code: 'THESIS', label: 'Thesis'),
  ];

  /// Search-scope options — mirrors the real OPAC website's `idx=`
  /// search-index parameter exactly (confirmed from the live site's
  /// search form, see deferred.md). Series/call-number exist on the real
  /// site too but aren't included yet since [Biblio] doesn't carry those
  /// fields.
  static const List<({String? code, String label})> _searchFields = [
    (code: null, label: 'Keyword'),
    (code: 'ti', label: 'Title'),
    (code: 'au', label: 'Author'),
    (code: 'su', label: 'Subject'),
    (code: 'nb', label: 'ISBN'),
    (code: 'ns', label: 'ISSN'),
  ];

  /// Campus filter — real confirmed codes for this library, read
  /// directly off the live OPAC's "Home libraries" facet (`homebranch:`,
  /// see deferred.md).
  static const List<({String? code, String label})> _campusFilters = [
    (code: null, label: 'All campuses'),
    (code: 'isb', label: 'Islamabad'),
    (code: 'lhr', label: 'Lahore'),
    (code: 'atd', label: 'Abbottabad'),
    (code: 'atk', label: 'Attock'),
    (code: 'swl', label: 'Sahiwal'),
    (code: 'veh', label: 'Vehari'),
    (code: 'wah', label: 'Wah'),
  ];

  late String _query = widget.initialQuery ?? '';
  String? _selectedItemType;
  String? _selectedSearchField;
  String? _selectedCampus;
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;
  List<Biblio> _filteredBooks = const [];

  /// Set only while showing results from [AdvancedSearchScreen] — takes
  /// over from the plain search bar/filters until the user types in the
  /// search bar again or changes a filter, either of which clears it.
  AdvancedSearchQuery? _advancedQuery;

  Timer? _debounceTimer;

  final BiblioSource _biblioService =
      ApiConstants.useMockKohaBackend ? MockBiblioService() : BiblioService();

  @override
  void initState() {
    super.initState();
    _loadBooks();
    BookBagService.instance.ensureLoaded();
    SearchHistoryService.instance.ensureLoaded();
    WatchlistService.instance.ensureLoaded();
  }

  @override
  void didUpdateWidget(covariant OpacScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.queryGeneration != oldWidget.queryGeneration) {
      final query = widget.initialQuery ?? '';
      setState(() => _query = query);
      _onSubmitted(query);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final books = await _biblioService.search(
        _query,
        itemType: _selectedItemType,
        searchField: _selectedSearchField,
        campus: _selectedCampus,
      );
      if (!mounted) return;
      setState(() {
        _filteredBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Called on every keystroke — updates the text immediately but waits
  /// [_searchDebounce] of inactivity before actually hitting the search
  /// endpoint, so typing quickly doesn't fire a request per character.
  void _onSearch(String query) {
    setState(() => _query = query);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_searchDebounce, () => _runSearch(query));
  }

  /// Submits immediately (Enter key / search-icon action), skipping the
  /// debounce.
  void _onSubmitted(String query) {
    _debounceTimer?.cancel();
    _runSearch(query);
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _advancedQuery = null;
    });

    if (query.trim().isNotEmpty) {
      unawaited(SearchHistoryService.instance.add(query.trim()));
    }

    try {
      final results = await _biblioService.search(
        query,
        itemType: _selectedItemType,
        searchField: _selectedSearchField,
        campus: _selectedCampus,
      );
      if (!mounted) return;
      setState(() {
        _filteredBooks = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isSearching = false;
      });
    }
  }

  /// Runs an [AdvancedSearchScreen] result — replaces whatever the plain
  /// search bar/filters had, since the two are separate ways of
  /// producing a result set, not composable in the current UI.
  Future<void> _runAdvancedSearch(AdvancedSearchQuery query) async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _advancedQuery = query;
      _query = '';
      _selectedItemType = null;
      _selectedSearchField = null;
      _selectedCampus = null;
    });

    try {
      final results = await _biblioService.advancedSearch(
        title: query.title,
        author: query.author,
        isbn: query.isbn,
        issn: query.issn,
        publisher: query.publisher,
        seriesTitle: query.seriesTitle,
        publicationYear: query.publicationYear,
        itemType: query.itemType,
      );
      if (!mounted) return;
      setState(() {
        _filteredBooks = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isSearching = false;
      });
    }
  }

  Future<void> _openAdvancedSearch() async {
    final query = await Navigator.of(context).push<AdvancedSearchQuery>(
      MaterialPageRoute(builder: (_) => const AdvancedSearchScreen()),
    );
    if (query != null && mounted) _runAdvancedSearch(query);
  }

  /// Type filter changes apply immediately (no debounce — it's a discrete
  /// selection, not free text).
  void _onTypeChanged(String? code) {
    if (code == _selectedItemType) return;
    setState(() => _selectedItemType = code);
    _onSubmitted(_query);
  }

  /// Search-field changes apply immediately, same as [_onTypeChanged].
  void _onSearchFieldChanged(String? code) {
    if (code == _selectedSearchField) return;
    setState(() => _selectedSearchField = code);
    _onSubmitted(_query);
  }

  /// Campus changes apply immediately, same as [_onTypeChanged].
  void _onCampusChanged(String? code) {
    if (code == _selectedCampus) return;
    setState(() => _selectedCampus = code);
    _onSubmitted(_query);
  }

  void _showBookDetails(BuildContext context, Biblio book) {
    final colors = useTheme(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BookDetailSheet(book: book, colors: colors, biblioService: _biblioService),
    );
  }

  /// Scans a barcode/ISBN and jumps straight to that book's detail sheet
  /// — a mobile-native shortcut the real OPAC website has no equivalent
  /// for.
  Future<void> _openScanner() async {
    final result = await Navigator.of(context).push<Biblio>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (result != null && mounted) {
      _showBookDetails(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return Scaffold(
      backgroundColor: colors.background.primary,
      appBar: AppBar(
        backgroundColor: colors.background.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Heading(level: 5, text: 'OPAC'),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.scan_barcode, size: 20, color: colors.icon),
            onPressed: _openScanner,
            tooltip: 'Scan a barcode',
          ),
          ListenableBuilder(
            listenable: BookBagService.instance,
            builder: (context, _) {
              final count = BookBagService.instance.count;
              return IconButton(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: Icon(LucideIcons.shopping_bag, size: 20, color: colors.icon),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BookBagScreen()),
                ),
                tooltip: 'Book bag',
              );
            },
          ),
          IconButton(
            icon: Icon(LucideIcons.refresh_cw, size: 20, color: colors.icon),
            onPressed: _loadBooks,
            tooltip: 'Refresh catalog',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ScreenContainer(
        scroll: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Search Bar ---
            SearchInput(
              value: _query,
              onChanged: _onSearch,
              onClear: () {
                setState(() => _query = '');
                _onSubmitted('');
              },
              onSubmitted: (query) {
                setState(() => _query = query);
                _onSubmitted(query);
              },
              isSearching: _isSearching,
              placeholder: 'Search by title, author, or ISBN...',
            ),

            const SizedBox(height: AppSpacing.xs),

            // --- Advanced search entry point ---
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: 'Advanced Search',
                variant: 'text',
                fullWidth: false,
                icon: LucideIcons.sliders_horizontal,
                onPressed: _openAdvancedSearch,
              ),
            ),

            // --- Recent searches (local-only — no such Koha endpoint,
            // see SearchHistoryService) — shown while the search bar is
            // empty so it doesn't compete with live results. ---
            if (_query.trim().isEmpty && _advancedQuery == null)
              ListenableBuilder(
                listenable: SearchHistoryService.instance,
                builder: (context, _) {
                  final history = SearchHistoryService.instance.queries;
                  if (history.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText('Recent searches', variant: 'bodySmall', tone: 'secondary'),
                            GestureDetector(
                              onTap: () => SearchHistoryService.instance.clear(),
                              child: AppText('Clear', variant: 'bodySmall', tone: 'brand'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final q in history)
                              _HistoryChip(
                                label: q,
                                onTap: () {
                                  setState(() => _query = q);
                                  _onSubmitted(q);
                                },
                                onRemove: () => SearchHistoryService.instance.remove(q),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

            // --- Filters: search field (mirrors the real OPAC's idx=) + item type ---
            Row(
              children: [
                Expanded(
                  child: _FilterDropdown(
                    hint: 'Search in',
                    options: _searchFields,
                    selected: _selectedSearchField,
                    onChanged: _onSearchFieldChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _FilterDropdown(
                    hint: 'Type',
                    options: _typeFilters,
                    selected: _selectedItemType,
                    onChanged: _onTypeChanged,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // --- Filter: campus (mirrors the real OPAC's homebranch: facet) ---
            _FilterDropdown(
              hint: 'Campus',
              options: _campusFilters,
              selected: _selectedCampus,
              onChanged: _onCampusChanged,
            ),

            const SizedBox(height: AppSpacing.md),

            // --- Results header ---
            if (!_isLoading && _errorMessage == null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.ms),
                child: Row(
                  children: [
                    Icon(LucideIcons.library, size: 16, color: colors.brand),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _advancedQuery == null &&
                              _query.trim().isEmpty &&
                              _selectedItemType == null &&
                              _selectedSearchField == null &&
                              _selectedCampus == null
                          ? '${_filteredBooks.length} books in catalog'
                          : '${_filteredBooks.length} result${_filteredBooks.length != 1 ? 's' : ''} found',
                      style: AppTypography.bodySmall
                          .toTextStyle(color: colors.text.secondary),
                    ),
                  ],
                ),
              ),

            // --- Content ---
            Expanded(child: _buildContent(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SemanticColors colors) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(colors.brand),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Loading catalog...',
              style: AppTypography.bodySmall
                  .toTextStyle(color: colors.text.tertiary),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.error.withValues(alpha: 0.1),
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.wifi_off, size: 28, color: colors.error),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to load catalog',
              style: AppTypography.h5.toTextStyle(color: colors.text.primary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                _errorMessage ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall
                    .toTextStyle(color: colors.text.tertiary),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton.icon(
              onPressed: _loadBooks,
              icon: Icon(LucideIcons.refresh_cw, size: 16, color: colors.brand),
              label: Text(
                'Retry',
                style: AppTypography.bodyBase
                    .toTextStyle(color: colors.brand)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.background.tertiary,
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.book_open, size: 28, color: colors.icon),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _query.trim().isEmpty &&
                      _selectedItemType == null &&
                      _selectedSearchField == null &&
                      _selectedCampus == null
                  ? 'No books in the catalog yet'
                  : 'No results for "$_query"',
              style: AppTypography.bodyBase
                  .toTextStyle(color: colors.text.primary)
                  .copyWith(fontWeight: FontWeight.w500),
            ),
            if (_query.trim().isNotEmpty ||
                _selectedItemType != null ||
                _selectedSearchField != null ||
                _selectedCampus != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _selectedItemType != null ||
                        _selectedSearchField != null ||
                        _selectedCampus != null
                    ? 'Try a different search term or filter.'
                    : 'Try a different search term.',
                style: AppTypography.bodySmall
                    .toTextStyle(color: colors.text.tertiary),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: _filteredBooks.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.ms),
      itemBuilder: (context, index) {
        final book = _filteredBooks[index];
        return _BookCard(
          book: book,
          colors: colors,
          biblioService: _biblioService,
          onTap: () => _showBookDetails(context, book),
          index: index,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
//  Recent-search chip
// ---------------------------------------------------------------------------

/// One tappable past query in the "Recent searches" row — tap the label
/// to re-run it, tap the x to drop just that one entry.
class _HistoryChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _HistoryChip({
    required this.label,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: colors.background.secondary,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.clock, size: 12, color: colors.text.tertiary),
            const SizedBox(width: AppSpacing.xs),
            AppText(label, variant: 'bodySmall', tone: 'secondary'),
            const SizedBox(width: AppSpacing.xs),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Icon(LucideIcons.x, size: 12, color: colors.text.tertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Filter Dropdown
// ---------------------------------------------------------------------------

/// Compact pill dropdown for a search filter (item type, search field,
/// etc — see [OpacScreen]'s use of two of these side by side). Same pill
/// visual language as [SearchInput] so they sit naturally together.
/// [hint] is shown when nothing's selected (`code: null`).
class _FilterDropdown extends StatelessWidget {
  final String hint;
  final List<({String? code, String label})> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.hint,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final shadow = cardShadowDecoration(colors);
    final backgroundColor =
        colors.isDark ? colors.background.tertiary : const Color(0xFFFFFFFF);
    final isFiltered = selected != null;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.ms),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: isFiltered ? colors.brand : colors.border,
          width: 1,
        ),
        boxShadow: shadow.boxShadow,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selected,
          isDense: true,
          isExpanded: true,
          icon: Icon(LucideIcons.chevron_down,
              size: 16, color: isFiltered ? colors.brand : colors.icon),
          dropdownColor: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          style: AppTypography.bodyBase.toTextStyle(
            color: isFiltered ? colors.brand : colors.text.primary,
          ),
          selectedItemBuilder: (context) => options
              .map((o) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      o.code == null ? hint : o.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          items: options
              .map(
                (o) => DropdownMenuItem<String?>(
                  value: o.code,
                  child: Text(o.label),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Book Card
// ---------------------------------------------------------------------------

class _BookCard extends StatefulWidget {
  final Biblio book;
  final SemanticColors colors;
  final BiblioSource biblioService;
  final VoidCallback onTap;
  final int index;

  const _BookCard({
    required this.book,
    required this.colors,
    required this.biblioService,
    required this.onTap,
    required this.index,
  });

  @override
  State<_BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<_BookCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    // Stagger the animation based on index.
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Generate a deterministic accent color from the book's title.
  Color _bookAccent() {
    final hue = (widget.book.title.hashCode % 360).abs().toDouble();
    return HSLColor.fromAHSL(1, hue, 0.55, 0.50).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final book = widget.book;
    final shadow = cardShadowDecoration(colors);
    final accent = _bookAccent();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: colors.isDark
                ? colors.background.tertiary
                : colors.background.secondary,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: shadow.border,
            boxShadow: shadow.boxShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Book cover (real image, falls back to icon) ---
                    Container(
                      width: 52,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _BookCoverImage(book: book, accent: accent, iconSize: 22),
                    ),

                    const SizedBox(width: AppSpacing.ms),

                    // --- Book info ---
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: AppTypography.bodyBase
                                .toTextStyle(color: colors.text.primary)
                                .copyWith(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (book.author != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                Icon(LucideIcons.user, size: 12,
                                    color: colors.text.tertiary),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    book.author!,
                                    style: AppTypography.bodySmall
                                        .toTextStyle(
                                            color: colors.text.secondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              if (book.displayYear != null)
                                _InfoChip(
                                  icon: LucideIcons.calendar,
                                  label: book.displayYear!,
                                  colors: colors,
                                ),
                              if (book.displayYear != null &&
                                  book.isbn != null)
                                const SizedBox(width: AppSpacing.sm),
                              if (book.isbn != null)
                                Flexible(
                                  child: _InfoChip(
                                    icon: LucideIcons.barcode,
                                    label: book.isbn!,
                                    colors: colors,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _AvailabilityBadge(
                            biblioService: widget.biblioService,
                            biblioId: book.biblioId,
                            colors: colors,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: AppSpacing.sm),

                    // --- Type badge + book bag toggle ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: colors.brand.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            book.itemTypeLabel,
                            style: AppTypography.caption
                                .toTextStyle(color: colors.brand)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ListenableBuilder(
                          listenable: BookBagService.instance,
                          builder: (context, _) {
                            final inBag = BookBagService.instance.contains(book.biblioId);
                            return GestureDetector(
                              onTap: () => BookBagService.instance.toggle(book.biblioId),
                              behavior: HitTestBehavior.opaque,
                              child: Icon(
                                inBag ? LucideIcons.shopping_bag : LucideIcons.plus,
                                size: 16,
                                color: inBag ? colors.brand : colors.icon,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Book Cover Image (real cover from ISBN, falls back to a gradient icon)
// ---------------------------------------------------------------------------

class _BookCoverImage extends StatelessWidget {
  final Biblio book;
  final Color accent;
  final double iconSize;

  const _BookCoverImage({required this.book, required this.accent, required this.iconSize});

  /// Koha ISBN fields sometimes carry multiple values or trailing
  /// qualifiers, e.g. `"0131103709 | 0131103628 (pbk.)"` — take the
  /// first token and strip everything but digits/X.
  String? get _cleanIsbn {
    final isbn = book.isbn;
    if (isbn == null || isbn.trim().isEmpty) return null;
    final firstToken = isbn.split(RegExp(r'[|,]')).first;
    final digits = firstToken.replaceAll(RegExp(r'[^0-9Xx]'), '');
    return digits.isEmpty ? null : digits;
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, accent.withValues(alpha: 0.7)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(LucideIcons.book_open, size: iconSize, color: Colors.white.withValues(alpha: 0.9)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isbn = _cleanIsbn;
    if (isbn == null) return _placeholder();
    // `default=false` makes OpenLibrary 404 when it has no real cover,
    // instead of silently serving a generic placeholder image — lets
    // errorBuilder correctly fall back to this app's own placeholder.
    return Image.network(
      'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg?default=false',
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null ? child : _placeholder(),
      errorBuilder: (context, error, stack) => _placeholder(),
    );
  }
}

// ---------------------------------------------------------------------------
//  Availability Badge (fetched per-card, real Koha item status)
// ---------------------------------------------------------------------------

class _AvailabilityBadge extends StatefulWidget {
  final BiblioSource biblioService;
  final int biblioId;
  final SemanticColors colors;

  const _AvailabilityBadge({
    required this.biblioService,
    required this.biblioId,
    required this.colors,
  });

  @override
  State<_AvailabilityBadge> createState() => _AvailabilityBadgeState();
}

class _AvailabilityBadgeState extends State<_AvailabilityBadge> {
  Availability? _availability;

  @override
  void initState() {
    super.initState();
    widget.biblioService.fetchAvailability(widget.biblioId).then((a) {
      if (mounted) setState(() => _availability = a);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final availability = _availability;

    if (availability == null) {
      return SizedBox(
        width: 70,
        height: 12,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.background.tertiary,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      );
    }

    final Color dotColor = switch (availability.status) {
      AvailabilityStatus.available => colors.success,
      AvailabilityStatus.checkedOut => colors.warning,
      AvailabilityStatus.noItems => colors.text.tertiary,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            availability.label,
            style: AppTypography.caption.toTextStyle(color: colors.text.secondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
//  Info Chip (year, ISBN, etc.)
// ---------------------------------------------------------------------------

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final SemanticColors colors;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.background.tertiary,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: colors.text.tertiary),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              style: AppTypography.caption
                  .toTextStyle(color: colors.text.tertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Book Detail Bottom Sheet
// ---------------------------------------------------------------------------

class _BookDetailSheet extends StatefulWidget {
  final Biblio book;
  final SemanticColors colors;
  final BiblioSource biblioService;

  const _BookDetailSheet({required this.book, required this.colors, required this.biblioService});

  @override
  State<_BookDetailSheet> createState() => _BookDetailSheetState();
}

class _BookDetailSheetState extends State<_BookDetailSheet> {
  final _circulation = CirculationService();
  bool _isPlacingHold = false;
  bool _holdPlaced = false;
  String? _holdError;
  Availability? _availability;

  @override
  void initState() {
    super.initState();
    widget.biblioService.fetchAvailability(widget.book.biblioId).then((a) {
      if (mounted) setState(() => _availability = a);
    });
  }

  Color _bookAccent() {
    final hue = (widget.book.title.hashCode % 360).abs().toDouble();
    return HSLColor.fromAHSL(1, hue, 0.55, 0.50).toColor();
  }

  Future<void> _placeHold() async {
    setState(() {
      _isPlacingHold = true;
      _holdError = null;
    });
    try {
      await _circulation.placeHold(
        biblioId: widget.book.biblioId,
      );
      if (!mounted) return;
      setState(() {
        _holdPlaced = true;
        _isPlacingHold = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _holdError = e.toString();
        _isPlacingHold = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final colors = widget.colors;
    final accent = _bookAccent();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.background.primary,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // --- Drag handle ---
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.ms),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // --- Hero header ---
                    Center(
                      child: Container(
                        width: 90,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _BookCoverImage(book: book, accent: accent, iconSize: 36),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // --- Title ---
                    Text(
                      book.title,
                      textAlign: TextAlign.center,
                      style: AppTypography.h5
                          .toTextStyle(color: colors.text.primary),
                    ),
                    if (book.subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        book.subtitle!,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyBase
                            .toTextStyle(color: colors.text.secondary),
                      ),
                    ],
                    if (book.author != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.pencil, size: 14,
                              color: colors.brand),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              book.author!,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyBase
                                  .toTextStyle(color: colors.brand)
                                  .copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    // --- Quick-info chips ---
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        if (_availability != null)
                          _DetailChip(
                            icon: switch (_availability!.status) {
                              AvailabilityStatus.available => LucideIcons.circle_check,
                              AvailabilityStatus.checkedOut => LucideIcons.clock,
                              AvailabilityStatus.noItems => LucideIcons.circle_x,
                            },
                            label: _availability!.label,
                            colors: colors,
                          ),
                        _DetailChip(
                          icon: LucideIcons.tag,
                          label: book.itemTypeLabel,
                          colors: colors,
                        ),
                        if (book.displayYear != null)
                          _DetailChip(
                            icon: LucideIcons.calendar,
                            label: book.displayYear!,
                            colors: colors,
                          ),
                        if (book.serial)
                          _DetailChip(
                            icon: LucideIcons.repeat,
                            label: 'Serial',
                            colors: colors,
                          ),
                        if (book.campusLabel != null)
                          _DetailChip(
                            icon: LucideIcons.map_pin,
                            label: book.campusLabel!,
                            colors: colors,
                          ),
                        for (final subject in book.subjects)
                          _DetailChip(
                            icon: LucideIcons.hash,
                            label: subject,
                            colors: colors,
                          ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // --- Detail rows ---
                    Container(
                      decoration: BoxDecoration(
                        color: colors.isDark
                            ? colors.background.tertiary
                            : colors.background.secondary,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: colors.border, width: 1),
                      ),
                      child: Column(
                        children: [
                          if (book.isbn != null)
                            _DetailRow(
                              icon: LucideIcons.barcode,
                              label: 'ISBN',
                              value: book.isbn!,
                              colors: colors,
                            ),
                          if (book.issn != null)
                            _DetailRow(
                              icon: LucideIcons.hash,
                              label: 'ISSN',
                              value: book.issn!,
                              colors: colors,
                              showTopBorder: book.isbn != null,
                            ),
                          if (book.publisher != null)
                            _DetailRow(
                              icon: LucideIcons.building,
                              label: 'Publisher',
                              value: book.publisher!,
                              colors: colors,
                              showTopBorder:
                                  book.isbn != null || book.issn != null,
                            ),
                          if (book.publicationPlace != null)
                            _DetailRow(
                              icon: LucideIcons.map_pin,
                              label: 'Place',
                              value: book.publicationPlace!,
                              colors: colors,
                              showTopBorder: true,
                            ),
                          if (book.editionStatement != null)
                            _DetailRow(
                              icon: LucideIcons.layers,
                              label: 'Edition',
                              value: book.editionStatement!,
                              colors: colors,
                              showTopBorder: true,
                            ),
                          if (book.pages != null)
                            _DetailRow(
                              icon: LucideIcons.file_text,
                              label: 'Pages',
                              value: book.pages!,
                              colors: colors,
                              showTopBorder: true,
                            ),
                          if (book.volume != null)
                            _DetailRow(
                              icon: LucideIcons.book_copy,
                              label: 'Volume',
                              value: book.volume!,
                              colors: colors,
                              showTopBorder: true,
                            ),
                          if (book.seriesTitle != null)
                            _DetailRow(
                              icon: LucideIcons.list,
                              label: 'Series',
                              value: book.seriesTitle!,
                              colors: colors,
                              showTopBorder: true,
                            ),
                          if (book.ean != null)
                            _DetailRow(
                              icon: LucideIcons.barcode,
                              label: 'EAN',
                              value: book.ean!,
                              colors: colors,
                              showTopBorder: true,
                            ),
                          // Always show at least the catalog ID.
                          _DetailRow(
                            icon: LucideIcons.database,
                            label: 'Catalog ID',
                            value: '#${book.biblioId}',
                            colors: colors,
                            showTopBorder: true,
                          ),
                        ],
                      ),
                    ),

                    // --- Abstract / notes ---
                    if (book.abstract_ != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Abstract',
                        style: AppTypography.bodyBase
                            .toTextStyle(color: colors.text.primary)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        book.abstract_!,
                        style: AppTypography.bodySmall
                            .toTextStyle(color: colors.text.secondary),
                      ),
                    ],
                    if (book.notes != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Notes',
                        style: AppTypography.bodyBase
                            .toTextStyle(color: colors.text.primary)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        book.notes!,
                        style: AppTypography.bodySmall
                            .toTextStyle(color: colors.text.secondary),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),

              // --- Place Hold action bar ---
              Container(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md + MediaQuery.paddingOf(context).bottom,
                ),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.border, width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_holdError != null) ...[
                      Text(
                        _holdError!,
                        style: AppTypography.bodySmall.toTextStyle(color: colors.error),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: _holdPlaced ? 'Hold Placed' : 'Place Hold',
                            icon: _holdPlaced ? LucideIcons.circle_check : LucideIcons.bookmark,
                            isLoading: _isPlacingHold,
                            onPressed: _holdPlaced ? null : _placeHold,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ListenableBuilder(
                          listenable: BookBagService.instance,
                          builder: (context, _) {
                            final inBag = BookBagService.instance.contains(book.biblioId);
                            return SizedBox(
                              width: 52,
                              child: AppButton(
                                label: '',
                                icon: inBag ? LucideIcons.shopping_bag : LucideIcons.plus,
                                variant: 'secondary',
                                fullWidth: false,
                                onPressed: () => BookBagService.instance.toggle(book.biblioId),
                              ),
                            );
                          },
                        ),
                        // Watching only makes sense while the book is
                        // actually checked out — nothing to wait for
                        // otherwise (available now, or no items exist at
                        // all in the catalog record).
                        if (_availability?.status == AvailabilityStatus.checkedOut) ...[
                          const SizedBox(width: AppSpacing.sm),
                          ListenableBuilder(
                            listenable: WatchlistService.instance,
                            builder: (context, _) {
                              final watching = WatchlistService.instance.isWatching(book.biblioId);
                              return SizedBox(
                                width: 52,
                                child: AppButton(
                                  label: '',
                                  icon: watching ? LucideIcons.bell_ring : LucideIcons.bell,
                                  variant: 'secondary',
                                  fullWidth: false,
                                  onPressed: () => watching
                                      ? WatchlistService.instance.unwatch(book.biblioId)
                                      : WatchlistService.instance.watch(
                                          biblioId: book.biblioId,
                                          title: book.title,
                                          author: book.author,
                                        ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
//  Detail Chip (used in bottom sheet header area)
// ---------------------------------------------------------------------------

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final SemanticColors colors;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.ms,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: colors.brand.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.brand),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.bodySmall
                .toTextStyle(color: colors.brand)
                .copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Detail Row (used inside the info container in the bottom sheet)
// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final SemanticColors colors;
  final bool showTopBorder;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    this.showTopBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.ms,
      ),
      decoration: BoxDecoration(
        border: showTopBorder
            ? Border(top: BorderSide(color: colors.border, width: 0.5))
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.text.tertiary),
          const SizedBox(width: AppSpacing.ms),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTypography.bodySmall
                  .toTextStyle(color: colors.text.tertiary)
                  .copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall
                  .toTextStyle(color: colors.text.primary),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}