import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../riders/models/rider_model.dart';
import '../../riders/rider_repository.dart';

// All active riders loaded once for rankings (no search/filter applied)
final allRidersProvider =
    AsyncNotifierProvider<AllRidersNotifier, List<RiderModel>>(AllRidersNotifier.new);

class AllRidersNotifier extends AsyncNotifier<List<RiderModel>> {
  @override
  Future<List<RiderModel>> build() =>
      ref.read(riderRepositoryProvider).fetchRiders();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(riderRepositoryProvider).fetchRiders(),
    );
  }
}

// 20" categories in display order
const kCategories20 = [
  'Men Elite',
  'Women Elite',
  'Men Under 23',
  'Women Under 23',
  'Men Junior',
  'Women Junior',
  'Men 17-24',
  'Men 25-29',
  'Men 30-34',
  'Men 35 and over',
  'Women 17-24',
  'Women 25 and over',
  'Boys 16',
  'Boys 15',
  'Boys 14',
  'Boys 13',
  'Boys 12',
  'Boys 11',
  'Boys 10',
  'Boys 9',
  'Boys 8',
  'Boys 7',
  'Boys 6',
  'Girls 16',
  'Girls 15',
  'Girls 14',
  'Girls 13',
  'Girls 12',
  'Girls 11',
  'Girls 10',
  'Girls 9',
  'Girls 8',
  'Girls 7',
];

// 24" categories in display order
const kCategories24 = [
  'Men Elite',
  'Women Elite',
  'Men 17-24',
  'Men 25-39',
  'Men 30-34',
  'Men 35-39',
  'Men 40-44',
  'Men 45-49',
  'Men 50 and over',
  'Women 17-29',
  'Women 30-99',
  'Women 40 and over',
  'Boys 15 and 16',
  'Boys 13 and 14',
  'Boys 12 and under',
  'Girls 13-16',
  'Girls 12 and under',
];
