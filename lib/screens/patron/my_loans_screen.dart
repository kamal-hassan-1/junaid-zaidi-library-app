import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../models/loan.dart';
import '../../repositories/patron_repository.dart';
import '../../repositories/repository_scope.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

enum _LoansView { loading, content, empty, error }

/// What the student currently has out, and when each item is due.
///
/// Reached from the More tab's "My Library" section, behind the same
/// authentication check the OPAC card uses — see `MoreScreen`. Pushed onto the
/// More tab's Navigator, which supplies the AppBar, so this screen renders
/// content only.
class MyLoansScreen extends StatefulWidget {
  /// Optional only for focused widget tests. Production callers leave this null
  /// and get the repository from [RepositoryScope].
  final PatronRepository? repository;

  const MyLoansScreen({super.key, this.repository});

  @override
  State<MyLoansScreen> createState() => _MyLoansScreenState();
}

class _MyLoansScreenState extends State<MyLoansScreen> {
  late final PatronRepository _patron;

  _LoansView _view = _LoansView.loading;
  List<Loan> _loans = const [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _patron = widget.repository ?? RepositoryScope.of(context).patron;
    _load();
  }

  Future<void> _load() async {
    setState(() => _view = _LoansView.loading);

    try {
      final loans = await _patron.getLoans();
      if (!mounted) return;
      setState(() {
        _loans = loans;
        // An empty account is a normal answer, not a failure — hence a
        // separate view rather than an error.
        _view = loans.isEmpty ? _LoansView.empty : _LoansView.content;
      });
    } on PatronException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _view = _LoansView.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _view = _LoansView.error;
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
      case _LoansView.loading:
        return const ListSkeleton(rows: 3);
      case _LoansView.empty:
        return const _LoansEmpty();
      case _LoansView.error:
        return _LoansError(message: _errorMessage, onRetry: _load);
      case _LoansView.content:
        return _LoansList(loans: _loans);
    }
  }
}

class _LoansList extends StatelessWidget {
  final List<Loan> loans;

  const _LoansList({required this.loans});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          '${loans.length} ${loans.length == 1 ? 'item' : 'items'} on loan',
          variant: 'bodySmall',
          tone: 'secondary',
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < loans.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _LoanCard(loan: loans[i]),
        ],
      ],
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Loan loan;

  const _LoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final status = loan.status;

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
                    AppText(loan.title, variant: 'bodyBase', maxLines: 2),
                    if (loan.author != null && loan.author!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      AppText(
                        'by ${loan.author!}',
                        variant: 'bodySmall',
                        tone: 'secondary',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.ms),
              AppBadge(label: status.label, intent: status.badgeIntent),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppDivider(),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 16,
                          color: colors.icon,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        AppText(
                          'Due ${loan.dueDateLabel}',
                          variant: 'bodySmall',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      loan.dueDescription,
                      variant: 'caption',
                      // The one place status earns a colour outside the badge:
                      // being late is the whole point of the row.
                      tone: status == LoanStatus.overdue ? 'error' : 'secondary',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.ms),
              const _RenewAction(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Renewals need an endpoint that does not exist, so the button is present but
/// inert, with the same "Coming soon" wording the More tab's unfinished items
/// use. Disabled rather than hidden so the action's eventual home is obvious.
class _RenewAction extends StatelessWidget {
  const _RenewAction();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AppButton(
          label: 'Renew',
          variant: 'secondary',
          fullWidth: false,
          onPressed: null,
        ),
        SizedBox(height: AppSpacing.xs),
        AppText('Coming soon', variant: 'caption', tone: 'tertiary'),
      ],
    );
  }
}

class _LoansEmpty extends StatelessWidget {
  const _LoansEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: EmptyState(
        icon: LucideIcons.book_open,
        title: 'Nothing on loan',
        description:
            'Books you borrow from the library will appear here, along with '
            'when they are due back.',
      ),
    );
  }
}

class _LoansError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoansError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: ErrorState(
        title: 'Loans unavailable',
        description: message,
        onRetry: onRetry,
      ),
    );
  }
}
