import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../models/checkout.dart';
import '../../models/hold.dart';
import '../../navigation/auth_scope.dart';
import '../../services/circulation_service.dart';
import '../../services/koha_api_client.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

/// My Checkouts & Holds — see [CirculationService]. Shows what the
/// student currently has borrowed (with a renew action) and what they've
/// placed a hold on (with a cancel action). Holds are also placeable from
/// OPAC's book detail sheet — this screen is where they're managed.
class MyBooksScreen extends StatefulWidget {
  const MyBooksScreen({super.key});

  @override
  State<MyBooksScreen> createState() => _MyBooksScreenState();
}

class _MyBooksScreenState extends State<MyBooksScreen> {
  final _circulation = CirculationService();

  bool _isLoading = true;
  String? _errorMessage;
  List<Checkout> _checkouts = const [];
  List<Hold> _holds = const [];

  /// checkoutId/holdId currently mid-action, so only that row shows a
  /// spinner instead of the whole screen.
  final Set<int> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _circulation.fetchCheckouts(),
        _circulation.fetchHolds(),
      ]);
      if (!mounted) return;
      setState(() {
        _checkouts = results[0] as List<Checkout>;
        _holds = results[1] as List<Hold>;
        _isLoading = false;
      });
    } on KohaSessionExpiredException {
      if (mounted) await AuthScope.of(context).onLogout();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _renew(Checkout checkout) async {
    setState(() => _busyIds.add(checkout.checkoutId));
    try {
      final renewed = await _circulation.renewCheckout(checkout.checkoutId);
      if (!mounted) return;
      setState(() {
        _checkouts = [
          for (final c in _checkouts)
            if (c.checkoutId == renewed.checkoutId) renewed else c,
        ];
      });
    } on KohaSessionExpiredException {
      if (mounted) await AuthScope.of(context).onLogout();
    } catch (e) {
      if (mounted) _showActionError(e);
    } finally {
      if (mounted) setState(() => _busyIds.remove(checkout.checkoutId));
    }
  }

  Future<void> _cancelHold(Hold hold) async {
    setState(() => _busyIds.add(hold.holdId));
    try {
      await _circulation.cancelHold(hold.holdId);
      if (!mounted) return;
      setState(() => _holds = _holds.where((h) => h.holdId != hold.holdId).toList());
    } on KohaSessionExpiredException {
      if (mounted) await AuthScope.of(context).onLogout();
    } catch (e) {
      if (mounted) _showActionError(e);
    } finally {
      if (mounted) setState(() => _busyIds.remove(hold.holdId));
    }
  }

  void _showActionError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
  }

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final isGuest = AuthScope.of(context).isGuest;

    if (isGuest) {
      return ScreenContainer(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.intents.info.light.bg,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(LucideIcons.book_marked, size: 32, color: colors.brand),
              ),
              const SizedBox(height: AppSpacing.lg),
              Heading(level: 4, text: "You're browsing as a guest", textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              AppText(
                'Sign up or log in to see what you\'ve borrowed and reserved.',
                variant: 'bodyBase',
                tone: 'secondary',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Sign Up / Sign In',
                onPressed: () => AuthScope.of(context).onLogout(),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return ScreenContainer(
        child: Center(child: CircularProgressIndicator(color: colors.brand)),
      );
    }

    if (_errorMessage != null) {
      return ScreenContainer(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.wifi_off, size: 32, color: colors.error),
              const SizedBox(height: AppSpacing.md),
              AppText(_errorMessage!, variant: 'bodyBase', tone: 'secondary', textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: 'Retry', fullWidth: false, onPressed: _load),
            ],
          ),
        ),
      );
    }

    return ScreenContainer(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Heading(level: 5, text: 'Checkouts'),
          const SizedBox(height: AppSpacing.ms),
          if (_checkouts.isEmpty)
            _emptyRow(colors, "You don't have anything checked out.")
          else
            _groupedList(colors, [
              for (var i = 0; i < _checkouts.length; i++)
                _CheckoutRow(
                  checkout: _checkouts[i],
                  colors: colors,
                  isBusy: _busyIds.contains(_checkouts[i].checkoutId),
                  showDivider: i != _checkouts.length - 1,
                  onRenew: () => _renew(_checkouts[i]),
                ),
            ]),
          const SizedBox(height: AppSpacing.xl),
          Heading(level: 5, text: 'Holds'),
          const SizedBox(height: AppSpacing.ms),
          if (_holds.isEmpty)
            _emptyRow(colors, "You don't have any holds. Place one from a book's details in OPAC.")
          else
            _groupedList(colors, [
              for (var i = 0; i < _holds.length; i++)
                _HoldRow(
                  hold: _holds[i],
                  colors: colors,
                  isBusy: _busyIds.contains(_holds[i].holdId),
                  showDivider: i != _holds.length - 1,
                  onCancel: () => _cancelHold(_holds[i]),
                ),
            ]),
        ],
      ),
    );
  }

  Widget _emptyRow(SemanticColors colors, String message) {
    return _groupedList(colors, [
      ListRow(
        icon: LucideIcons.info,
        label: message,
        showChevron: false,
        showDivider: false,
      ),
    ]);
  }

  Widget _groupedList(SemanticColors colors, List<Widget> rows) {
    final shadow = cardShadowDecoration(colors);
    return Container(
      decoration: BoxDecoration(
        color: colors.background.secondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: shadow.border,
        boxShadow: shadow.boxShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

class _CheckoutRow extends StatelessWidget {
  final Checkout checkout;
  final SemanticColors colors;
  final bool isBusy;
  final bool showDivider;
  final VoidCallback onRenew;

  const _CheckoutRow({
    required this.checkout,
    required this.colors,
    required this.isBusy,
    required this.showDivider,
    required this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    final dueDate = checkout.dueDate;
    final dueLabel = dueDate == null
        ? 'Due date unknown'
        : checkout.isOverdue
            ? 'Overdue since ${_formatDate(dueDate)}'
            : 'Due ${_formatDate(dueDate)}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.ms, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        border: showDivider ? Border(bottom: BorderSide(color: colors.border)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(checkout.title ?? 'Untitled', variant: 'bodyBase', tone: 'primary'),
                if (checkout.author != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppText(checkout.author!, variant: 'bodySmall', tone: 'secondary'),
                ],
                const SizedBox(height: AppSpacing.xs),
                AppBadge(
                  label: dueLabel,
                  intent: checkout.isOverdue ? 'error' : 'neutral',
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.ms),
          SizedBox(
            width: 96,
            child: AppButton(
              // Koha doesn't expose whether a checkout is renewable ahead
              // of time (confirmed — not on the real GET response), so
              // the button is always enabled; a rejection surfaces as a
              // normal error via [_showActionError] instead.
              label: 'Renew',
              variant: 'secondary',
              fullWidth: true,
              isLoading: isBusy,
              onPressed: onRenew,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _HoldRow extends StatelessWidget {
  final Hold hold;
  final SemanticColors colors;
  final bool isBusy;
  final bool showDivider;
  final VoidCallback onCancel;

  const _HoldRow({
    required this.hold,
    required this.colors,
    required this.isBusy,
    required this.showDivider,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.ms, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        border: showDivider ? Border(bottom: BorderSide(color: colors.border)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(hold.title ?? 'Untitled', variant: 'bodyBase', tone: 'primary'),
                if (hold.author != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppText(hold.author!, variant: 'bodySmall', tone: 'secondary'),
                ],
                const SizedBox(height: AppSpacing.xs),
                AppBadge(
                  label: hold.statusLabel,
                  intent: hold.isWaiting ? 'success' : 'info',
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.ms),
          SizedBox(
            width: 96,
            child: AppButton(
              label: 'Cancel',
              variant: 'secondary',
              fullWidth: true,
              isLoading: isBusy,
              onPressed: onCancel,
            ),
          ),
        ],
      ),
    );
  }
}
