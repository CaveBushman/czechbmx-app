import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/license_model.dart';

final licenseProvider =
    FutureProvider.family<LicenseInfo, int>((ref, uciId) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get(ApiConstants.riderLicense(uciId));
    return LicenseInfo.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
});
