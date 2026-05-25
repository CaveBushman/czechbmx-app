import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/rider_model.dart';
import '../rider_repository.dart';

final ridersFilterProvider = StateProvider<RidersFilter>((ref) => const RidersFilter());

final ridersProvider =
    AsyncNotifierProvider<RidersNotifier, List<RiderModel>>(RidersNotifier.new);

class RidersNotifier extends AsyncNotifier<List<RiderModel>> {
  @override
  Future<List<RiderModel>> build() {
    final filter = ref.watch(ridersFilterProvider);
    return ref.read(riderRepositoryProvider).fetchRiders(filter: filter);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final filter = ref.read(ridersFilterProvider);
    state = await AsyncValue.guard(
      () => ref.read(riderRepositoryProvider).fetchRiders(filter: filter),
    );
  }
}

final riderDetailProvider =
    AsyncNotifierProviderFamily<RiderDetailNotifier, RiderModel, int>(
  RiderDetailNotifier.new,
);

class RiderDetailNotifier extends FamilyAsyncNotifier<RiderModel, int> {
  @override
  Future<RiderModel> build(int uciId) async {
    final cached = ref.read(ridersProvider).valueOrNull
        ?.where((r) => r.uciId == uciId)
        .firstOrNull;
    if (cached != null) return cached;
    return ref.read(riderRepositoryProvider).fetchRiderDetail(uciId);
  }
}
