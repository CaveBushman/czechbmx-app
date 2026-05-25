import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'auth_interceptor.dart';

class DioClient {
  DioClient._();

  static Dio create({bool withAuth = true}) {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    if (withAuth) dio.interceptors.add(AuthInterceptor());
    dio.interceptors.add(_LogInterceptor());
    return dio;
  }
}

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[HTTP] ${options.method} ${options.path}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[HTTP ${response.statusCode}] ${response.requestOptions.path} → ${response.data}');
      return true;
    }());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[HTTP ERR] ${err.response?.statusCode} ${err.response?.data} ${err.message}');
      return true;
    }());
    handler.next(err);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException e) {
    final code = e.response?.statusCode;
    final msg = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Časový limit připojení vypršel.',
      DioExceptionType.connectionError => 'Nelze se připojit k serveru.',
      _ => e.response?.data?['detail'] as String? ??
          'Neznámá chyba (${code ?? 'N/A'}).',
    };
    return ApiException(msg, statusCode: code);
  }

  @override
  String toString() => message;
}
