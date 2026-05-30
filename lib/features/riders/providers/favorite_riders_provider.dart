// Oblíbení jezdci — perzistentní Set<int> UCI ID uložený v SharedPreferences.
//
// favoriteRidersProvider — StateNotifier<Set<int>>
//   toggle(uciId) — přidá/odebere jezdce a ihned uloží do SharedPreferences
//
// Používá se na třech místech:
//   RidersListScreen  — filtr "Jen oblíbení" a ikona srdíčka na každém tile
//   RiderDetailScreen — ikona srdíčka v AppBaru
//   EventRegisteredRidersScreen — toggle "Jen oblíbení" v AppBaru
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kKey = 'favorite_rider_uci_ids';

final favoriteRidersProvider =
    StateNotifierProvider<FavoriteRidersNotifier, Set<int>>(
  (ref) => FavoriteRidersNotifier(),
);

class FavoriteRidersNotifier extends StateNotifier<Set<int>> {
  FavoriteRidersNotifier() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kKey) ?? [];
    state = raw.map((e) => int.tryParse(e)).whereType<int>().toSet();
  }

  Future<void> toggle(int uciId) async {
    final next = Set<int>.from(state);
    if (next.contains(uciId)) {
      next.remove(uciId);
    } else {
      next.add(uciId);
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kKey, state.map((e) => '$e').toList());
  }
}
