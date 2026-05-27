import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'token_storage.dart';

class AuthInterceptor extends Interceptor {
  // Called when tokens are cleared due to failed refresh — wire up in AuthNotifier
  static void Function()? onForceLogout;

  // Separate Dio instance for refresh — avoids infinite loop
  final Dio _refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.getAccess();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Don't retry the refresh endpoint itself
    if (err.requestOptions.path.contains('token/refresh') ||
        err.requestOptions.path.contains('auth/login')) {
      handler.next(err);
      return;
    }

    final refreshToken = await TokenStorage.getRefresh();
    if (refreshToken == null) {
      handler.next(err);
      return;
    }

    try {
      final response = await _refreshDio.post(
        ApiConstants.authRefresh,
        data: {'refresh': refreshToken},
      );
      final data = response.data;
      final newAccess = data is Map ? data['access'] as String? : null;
      final newRefresh = data is Map ? data['refresh'] as String? : null;
      if (newAccess == null || newAccess.isEmpty) {
        await TokenStorage.clear();
        onForceLogout?.call();
        handler.next(err);
        return;
      }

      await TokenStorage.saveAccess(newAccess);
      if (newRefresh != null) {
        await TokenStorage.save(access: newAccess, refresh: newRefresh);
      }

      // Retry original request with new token
      final opts = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccess';
      final retryResponse = await _refreshDio.fetch(opts);
      handler.resolve(retryResponse);
    } catch (_) {
      await TokenStorage.clear();
      onForceLogout?.call();
      handler.next(err);
    }
  }
}
