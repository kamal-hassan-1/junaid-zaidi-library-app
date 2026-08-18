import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only recent-search list for the OPAC search bar — mirrors the
/// real OPAC website's server-tracked search history, but kept entirely
/// on-device (no Koha endpoint for this was found; the real site's
/// history is tied to a logged-in Koha session this app doesn't have).
///
/// Same singleton-`ChangeNotifier`-over-`SharedPreferences` shape as
/// [BookBagService] — most recent first, capped, deduplicated by moving a
/// repeated query back to the front rather than storing it twice.
class SearchHistoryService extends ChangeNotifier {
  SearchHistoryService._();
  static final SearchHistoryService instance = SearchHistoryService._();

  static const String _prefsKey = 'opac_search_history';
  static const int _maxEntries = 12;

  List<String> _queries = [];
  bool _loaded = false;

  List<String> get queries => List.unmodifiable(_queries);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    _queries = prefs.getStringList(_prefsKey) ?? const [];
    notifyListeners();
  }

  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    await ensureLoaded();
    _queries.removeWhere((q) => q.toLowerCase() == trimmed.toLowerCase());
    _queries.insert(0, trimmed);
    if (_queries.length > _maxEntries) {
      _queries = _queries.sublist(0, _maxEntries);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String query) async {
    await ensureLoaded();
    _queries.remove(query);
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    await ensureLoaded();
    _queries = [];
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _queries);
  }
}
