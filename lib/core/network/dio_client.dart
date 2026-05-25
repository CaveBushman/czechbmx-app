import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../constants/api_constants.dart';
import '../l10n/locale_provider.dart';
import 'auth_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final localeCode = ref.watch(currentLocaleCodeProvider);
  return DioClient.create(localeCode: localeCode);
});

final publicDioProvider = Provider<Dio>(
  (ref) {
    final localeCode = ref.watch(currentLocaleCodeProvider);
    return DioClient.create(withAuth: false, localeCode: localeCode);
  },
);

class DioClient {
  DioClient._();

  static Dio create({bool withAuth = true, String localeCode = 'cs'}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language': localeCode,
        },
      ),
    );

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
      print('[HTTP] ${options.method} ${options.uri}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print(
        '[HTTP ${response.statusCode}] ${response.requestOptions.uri} → ${_shortLog(response.data)}',
      );
      return true;
    }());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print(
        '[HTTP ERR] ${err.response?.statusCode} ${err.requestOptions.uri} ${_shortLog(err.response?.data)} ${err.message}',
      );
      return true;
    }());
    handler.next(err);
  }
}

String _shortLog(Object? value) {
  final text = value.toString();
  if (text.length <= 500) return text;
  return '${text.substring(0, 500)}... (${text.length} chars)';
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
      _ => _messageFromResponse(e.response?.data, code),
    };
    return ApiException(msg, statusCode: code);
  }

  static String _messageFromResponse(dynamic data, int? code) {
    if (data is String && data.isNotEmpty) return data;
    if (data is Map) {
      for (final key in const ['detail', 'error', 'message']) {
        final value = data[key];
        if (value is String && value.isNotEmpty) return value;
      }
      for (final value in data.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value is String && value.isNotEmpty) return value;
      }
    }
    return 'Neznámá chyba (${code ?? 'N/A'}).';
  }

  @override
  String toString() => message;
}
