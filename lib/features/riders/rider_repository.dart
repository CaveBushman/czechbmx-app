import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'models/rider_model.dart';

final _dioProvider = Provider<Dio>((ref) => DioClient.create());

final riderRepositoryProvider = Provider<RiderRepository>(
  (ref) => RiderRepository(ref.read(_dioProvider)),
);

class RidersFilter {
  final String? search;
  final String? gender;
  final bool? is20;
  final bool? is24;
  final bool? isElite;

  const RidersFilter({this.search, this.gender, this.is20, this.is24, this.isElite});

  Map<String, dynamic> toQueryParams() => {
        if (search != null && search!.isNotEmpty) 'search': search,
        if (gender != null) 'gender': gender,
        if (is20 != null) 'is_20': is20,
        if (is24 != null) 'is_24': is24,
        if (isElite != null) 'is_elite': isElite,
        'ordering': 'last_name',
      };
}

class RiderRepository {
  final Dio _dio;

  const RiderRepository(this._dio);

  Future<List<RiderModel>> fetchRiders({RidersFilter? filter}) async {
    try {
      final response = await _dio.get(
        ApiConstants.riders,
        queryParameters: filter?.toQueryParams(),
      );
      return PaginatedRiders.fromJson(response.data).results;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<RiderModel> fetchRiderDetail(int uciId) async {
    try {
      final response = await _dio.get('${ApiConstants.riders}$uciId/');
      return RiderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
