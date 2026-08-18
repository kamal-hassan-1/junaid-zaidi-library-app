import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:share_plus/share_plus.dart';

import '../config/api_constants.dart';
import '../models/biblio.dart';
import '../services/biblio_service.dart';
import '../services/book_bag_service.dart';
import '../services/circulation_service.dart';
import '../services/mock_biblio_service.dart';
import '../theme/theme.dart';
import '../widgets/ui.dart';

/// Book Bag — mirrors the real OPAC website's cart ("Add to cart"):
/// collect titles while browsing, then act on them together. Currently
/// supports bulk hold placement; removing an item is per-row.
class BookBagScreen extends StatefulWidget {
  const BookBagScreen({super.key});

  @override
  State<BookBagScreen> createState() => _BookBagScreenState();
}

class _BookBagScreenState extends State<BookBagScreen> {
  final _bag = BookBagService.instance;
  final BiblioSource _biblioService =
      ApiConstants.useMockKohaBackend ? MockBiblioService() : BiblioService();
  final _circulation = CirculationService();

  bool _isLoading = true;
  List<Biblio> _books = [];
  bool _isPlacingHolds = false;
  String? _bulkResultMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    await _bag.ensureLoaded();
    final results = await Future.wait(_bag.ids.map(_biblioService.fetchOne));
    if (!mounted) return;
    setState(() {
      _books = results.whereType<Biblio>().toList();
      _isLoading = false;
    });
  }

  Future<void> _remove(Biblio book) async {
    await _bag.remove(book.biblioId);
    if (!mounted) return;
    setState(() => _books.removeWhere((b) => b.biblioId == book.biblioId));
  }

  Future<void> _clearAll() async {
    await _bag.clear();
    if (!mounted) return;
    setState(() => _books = []);
  }

  Future<void> _placeAllHolds() async {
    setState(() {
      _isPlacingHolds = true;
      _bulkResultMessage = null;
    });
    var succeeded = 0;
    var failed = 0;
    for (final book in _books) {
      try {
        await _circulation.placeHold(biblioId: book.biblioId);
        succeeded++;
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    setState(() {
      _isPlacingHolds = false;
      _bulkResultMessage = failed == 0
          ? 'Placed $succeeded hold${succeeded == 1 ? '' : 's'}.'
          : 'Placed $succeeded hold${succeeded == 1 ? '' : 's'}, $failed failed (already held, or unavailable).';
    });
  }

  /// Hands the bag's contents off to the OS share sheet as plain text —
  /// e.g. for a group project reading list over WhatsApp/email. Purely
  /// local formatting, no Koha call involved.
  Future<void> _share() async {
    final buffer = StringBuffer('My Book Bag — Junaid Zaidi Library\n\n');
    for (var i = 0; i < _books.length; i++) {
      final book = _books[i];
      buffer.write('${i + 1}. ${book.title}');
      if (book.author != null) buffer.write(' — ${book.author}');
      buffer.writeln();
    }
    await SharePlus.instance.share(
      ShareParams(text: buffer.toString(), subject: 'My Book Bag'),
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
        title: const Heading(level: 5, text: 'Book Bag'),
        actions: [
          if (_books.isNotEmpty) ...[
            IconButton(
              icon: Icon(LucideIcons.share_2, size: 20, color: colors.icon),
              onPressed: _share,
              tooltip: 'Share as a list',
            ),
            TextButton(
              onPressed: _clearAll,
              child: Text(
                'Clear',
                style: AppTypography.bodyBase.toTextStyle(color: colors.error),
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: ScreenContainer(
        scroll: false,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: colors.brand))
            : _books.isEmpty
                ? _buildEmpty(colors)
                : _buildList(colors),
      ),
    );
  }

  Widget _buildEmpty(SemanticColors colors) {
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
            child: Icon(LucideIcons.shopping_bag, size: 28, color: colors.icon),
          ),
          const SizedBox(height: AppSpacing.md),
          AppText('Your book bag is empty', variant: 'bodyBase', tone: 'secondary'),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: AppText(
              'Add books while browsing OPAC to collect them here, then place holds on all of them at once.',
              variant: 'bodySmall',
              tone: 'tertiary',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(SemanticColors colors) {
    final shadow = cardShadowDecoration(colors);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_bulkResultMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppText(_bulkResultMessage!, variant: 'bodySmall', tone: 'secondary'),
          ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.background.secondary,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: shadow.border,
              boxShadow: shadow.boxShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView.builder(
              itemCount: _books.length,
              itemBuilder: (context, index) {
                final book = _books[index];
                return ListRow(
                  icon: LucideIcons.book_open,
                  label: book.title,
                  secondaryLabel: book.author,
                  showChevron: false,
                  showDivider: index != _books.length - 1,
                  badge: GestureDetector(
                    onTap: () => _remove(book),
                    behavior: HitTestBehavior.opaque,
                    child: Icon(LucideIcons.x, size: 18, color: colors.icon),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Place Holds on All (${_books.length})',
          isLoading: _isPlacingHolds,
          onPressed: _placeAllHolds,
        ),
      ],
    );
  }
}
