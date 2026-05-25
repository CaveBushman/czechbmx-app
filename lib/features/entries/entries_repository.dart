import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'models/entry_model.dart';

final entriesRepositoryProvider = Provider<EntriesRepository>(
  (ref) => EntriesRepository(ref.read(dioProvider)),
);

class EntriesRepository {
  final Dio _dio;
  const EntriesRepository(this._dio);

  Future<List<EntryModel>> fetchMyEntries() async {
    try {
      final response = await _dio.get(ApiConstants.entriesMy);
      final data = response.data;
      final list = data is List ? data : (data as Map)['results'] as List;
      return list
          .map((e) => EntryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<int> cancelEntry(int entryId) async {
    try {
      final response = await _dio.post(ApiConstants.entryCancel(entryId));
      return response.data['new_balance'] as int? ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
