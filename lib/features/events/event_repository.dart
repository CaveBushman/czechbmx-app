import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'models/event_model.dart';

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(ref.read(dioProvider)),
);

class EventRepository {
  final Dio _dio;
  final Map<int, List<EventModel>> _eventsByYearCache = {};

  EventRepository(this._dio);

  Future<File> _cacheFile(int year) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/events_cache_$year.json');
  }

  Future<void> _saveToCache(int year, List<Map<String, dynamic>> rawItems) async {
    try {
      final file = await _cacheFile(year);
      await file.writeAsString(jsonEncode(rawItems));
    } catch (_) {}
  }

  Future<List<EventModel>?> _loadFromCache(int year) async {
    try {
      final file = await _cacheFile(year);
      if (!await file.exists()) return null;
      final list = jsonDecode(await file.readAsString()) as List<dynamic>;
      return list
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<EventModel>> fetchEvents({
    int? year,
    bool forceRefresh = false,
  }) async {
    final targetYear = year ?? DateTime.now().year;

    if (!forceRefresh && _eventsByYearCache.containsKey(targetYear)) {
      return _eventsByYearCache[targetYear]!;
    }

    try {
      final rawItems = <Map<String, dynamic>>[];
      var page = 1;
      var hasMore = true;

      while (hasMore) {
        final response = await _dio.get(
          ApiConstants.events,
          queryParameters: {
            'year': targetYear,
            'ordering': 'date',
            'page': page,
          },
        );
        final paginated = PaginatedEvents.fromJson(response.data);
        // Collect raw maps for disk cache
        final results = (response.data['results'] as List?)
            ?.cast<Map<String, dynamic>>() ?? [];
        rawItems.addAll(results);
        hasMore = paginated.next != null;
        page++;
      }

      final events = rawItems.map(EventModel.fromJson).toList();
      _eventsByYearCache[targetYear] = events;
      _saveToCache(targetYear, rawItems);
      return events;
    } on DioException catch (e) {
      // Network error → try disk cache
      final cached = await _loadFromCache(targetYear);
      if (cached != null) return cached;
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
