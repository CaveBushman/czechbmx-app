// Riders state management — seznam jezdců a detail jezdce.
//
// ridersFilterProvider  — aktuální filtr (vyhledávání, pohlaví, 20"/24", elite)
//                         Nastavuje se z RidersListScreen při každé změně filtru.
// ridersProvider        — AsyncNotifier<List<RiderModel>>
//                         Při změně filtru automaticky znovu fetchuje.
// riderDetailProvider   — FamilyAsyncNotifier<RiderModel, int(uciId)>
//                         Nejdřív hledá jezdce v cache ridersProvider, pak fetchuje.
// riderResultsProvider  — výsledky jezdce za poslední rok (pro rider_detail_screen)
// teamsMapProvider      — Map<id, název> klubů (fallback pro jezdce bez team_name v API)
//
// Cache strategie:
//   ridersCacheWarmupProvider se spustí při startu — stáhne všechny jezdce
//   a uloží je do riders_cache.json (RiderRepository). Při příštím spuštění
//   se cache načte okamžitě a pak se tiše aktualizuje na pozadí.
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/rider_model.dart';
import '../rider_repository.dart';

final teamsMapProvider = FutureProvider<Map<int, String>>((ref) async {
  // Try /api/teams/ first, fall back to /api/clubs/
  for (final endpoint in [ApiConstants.teams, ApiConstants.clubs]) {
    try {
      final dio = ref.watch(publicDioProvider);
      final response = await dio.get(endpoint);
      final data = response.data;
      final list = data is List ? data : (data as Map)['results'] as List;
      final map = <int, String>{};
      for (final c in list) {
        final id = c['id'] as int?;
        final name = c['team_name'] as String? ??
            c['name'] as String? ??
            c['club_name'] as String? ??
            c['short_name'] as String? ??
            '';
        if (id != null) map[id] = name;
      }
      if (map.isNotEmpty) return map;
    } catch (_) {
      continue;
    }
  }
  return {};
});

final ridersFilterProvider = StateProvider<RidersFilter>(
  (ref) => const RidersFilter(),
);

final ridersProvider = AsyncNotifierProvider<RidersNotifier, List<RiderModel>>(
  RidersNotifier.new,
);

final ridersCacheWarmupProvider = FutureProvider<void>((ref) async {
  try {
    await ref.read(riderRepositoryProvider).warmDefaultRidersCache();
    // Tichá aktualizace — nepřechází přes AsyncLoading, žádný shimmer.
    final cached = ref.read(riderRepositoryProvider).cachedRiders;
    if (cached != null) {
      ref.read(ridersProvider.notifier).refreshFromCache(cached);
    }
  } catch (_) {
    // Warmup is best effort; the riders screen still handles its own errors.
  }
});

class RidersNotifier extends AsyncNotifier<List<RiderModel>> {
  @override
  Future<List<RiderModel>> build() async {
    final filter = ref.watch(ridersFilterProvider);
    return ref.read(riderRepositoryProvider).fetchRiders(filter: filter);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final filter = ref.read(ridersFilterProvider);
    state = await AsyncValue.guard(
      () => ref
          .read(riderRepositoryProvider)
          .fetchRiders(filter: filter, forceRefresh: true),
    );
  }

  // Tichá aktualizace po API warmup — bez přechodu přes AsyncLoading.
  void refreshFromCache(List<RiderModel> riders) {
    if (state is AsyncData && ref.read(ridersFilterProvider).isDefault) {
      state = AsyncData(riders);
    }
  }
}

final riderResultsProvider =
    FutureProvider.family<List<RiderResult>, int>((ref, uciId) {
  return ref.read(riderRepositoryProvider).fetchRiderResults(uciId);
});

final riderDetailProvider =
    AsyncNotifierProviderFamily<RiderDetailNotifier, RiderModel, int>(
  RiderDetailNotifier.new,
);

class RiderDetailNotifier extends FamilyAsyncNotifier<RiderModel, int> {
  @override
  Future<RiderModel> build(int uciId) async {
    final cached = ref
        .read(ridersProvider)
        .valueOrNull
        ?.where((r) => r.uciId == uciId)
        .firstOrNull;
    if (cached != null) return cached;
    return ref.read(riderRepositoryProvider).fetchRiderDetail(uciId);
  }
}
