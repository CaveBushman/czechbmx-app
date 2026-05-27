import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/club_model.dart';

final clubsProvider = FutureProvider<List<ClubModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.clubs);
  final dynamic data = response.data;
  final List<dynamic> items = data is List
      ? data
      : (data as Map<String, dynamic>)['results'] as List<dynamic>;
  return items
      .map((e) => ClubModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

final clubDetailProvider = FutureProvider.family<ClubModel, int>((ref, id) async {
  // Prefer the clubs list — avoids a separate API endpoint
  final allClubs = await ref.watch(clubsProvider.future);
  final found = allClubs.where((c) => c.id == id).firstOrNull;
  if (found != null) return found;
  // Fallback: direct endpoint (for when the club is inactive/missing from list)
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.clubDetail(id));
  return ClubModel.fromJson(response.data as Map<String, dynamic>);
});
