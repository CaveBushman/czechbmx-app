// JWT interceptor — automatická správa přihlašovacích tokenů.
//
// Tok:
//   onRequest: přidá "Authorization: Bearer <access_token>" ke každému requestu
//   onError:   při 401 zkusí obnovit token přes /api/auth/token/refresh/
//              a pak zopakuje původní request s novým tokenem
//              → pokud obnova selže, zavolá onForceLogout (AuthNotifier přejde na Unauthenticated)
//
// Důležité detaily:
//   _refreshDio je zvláštní Dio instance bez interceptoru — jinak by obnova tokenu
//   způsobila nekonečnou smyčku (401 → obnov → 401 → obnov…)
//
//   onForceLogout callback nastavuje AuthNotifier v auth_provider.dart při inicializaci.
//   Bez toho by interceptor nemohl informovat Riverpod state o vynuceném odhlášení.
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

      // Retry original request with new token.
      // Use a nested try so a 403/404/5xx on the retry doesn't trigger logout —
      // only a genuine token failure (401) should do that.
      try {
        final opts = err.requestOptions
          ..headers['Authorization'] = 'Bearer $newAccess';
        final retryResponse = await _refreshDio.fetch(opts);
        handler.resolve(retryResponse);
      } on DioException catch (retryErr) {
        handler.reject(retryErr);
      }
    } catch (_) {
      // Token refresh itself failed — session is truly over.
      await TokenStorage.clear();
      onForceLogout?.call();
      handler.next(err);
    }
  }
}
