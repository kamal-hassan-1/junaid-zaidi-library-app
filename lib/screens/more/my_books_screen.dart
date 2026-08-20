import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../config/api_constants.dart';
import '../../models/checkout.dart';
import '../../models/hold.dart';
import '../../models/patron_account.dart';
import '../../navigation/auth_scope.dart';
import '../../services/biblio_service.dart';
import '../../services/circulation_service.dart';
import '../../services/mock_biblio_service.dart';
import '../../services/notification_service.dart';
import '../../services/watchlist_service.dart';
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
  final BiblioSource _biblioService =
      ApiConstants.useMockKohaBackend ? MockBiblioService() : BiblioService();

  bool _isLoading = true;
  String? _errorMessage;
  List<Checkout> _checkouts = const [];
  List<Hold> _holds = const [];

  /// Balance/limit are a supplementary summary, not core to this screen's
  /// job (checkouts/holds) — fetched separately so a failure here (or
  /// just slower) never blocks the main list from showing.
  PatronAccount? _account;
  int? _checkoutLimit;

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
      unawaited(NotificationService.instance.scheduleDueDateReminders(_checkouts));
      unawaited(_loadAccountSummary());
      unawaited(WatchlistService.instance.checkForAvailabilityChanges(_biblioService));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAccountSummary() async {
    try {
      final results = await Future.wait([
        _circulation.fetchAccount(),
        _circulation.fetchCheckoutLimit(),
      ]);
      if (!mounted) return;
      setState(() {
        _account = results[0] as PatronAccount;
        _checkoutLimit = results[1] as int?;
      });
    } catch (_) {
      // Silent — see field docs above. Checkouts/holds already loaded fine.
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
      unawaited(NotificationService.instance.scheduleDueDateReminders(_checkouts));
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
          if (_account != null) ...[
            _AccountSummaryCard(
              account: _account!,
              checkoutCount: _checkouts.length,
              checkoutLimit: _checkoutLimit,
              colors: colors,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
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
          const SizedBox(height: AppSpacing.xl),
          Heading(level: 5, text: 'Watching'),
          const SizedBox(height: AppSpacing.ms),
          ListenableBuilder(
            listenable: WatchlistService.instance,
            builder: (context, _) {
              final watched = WatchlistService.instance.entries;
              if (watched.isEmpty) {
                return _emptyRow(
                  colors,
                  "You're not watching any checked-out books. Tap the bell on a book's details to get notified when it's returned.",
                );
              }
              return _groupedList(colors, [
                for (var i = 0; i < watched.length; i++)
                  _WatchRow(
                    entry: watched[i],
                    colors: colors,
                    showDivider: i != watched.length - 1,
                    onRemove: () => WatchlistService.instance.unwatch(watched[i].biblioId),
                  ),
              ]);
            },
          ),
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

/// Balance + borrowing-limit summary shown above Checkouts. Koha's
/// `/account` response doesn't include a currency code or symbol
/// (confirmed — it's a bare number), so "Rs." here is an assumption
/// based on this being a Pakistani university library, not something the
/// API told us — worth confirming against the real deployed Koha's
/// configured currency before shipping.
class _AccountSummaryCard extends StatelessWidget {
  final PatronAccount account;
  final int checkoutCount;
  final int? checkoutLimit;
  final SemanticColors colors;

  const _AccountSummaryCard({
    required this.account,
    required this.checkoutCount,
    required this.checkoutLimit,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final shadow = cardShadowDecoration(colors);
    final hasBalance = account.hasOutstandingBalance;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.background.secondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: shadow.border,
        boxShadow: shadow.boxShadow,
      ),
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
                    AppText('Account balance', variant: 'bodySmall', tone: 'secondary'),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      'Rs. ${account.balance.toStringAsFixed(2)}',
                      variant: 'h5',
                      tone: hasBalance ? 'error' : 'primary',
                    ),
                  ],
                ),
              ),
              if (checkoutLimit != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText('Books borrowed', variant: 'bodySmall', tone: 'secondary'),
                    const SizedBox(height: AppSpacing.xs),
                    AppText('$checkoutCount of $checkoutLimit', variant: 'h5'),
                  ],
                ),
            ],
          ),
          if (hasBalance) ...[
            const SizedBox(height: AppSpacing.sm),
            AppText(
              'Outstanding fines may block new holds or renewals until paid.',
              variant: 'bodySmall',
              tone: 'error',
            ),
          ],
        ],
      ),
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

class _WatchRow extends StatelessWidget {
  final WatchEntry entry;
  final SemanticColors colors;
  final bool showDivider;
  final VoidCallback onRemove;

  const _WatchRow({
    required this.entry,
    required this.colors,
    required this.showDivider,
    required this.onRemove,
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
                AppText(entry.title, variant: 'bodyBase', tone: 'primary'),
                if (entry.author != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppText(entry.author!, variant: 'bodySmall', tone: 'secondary'),
                ],
                const SizedBox(height: AppSpacing.xs),
                AppBadge(
                  label: entry.wasAvailable ? 'Available now!' : 'Watching — checked out',
                  intent: entry.wasAvailable ? 'success' : 'neutral',
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.ms),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Icon(LucideIcons.x, size: 18, color: colors.icon),
          ),
        ],
      ),
    );
  }
}
