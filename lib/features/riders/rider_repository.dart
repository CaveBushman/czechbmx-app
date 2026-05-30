// Rider repository — načítání jezdců z API a správa disk cache.
//
// fetchRiders()      — stáhne všechny stránky z /api/riders/ podle filtru;
//                      výsledek bez filtru cachuje do riders_cache.json
// fetchRiderDetail() — GET /api/riders/{uciId}/
// fetchRiderResults()— GET /api/riders/{uciId}/results/
//
// Disk cache (riders_cache.json v app documents dir):
//   _saveToCache() — zapíše raw JSON seznam na disk (asynchronně, nevyhodí chybu)
//   _loadFromCache()— načte z disku při startu, aby byl seznam dostupný okamžitě
//
// warmDefaultRidersCache() — zavolá se z ridersCacheWarmupProvider při startu;
//   nejdřív načte disk cache, pak stáhne aktuální data a cache přepíše.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'models/rider_model.dart';

final riderRepositoryProvider = Provider<RiderRepository>(
  (ref) => RiderRepository(ref.watch(dioProvider)),
);

class RidersFilter {
  final String? search;
  final String? gender;
  final bool? is20;
  final bool? is24;
  final bool? isElite;

  const RidersFilter({
    this.search,
    this.gender,
    this.is20,
    this.is24,
    this.isElite,
  });

  bool get isDefault =>
      (search == null || search!.trim().isEmpty) &&
      gender == null &&
      is20 == null &&
      is24 == null &&
      isElite == null;

  Map<String, dynamic> toQueryParams({int? page}) => {
        if (search != null && search!.isNotEmpty) 'search': search,
        if (gender != null) 'gender': gender,
        if (is20 != null) 'is_20': is20,
        if (is24 != null) 'is_24': is24,
        if (isElite != null) 'is_elite': isElite,
        if (page != null) 'page': page,
        'ordering': 'last_name',
      };
}

class RiderRepository {
  final Dio _dio;
  List<RiderModel>? _defaultRidersCache;
  Future<List<RiderModel>>? _defaultRidersRefresh;

  RiderRepository(this._dio);

  List<RiderModel>? get cachedRiders => _defaultRidersCache;

  Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/riders_cache.json');
  }

  Future<void> _saveToCache(List<Map<String, dynamic>> rawItems) async {
    try {
      final file = await _cacheFile();
      await file.writeAsString(jsonEncode(rawItems));
    } catch (_) {}
  }

  Future<List<RiderModel>?> _loadFromCache() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return null;
      final list = jsonDecode(await file.readAsString()) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => RiderModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> warmDefaultRidersCache() async {
    _defaultRidersCache ??= await _loadFromCache();
    await fetchRiders(filter: const RidersFilter(), forceRefresh: true);
  }

  Future<List<RiderModel>> fetchRiders({
    RidersFilter? filter,
    bool forceRefresh = false,
  }) async {
    final effectiveFilter = filter ?? const RidersFilter();
    final canUseDefaultCache = effectiveFilter.isDefault;

    if (canUseDefaultCache && !forceRefresh) {
      if (_defaultRidersCache != null) return _defaultRidersCache!;

      final cached = await _loadFromCache();
      if (cached != null) {
        _defaultRidersCache = cached;
        return cached;
      }

      final inFlightRefresh = _defaultRidersRefresh;
      if (inFlightRefresh != null) return inFlightRefresh;
    }

    if (canUseDefaultCache && _defaultRidersRefresh != null) {
      return _defaultRidersRefresh!;
    }

    final request = _fetchRidersFromApi(
      filter: effectiveFilter,
      cacheResult: canUseDefaultCache,
    );

    if (!canUseDefaultCache) return request;

    _defaultRidersRefresh = request;
    try {
      return await request;
    } finally {
      _defaultRidersRefresh = null;
    }
  }

  Future<List<RiderModel>> _fetchRidersFromApi({
    required RidersFilter filter,
    required bool cacheResult,
  }) async {
    try {
      final riders = <RiderModel>[];
      final rawItems = <Map<String, dynamic>>[];
      var page = 1;
      var hasMore = true;

      while (hasMore) {
        final response = await _dio.get(
          ApiConstants.riders,
          queryParameters: filter.toQueryParams(page: page),
        );
        final paginated = PaginatedRiders.fromJson(response.data);
        riders.addAll(paginated.results);
        rawItems.addAll(_rawRiderItems(response.data));

        if (paginated.results.isEmpty) break;

        hasMore = paginated.next != null;
        if (!hasMore) break;
        page++;
      }

      if (cacheResult) {
        _defaultRidersCache = riders;
        unawaited(_saveToCache(rawItems));
      }

      return riders;
    } on DioException catch (e) {
      if (cacheResult) {
        final cached = await _loadFromCache();
        if (cached != null) {
          _defaultRidersCache = cached;
          return cached;
        }
      }
      throw ApiException.fromDio(e);
    }
  }

  List<Map<String, dynamic>> _rawRiderItems(dynamic data) {
    final raw = data is List
        ? data
        : data is Map
            ? (data['results'] ?? data['data'])
            : null;

    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<RiderModel> fetchRiderDetail(int uciId) async {
    try {
      final response = await _dio.get('${ApiConstants.riders}$uciId/');
      return RiderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<RiderResult>> fetchRiderResults(int uciId) async {
    try {
      final response = await _dio.get(ApiConstants.riderResults(uciId));
      final list = response.data as List<dynamic>;
      return list
          .map((e) => RiderResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
