import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../models/hold.dart';
import '../../repositories/patron_repository.dart';
import '../../repositories/repository_scope.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

enum _HoldsView { loading, content, empty, error }

/// Reservations the student is waiting on, and where to collect them.
///
/// Sibling of `MyLoansScreen`: same states, same card anatomy, same place in
/// the More tab behind the authentication check.
class MyHoldsScreen extends StatefulWidget {
  /// Optional only for focused widget tests. Production callers leave this null
  /// and get the repository from [RepositoryScope].
  final PatronRepository? repository;

  const MyHoldsScreen({super.key, this.repository});

  @override
  State<MyHoldsScreen> createState() => _MyHoldsScreenState();
}

class _MyHoldsScreenState extends State<MyHoldsScreen> {
  late final PatronRepository _patron;

  _HoldsView _view = _HoldsView.loading;
  List<Hold> _holds = const [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _patron = widget.repository ?? RepositoryScope.of(context).patron;
    _load();
  }

  Future<void> _load() async {
    setState(() => _view = _HoldsView.loading);

    try {
      final holds = await _patron.getHolds();
      if (!mounted) return;
      setState(() {
        _holds = holds;
        _view = holds.isEmpty ? _HoldsView.empty : _HoldsView.content;
      });
    } on PatronException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _view = _HoldsView.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _view = _HoldsView.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenContainer(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildBody()],
      ),
    );
  }

  Widget _buildBody() {
    switch (_view) {
      case _HoldsView.loading:
        return const ListSkeleton(rows: 3);
      case _HoldsView.empty:
        return const _HoldsEmpty();
      case _HoldsView.error:
        return _HoldsError(message: _errorMessage, onRetry: _load);
      case _HoldsView.content:
        return _HoldsList(holds: _holds);
    }
  }
}

class _HoldsList extends StatelessWidget {
  final List<Hold> holds;

  const _HoldsList({required this.holds});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          '${holds.length} ${holds.length == 1 ? 'hold' : 'holds'} placed',
          variant: 'bodySmall',
          tone: 'secondary',
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < holds.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _HoldCard(hold: holds[i]),
        ],
      ],
    );
  }
}

class _HoldCard extends StatelessWidget {
  final Hold hold;

  const _HoldCard({required this.hold});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(hold.title, variant: 'bodyBase', maxLines: 2),
                    if (hold.author != null && hold.author!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      AppText(
                        'by ${hold.author!}',
                        variant: 'bodySmall',
                        tone: 'secondary',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.ms),
              AppBadge(
                label: hold.status.label,
                intent: hold.status.badgeIntent,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppDivider(),
          const SizedBox(height: AppSpacing.md),
          _HoldDetailLine(icon: LucideIcons.users, text: hold.queueLabel),
          const SizedBox(height: AppSpacing.sm),
          _HoldDetailLine(
            icon: LucideIcons.map_pin,
            text: 'Pickup at ${hold.pickupLibrary}',
          ),
        ],
      ),
    );
  }
}

class _HoldDetailLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HoldDetailLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colors.icon),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: AppText(text, variant: 'bodySmall', tone: 'secondary'),
        ),
      ],
    );
  }
}

class _HoldsEmpty extends StatelessWidget {
  const _HoldsEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: EmptyState(
        icon: LucideIcons.bookmark,
        title: 'No holds placed',
        description:
            'Reserve a book that is currently out and it will appear here with '
            'your place in the queue.',
      ),
    );
  }
}

class _HoldsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HoldsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: ErrorState(
        title: 'Holds unavailable',
        description: message,
        onRetry: onRetry,
      ),
    );
  }
}
