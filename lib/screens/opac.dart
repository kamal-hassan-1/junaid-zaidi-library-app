import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../models/biblio.dart';
import '../services/biblio_service.dart';
import '../theme/theme.dart';
import '../widgets/ui.dart';

/// OPAC (Online Public Access Catalog) — full catalog search screen.
///
/// Reached from the "OPAC" resource card on the Home tab, or by
/// submitting a query from the Home tab's search box (in which case
/// [initialQuery] is pre-filled and searched immediately).
class OpacScreen extends StatefulWidget {
  const OpacScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<OpacScreen> createState() => _OpacScreenState();
}

class _OpacScreenState extends State<OpacScreen> with TickerProviderStateMixin {
  late String _query = widget.initialQuery ?? '';
  bool _isLoading = false;
  String? _errorMessage;
  List<Biblio> _allBooks = const [];
  List<Biblio> _filteredBooks = const [];

  final BiblioService _biblioService = BiblioService();

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final books = await _biblioService.fetchAll();
      if (!mounted) return;
      setState(() {
        _allBooks = books;
        _filteredBooks = _applyFilter(books, _query);
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

  List<Biblio> _applyFilter(List<Biblio> books, String query) {
    if (query.trim().isEmpty) return books;
    final lower = query.toLowerCase();
    return books.where((b) {
      return b.title.toLowerCase().contains(lower) ||
          (b.author ?? '').toLowerCase().contains(lower) ||
          (b.isbn ?? '').toLowerCase().contains(lower);
    }).toList();
  }

  void _onSearch(String query) {
    setState(() {
      _query = query;
      _filteredBooks = _applyFilter(_allBooks, query);
    });
  }

  void _showBookDetails(BuildContext context, Biblio book) {
    final colors = useTheme(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BookDetailSheet(book: book, colors: colors),
    );
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
              onClear: () => _onSearch(''),
              onSubmitted: _onSearch,
              placeholder: 'Search by title, author, or ISBN...',
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
                      _query.trim().isEmpty
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
              _query.trim().isEmpty
                  ? 'No books in the catalog yet'
                  : 'No results for "$_query"',
              style: AppTypography.bodyBase
                  .toTextStyle(color: colors.text.primary)
                  .copyWith(fontWeight: FontWeight.w500),
            ),
            if (_query.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Try a different search term.',
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
          onTap: () => _showBookDetails(context, book),
          index: index,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
//  Book Card
// ---------------------------------------------------------------------------

class _BookCard extends StatefulWidget {
  final Biblio book;
  final SemanticColors colors;
  final VoidCallback onTap;
  final int index;

  const _BookCard({
    required this.book,
    required this.colors,
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
                    // --- Book icon / cover placeholder ---
                    Container(
                      width: 52,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent,
                            accent.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        LucideIcons.book_open,
                        size: 22,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
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
                        ],
                      ),
                    ),

                    const SizedBox(width: AppSpacing.sm),

                    // --- Type badge ---
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

class _BookDetailSheet extends StatelessWidget {
  final Biblio book;
  final SemanticColors colors;

  const _BookDetailSheet({required this.book, required this.colors});

  Color _bookAccent() {
    final hue = (book.title.hashCode % 360).abs().toDouble();
    return HSLColor.fromAHSL(1, hue, 0.55, 0.50).toColor();
  }

  @override
  Widget build(BuildContext context) {
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
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accent,
                              accent.withValues(alpha: 0.65),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          LucideIcons.book_open,
                          size: 36,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
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