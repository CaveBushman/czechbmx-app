import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'models/news_model.dart';

final newsRepositoryProvider = Provider<NewsRepository>(
  (ref) => NewsRepository(ref.watch(publicDioProvider)),
);

class NewsPage {
  final List<NewsModel> items;
  final bool hasMore;
  const NewsPage({required this.items, required this.hasMore});
}

class NewsRepository {
  final Dio _dio;
  final Map<String, NewsPage> _pageCache = {};

  NewsRepository(this._dio);

  Future<NewsPage> fetchNews({
    int page = 1,
    String? search,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = '${search ?? ''}::$page';
      if (!forceRefresh && _pageCache.containsKey(cacheKey)) {
        return _pageCache[cacheKey]!;
      }

      final params = <String, dynamic>{
        'page': page,
        'ordering': '-publish_date'
      };
      if (search != null && search.isNotEmpty) params['search'] = search;
      final response = await _dio.get(
        ApiConstants.news,
        queryParameters: params,
      );
      final paginated = PaginatedNews.fromJson(response.data);
      final items = paginated.results.where((n) => n.published).toList()
        ..sort((a, b) {
          final da = a.publishDate;
          final db = b.publishDate;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da);
        });
      final result = NewsPage(items: items, hasMore: paginated.next != null);
      _pageCache[cacheKey] = result;
      return result;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<NewsModel> fetchNewsDetail(String slugOrId) async {
    try {
      final response = await _dio.get('${ApiConstants.news}$slugOrId/');
      return NewsModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        throw ApiException.fromDio(e);
      }
    }

    try {
      final response = await _dio.get(
        ApiConstants.news,
        queryParameters: {'ordering': '-publish_date'},
      );
      final paginated = PaginatedNews.fromJson(response.data);
      return paginated.results.firstWhere(
        (n) => n.slug == slugOrId || n.id.toString() == slugOrId,
        orElse: () =>
            throw const ApiException('Článek nenalezen.', statusCode: 404),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
