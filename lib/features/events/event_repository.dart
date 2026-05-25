import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'models/event_model.dart';

final _dioProvider = Provider<Dio>((ref) => DioClient.create());

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(ref.read(_dioProvider)),
);

class EventRepository {
  final Dio _dio;

  const EventRepository(this._dio);

  Future<List<EventModel>> fetchEvents({int? year}) async {
    try {
      final targetYear = year ?? DateTime.now().year;
      final response = await _dio.get(
        ApiConstants.events,
        queryParameters: {'ordering': 'date'},
      );
      final paginated = PaginatedEvents.fromJson(response.data);
      return paginated.results
          .where((e) => e.date?.year == targetYear)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<EventModel> fetchEventDetail(int id) async {
    try {
      final response = await _dio.get('${ApiConstants.events}$id/');
      return EventModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
