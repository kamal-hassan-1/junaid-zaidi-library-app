/// A single fine/charge/payment line from a patron's Koha account —
/// `outstanding_debits.lines[]` on `GET /api/v1/patrons/{id}/account`.
///
/// Field names/shape confirmed live (2026-08-18, see deferred.md): posted
/// a real test debit via `POST /api/v1/patrons/{id}/account/debits` and
/// inspected the resulting line directly, rather than guessing from docs.
class AccountLine {
  final int accountLineId;
  final double amount;
  final double amountOutstanding;
  final String? description;
  final String? debitType;
  final DateTime? date;

  const AccountLine({
    required this.accountLineId,
    required this.amount,
    required this.amountOutstanding,
    this.description,
    this.debitType,
    this.date,
  });

  factory AccountLine.fromJson(Map<String, dynamic> json) {
    return AccountLine(
      accountLineId: json['account_line_id'] as int,
      amount: (json['amount'] as num).toDouble(),
      amountOutstanding: (json['amount_outstanding'] as num).toDouble(),
      description: json['description'] as String?,
      debitType: json['debit_type'] as String?,
      date: DateTime.tryParse((json['date'] as String?) ?? ''),
    );
  }

  /// Human-friendly label for [debitType] — Koha's real values seen so
  /// far ('OVERDUE' from a live test debit); others are educated guesses
  /// at Koha's standard debit-type vocabulary, not individually confirmed.
  String get typeLabel {
    switch (debitType) {
      case 'OVERDUE':
        return 'Overdue fine';
      case 'LOST':
        return 'Lost item';
      case 'MANUAL':
        return 'Manual charge';
      case 'NEW_CARD':
        return 'New card fee';
      case 'RENT':
        return 'Rental fee';
      default:
        return description ?? 'Charge';
    }
  }
}

/// A patron's Koha account balance and outstanding charges —
/// `GET /api/v1/patrons/{id}/account`. Confirmed live (2026-08-18): real
/// shape is `{balance, outstanding_credits: {lines, total},
/// outstanding_debits: {lines, total}}`. Only debits (money owed) are
/// modeled — credits (refunds/overpayments) aren't surfaced anywhere in
/// the app yet since there's no real scenario for a student to have one.
class PatronAccount {
  final double balance;
  final List<AccountLine> debitLines;

  const PatronAccount({required this.balance, required this.debitLines});

  bool get hasOutstandingBalance => balance > 0;

  factory PatronAccount.fromJson(Map<String, dynamic> json) {
    final debits = json['outstanding_debits'] as Map<String, dynamic>?;
    final lines = (debits?['lines'] as List<dynamic>?) ?? const [];
    return PatronAccount(
      balance: ((json['balance'] as num?) ?? 0).toDouble(),
      debitLines: lines
          .map((e) => AccountLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
