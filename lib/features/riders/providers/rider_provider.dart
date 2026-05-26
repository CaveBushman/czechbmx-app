import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/rider_model.dart';
import '../rider_repository.dart';

final teamsMapProvider = FutureProvider<Map<int, String>>((ref) async {
  // Try /api/teams/ first, fall back to /api/clubs/
  for (final endpoint in [ApiConstants.teams, ApiConstants.clubs]) {
    try {
      final dio = ref.read(publicDioProvider);
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

class RidersNotifier extends AsyncNotifier<List<RiderModel>> {
  @override
  Future<List<RiderModel>> build() async {
    final authState = await ref.watch(authProvider.future);
    if (authState is! AuthAuthenticated) {
      throw const ApiException('login_required', statusCode: 401);
    }

    final filter = ref.watch(ridersFilterProvider);
    return ref.read(riderRepositoryProvider).fetchRiders(filter: filter);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final authState = await ref.read(authProvider.future);
    if (authState is! AuthAuthenticated) {
      state = AsyncError(
        const ApiException('login_required', statusCode: 401),
        StackTrace.current,
      );
      return;
    }

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
    final authState = await ref.watch(authProvider.future);
    if (authState is! AuthAuthenticated) {
      throw const ApiException('login_required', statusCode: 401);
    }

    final cached = ref
        .read(ridersProvider)
        .valueOrNull
        ?.where((r) => r.uciId == uciId)
        .firstOrNull;
    if (cached != null) return cached;
    return ref.read(riderRepositoryProvider).fetchRiderDetail(uciId);
  }
}
