import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'models/news_model.dart';

final _dioProvider = Provider<Dio>((ref) => DioClient.create());

final newsRepositoryProvider = Provider<NewsRepository>(
  (ref) => NewsRepository(ref.read(_dioProvider)),
);

class NewsPage {
  final List<NewsModel> items;
  final bool hasMore;
  const NewsPage({required this.items, required this.hasMore});
}

class NewsRepository {
  final Dio _dio;
  const NewsRepository(this._dio);

  Future<NewsPage> fetchNews({int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiConstants.news,
        queryParameters: {'page': page, 'ordering': '-publish_date'},
      );
      final paginated = PaginatedNews.fromJson(response.data);
      final items = paginated.results
          .where((n) => n.published)
          .toList()
        ..sort((a, b) {
          final da = a.publishDate;
          final db = b.publishDate;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da);
        });
      return NewsPage(items: items, hasMore: paginated.next != null);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<NewsModel> fetchNewsDetail(String slugOrId) async {
    try {
      final response = await _dio.get(
        ApiConstants.news,
        queryParameters: {'ordering': '-publish_date'},
      );
      final paginated = PaginatedNews.fromJson(response.data);
      return paginated.results.firstWhere(
        (n) => n.slug == slugOrId || n.id.toString() == slugOrId,
        orElse: () => throw const ApiException('Článek nenalezen.', statusCode: 404),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
