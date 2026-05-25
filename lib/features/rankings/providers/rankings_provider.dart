import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/ranking_model.dart';
import '../ranking_repository.dart';

// ── Categories ────────────────────────────────────────────────────────────────

final rankingCategoriesProvider =
    AsyncNotifierProvider<RankingCategoriesNotifier, List<String>>(
  RankingCategoriesNotifier.new,
);

class RankingCategoriesNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() =>
      ref.read(rankingRepositoryProvider).fetchCategories();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(rankingRepositoryProvider).fetchCategories(),
    );
  }
}

// 20" categories: no "Cruiser" prefix
List<String> categories20(List<String> all) =>
    all.where((c) => !c.startsWith('Cruiser')).toList();

// 24" categories: "Cruiser " prefix — strip it for display, keep full for requests
List<String> categories24(List<String> all) =>
    all.where((c) => c.startsWith('Cruiser')).toList();

String displayCategory24(String cat) =>
    cat.startsWith('Cruiser ') ? cat.substring(8) : cat;

// ── Per-category ranking ──────────────────────────────────────────────────────

final rankingProvider =
    AsyncNotifierProviderFamily<RankingNotifier, List<RankedRider>, String>(
  RankingNotifier.new,
);

class RankingNotifier extends FamilyAsyncNotifier<List<RankedRider>, String> {
  @override
  Future<List<RankedRider>> build(String category) =>
      ref.read(rankingRepositoryProvider).fetchRanking(category);
}
