import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'models/ranking_model.dart';

final rankingRepositoryProvider = Provider<RankingRepository>(
  (ref) => RankingRepository(ref.watch(publicDioProvider)),
);

class RankingRepository {
  final Dio _dio;
  const RankingRepository(this._dio);

  Future<List<String>> fetchCategories() async {
    try {
      final response = await _dio.get(ApiConstants.rankingCategories);
      final data = response.data as Map<String, dynamic>;
      return (data['categories'] as List<dynamic>)
          .map((e) => e as String)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<RankedRider>> fetchRanking(String category) async {
    try {
      final response = await _dio.get(
        ApiConstants.ranking,
        queryParameters: {'category': category},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['results'] as List<dynamic>)
          .map((e) => RankedRider.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
