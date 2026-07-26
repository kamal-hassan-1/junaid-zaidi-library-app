import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../models/catalog_holding.dart';
import '../../models/catalog_item.dart';
import '../../services/opac_service.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

enum _BookDetailView { loading, content, notFound, error }

/// Native catalog record view. It deliberately presents only the fields a
/// student needs; Koha's MARC and ISBD views remain backend concerns.
class BookDetailScreen extends StatefulWidget {
  final String biblioId;

  /// Optional only for focused widget tests. Production callers use the
  /// default [OpacService], matching the app's existing service pattern.
  final OpacService? service;

  const BookDetailScreen({
    super.key,
    required this.biblioId,
    this.service,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late final OpacService _opacService;

  _BookDetailView _view = _BookDetailView.loading;
  CatalogItem? _book;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _opacService = widget.service ?? OpacService();
    _loadBook();
  }

  Future<void> _loadBook() async {
    setState(() => _view = _BookDetailView.loading);

    try {
      final book = await _opacService.getBiblio(widget.biblioId);
      if (!mounted) return;
      setState(() {
        _book = book;
        _view = _BookDetailView.content;
      });
    } on OpacNotFoundException {
      if (!mounted) return;
      setState(() => _view = _BookDetailView.notFound);
    } on OpacException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _view = _BookDetailView.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _view = _BookDetailView.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenContainer(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BackButton(),
          const SizedBox(height: AppSpacing.lg),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_view) {
      case _BookDetailView.loading:
        return const _BookDetailLoading();
      case _BookDetailView.notFound:
        return const _BookNotFound();
      case _BookDetailView.error:
        return _BookDetailError(
          message: _errorMessage,
          onRetry: _loadBook,
        );
      case _BookDetailView.content:
        return _BookDetailContent(book: _book!);
    }
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        label: 'Back to catalog search',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.arrow_left, size: 20, color: colors.icon),
            const SizedBox(width: AppSpacing.xs),
            const AppText(
              'Back',
              variant: 'bodyBase',
              tone: 'secondary',
            ),
          ],
        ),
      ),
    );
  }
}

class _BookDetailLoading extends StatelessWidget {
  const _BookDetailLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListSkeleton(rows: 2),
        SizedBox(height: AppSpacing.lg),
        ListSkeleton(rows: 3),
      ],
    );
  }
}

class _BookDetailContent extends StatelessWidget {
  final CatalogItem book;

  const _BookDetailContent({required this.book});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BookHero(book: book),
        const SizedBox(height: AppSpacing.lg),
        const _SectionHeading('Book information'),
        _BookMetadata(book: book),
        const SizedBox(height: AppSpacing.lg),
        const _SectionHeading('Holdings'),
        _HoldingsSection(book: book),

        // Reserved for Phase 3 actions such as Place Hold. Keeping this
        // breathing room now prevents the final holding from feeling
        // attached to future buttons when that action area is introduced.
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _BookHero extends StatelessWidget {
  final CatalogItem book;

  const _BookHero({required this.book});

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 72,
                decoration: BoxDecoration(
                  color: withOpacity(colors.brand, 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.book_open,
                  size: 26,
                  color: colors.brand,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Heading(level: 5, text: book.title),
                    if (book.author != null && book.author!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      AppText(
                        'by ${book.author!}',
                        variant: 'bodyBase',
                        tone: 'secondary',
                      ),
                    ],
                    const SizedBox(height: AppSpacing.ms),
                    AppBadge(
                      label: book.availabilityLabel,
                      intent: book.availabilityBadgeIntent,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppDivider(),
          const SizedBox(height: AppSpacing.md),
          AppText(
            _availabilitySummary(book),
            variant: 'bodySmall',
            tone: 'secondary',
          ),
        ],
      ),
    );
  }

  String _availabilitySummary(CatalogItem book) {
    if (book.totalCount == 0) {
      return 'No physical copies are currently listed.';
    }

    final copyNoun = book.totalCount == 1 ? 'copy' : 'copies';
    return '${book.availableCount} of ${book.totalCount} $copyNoun available';
  }
}

class _SectionHeading extends StatelessWidget {
  final String text;

  const _SectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Heading(level: 5, tone: 'tertiary', text: text),
    );
  }
}

class _BookMetadata extends StatelessWidget {
  final CatalogItem book;

  const _BookMetadata({required this.book});

  @override
  Widget build(BuildContext context) {
    final fields = <(String, String)>[
      ('Author', _valueOrFallback(book.author)),
      ('ISBN', _valueOrFallback(book.isbn)),
      ('Publication year', book.year?.toString() ?? 'Not listed'),
      ('Item type', _valueOrFallback(book.itemType)),
    ];

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < fields.length; i++)
            _MetadataRow(
              label: fields[i].$1,
              value: fields[i].$2,
              showDivider: i < fields.length - 1,
            ),
        ],
      ),
    );
  }

  String _valueOrFallback(String? value) {
    return value == null || value.isEmpty ? 'Not listed' : value;
  }
}

class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const _MetadataRow({
    required this.label,
    required this.value,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.ms,
      ),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.border))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: AppText(
              label,
              variant: 'bodySmall',
              tone: 'secondary',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppText(
              value,
              variant: 'bodyBase',
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldingsSection extends StatelessWidget {
  final CatalogItem book;

  const _HoldingsSection({required this.book});

  @override
  Widget build(BuildContext context) {
    final holdings = book.holdings ?? const <CatalogHolding>[];

    if (holdings.isEmpty) {
      return const AppCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: AppText(
            'No physical copies are currently listed for this title.',
            variant: 'bodySmall',
            tone: 'secondary',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < holdings.length; i++)
            _HoldingRow(
              holding: holdings[i],
              showDivider: i < holdings.length - 1,
            ),
        ],
      ),
    );
  }
}

class _HoldingRow extends StatelessWidget {
  final CatalogHolding holding;
  final bool showDivider;

  const _HoldingRow({
    required this.holding,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.border))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppText(
                  holding.library,
                  variant: 'bodyBase',
                ),
              ),
              const SizedBox(width: AppSpacing.ms),
              AppBadge(
                label: holding.availability.label,
                intent: holding.availability.badgeIntent,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(LucideIcons.tag, size: 16, color: colors.icon),
              const SizedBox(width: AppSpacing.xs),
              AppText(
                'Call number: ${holding.callNumber}',
                variant: 'bodySmall',
                tone: 'secondary',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookNotFound extends StatelessWidget {
  const _BookNotFound();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: EmptyState(
        icon: LucideIcons.book_x,
        title: 'Book not found',
        description:
            'This catalog record may have been removed or is no longer available.',
      ),
    );
  }
}

class _BookDetailError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _BookDetailError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: ErrorState(
        title: 'Book unavailable',
        description: message,
        onRetry: onRetry,
      ),
    );
  }
}
