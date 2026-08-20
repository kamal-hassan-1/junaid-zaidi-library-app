import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/availability.dart';
import 'biblio_service.dart';
import 'notification_service.dart';

/// One watched title — separate from a real Koha hold. Watching costs
/// nothing on the Koha side (it's purely local state); the point is to
/// know the moment a currently-checked-out book comes back, so the
/// student can *decide* whether it's worth queuing for, rather than
/// either committing to a hold early or re-checking the catalog by hand.
class WatchEntry {
  final int biblioId;
  final String title;
  final String? author;

  /// Whether the title was available the last time it was checked —
  /// this is what [WatchlistService.checkForAvailabilityChanges] compares
  /// against to detect a false→true transition worth notifying about.
  final bool wasAvailable;

  const WatchEntry({
    required this.biblioId,
    required this.title,
    this.author,
    this.wasAvailable = false,
  });

  WatchEntry copyWith({bool? wasAvailable}) => WatchEntry(
        biblioId: biblioId,
        title: title,
        author: author,
        wasAvailable: wasAvailable ?? this.wasAvailable,
      );

  Map<String, dynamic> toJson() => {
        'biblioId': biblioId,
        'title': title,
        'author': author,
        'wasAvailable': wasAvailable,
      };

  factory WatchEntry.fromJson(Map<String, dynamic> json) => WatchEntry(
        biblioId: json['biblioId'] as int,
        title: json['title'] as String,
        author: json['author'] as String?,
        wasAvailable: json['wasAvailable'] as bool? ?? false,
      );
}

/// Local-only "notify me when this comes back" list — see [WatchEntry].
/// Same singleton-`ChangeNotifier`-over-`SharedPreferences` shape as
/// [BookBagService]/[SearchHistoryService].
///
/// There's no server push from Koha, so "watching" means checking
/// availability opportunistically whenever [checkForAvailabilityChanges]
/// is called — [MyBooksScreen] does this every time it loads, the same
/// rebuild-on-load pattern [NotificationService.scheduleDueDateReminders]
/// already uses for due-date reminders. It isn't true background
/// monitoring, but it costs nothing extra to run and catches a change
/// the next time the student has the app open, which is when they'd act
/// on it anyway.
class WatchlistService extends ChangeNotifier {
  WatchlistService._();
  static final WatchlistService instance = WatchlistService._();

  static const String _prefsKey = 'watchlist_v1';

  Map<int, WatchEntry> _entries = {};
  bool _loaded = false;

  List<WatchEntry> get entries =>
      List.unmodifiable(_entries.values);

  bool isWatching(int biblioId) => _entries.containsKey(biblioId);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _entries = {
          for (final e in decoded)
            (e as Map<String, dynamic>)['biblioId'] as int: WatchEntry.fromJson(e),
        };
      } catch (_) {
        _entries = {};
      }
    }
    notifyListeners();
  }

  Future<void> watch({
    required int biblioId,
    required String title,
    String? author,
  }) async {
    await ensureLoaded();
    _entries[biblioId] = WatchEntry(biblioId: biblioId, title: title, author: author);
    notifyListeners();
    await _persist();
  }

  Future<void> unwatch(int biblioId) async {
    await ensureLoaded();
    if (_entries.remove(biblioId) != null) {
      notifyListeners();
      await _persist();
    }
  }

  /// Re-checks every watched title's real availability and fires a
  /// notification for any that just flipped from checked-out to
  /// available. Silent on failure per-title (a flaky Koha response for
  /// one book shouldn't stop the rest from being checked), and updates
  /// [WatchEntry.wasAvailable] either way so a title is never notified
  /// about twice for the same return.
  Future<void> checkForAvailabilityChanges(BiblioSource biblioService) async {
    await ensureLoaded();
    if (_entries.isEmpty) return;

    var changed = false;
    for (final entry in _entries.values.toList()) {
      try {
        final availability = await biblioService.fetchAvailability(entry.biblioId);
        final isAvailableNow = availability.status == AvailabilityStatus.available;
        if (isAvailableNow == entry.wasAvailable) continue;

        changed = true;
        _entries[entry.biblioId] = entry.copyWith(wasAvailable: isAvailableNow);
        if (isAvailableNow) {
          unawaited(NotificationService.instance.notifyBookAvailable(
            biblioId: entry.biblioId,
            title: entry.title,
          ));
        }
      } catch (_) {
        // Leave this entry as-is and check it again next time.
      }
    }
    if (changed) {
      notifyListeners();
      await _persist();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(_entries.values.map((e) => e.toJson()).toList()),
    );
  }
}
