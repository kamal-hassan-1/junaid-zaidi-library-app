import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A student's "book bag" — biblios collected while browsing OPAC to act
/// on together later (view as a list, place holds in bulk), mirroring
/// the real OPAC website's cart/"Add to cart" feature. Persisted locally
/// via [SharedPreferences] — this is a personal browsing aid, not
/// synced to Koha, same as the website's own cart (which is
/// browser-local too).
///
/// [ChangeNotifier] so any screen (the OPAC app bar badge, a book
/// card's bag toggle, the bag screen itself) can listen and stay in
/// sync without passing state around manually — wrap consumers in a
/// [ListenableBuilder] listening to [BookBagService.instance].
class BookBagService extends ChangeNotifier {
  BookBagService._();

  static final BookBagService instance = BookBagService._();

  static const _prefsKey = 'book_bag_biblio_ids';

  Set<int> _ids = {};
  bool _loaded = false;

  int get count => _ids.length;

  bool contains(int biblioId) => _ids.contains(biblioId);

  List<int> get ids => List.unmodifiable(_ids);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey) ?? const [];
    _ids = stored.map(int.parse).toSet();
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle(int biblioId) async {
    await ensureLoaded();
    if (!_ids.remove(biblioId)) _ids.add(biblioId);
    await _persist();
    notifyListeners();
  }

  Future<void> remove(int biblioId) async {
    await ensureLoaded();
    if (_ids.remove(biblioId)) {
      await _persist();
      notifyListeners();
    }
  }

  Future<void> clear() async {
    await ensureLoaded();
    if (_ids.isEmpty) return;
    _ids.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _ids.map((e) => e.toString()).toList());
  }
}
