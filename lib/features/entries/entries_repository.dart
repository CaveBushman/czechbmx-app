import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'models/entry_model.dart';

final entriesRepositoryProvider = Provider<EntriesRepository>(
  (ref) => EntriesRepository(ref.read(dioProvider)),
);

class EntriesRepository {
  final Dio _dio;
  const EntriesRepository(this._dio);

  Future<EventEntryInfo> fetchEventEntryInfo({
    required int eventId,
    required int riderUciId,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.eventEntryInfo(eventId),
        queryParameters: {'rider_uci_id': riderUciId},
      );
      return EventEntryInfo.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<EntryModel> enterEvent({
    required int eventId,
    required int riderUciId,
    required bool is20,
    required bool is24,
    required bool isBeginner,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.eventEnter(eventId),
        data: {
          'rider_uci_id': riderUciId,
          'is_20': is20,
          'is_24': is24,
          'is_beginner': isBeginner,
        },
      );
      return EntryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<EntryModel>> fetchMyEntries() async {
    try {
      final response = await _dio.get(ApiConstants.entriesMy);
      final data = response.data;
      final list = data is List ? data : (data as Map)['results'] as List;
      return list
          .map((e) => EntryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<int> cancelEntry(int entryId) async {
    try {
      final response = await _dio.post(ApiConstants.entryCancel(entryId));
      return response.data['new_balance'] as int? ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

class EventEntryInfo {
  final int eventId;
  final String eventName;
  final bool registrationOpen;
  final int riderUciId;
  final Map<String, EventEntryOption> options;

  const EventEntryInfo({
    required this.eventId,
    required this.eventName,
    required this.registrationOpen,
    required this.riderUciId,
    required this.options,
  });

  Iterable<MapEntry<String, EventEntryOption>> get selectableOptions =>
      options.entries.where(
        (entry) => entry.value.allowed && !entry.value.alreadyRegistered,
      );

  int feeFor(Set<String> selected) {
    var total = 0;
    for (final key in selected) {
      total += options[key]?.fee ?? 0;
    }
    return total;
  }

  factory EventEntryInfo.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as Map<String, dynamic>? ?? {};
    return EventEntryInfo(
      eventId: json['event_id'] as int,
      eventName: json['event_name'] as String? ?? '',
      registrationOpen: json['registration_open'] as bool? ?? false,
      riderUciId: json['rider_uci_id'] as int,
      options: rawOptions.map(
        (key, value) => MapEntry(
          key,
          EventEntryOption.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }
}

class EventEntryOption {
  final bool allowed;
  final String? className;
  final int fee;
  final bool alreadyRegistered;

  const EventEntryOption({
    required this.allowed,
    this.className,
    required this.fee,
    required this.alreadyRegistered,
  });

  factory EventEntryOption.fromJson(Map<String, dynamic> json) {
    return EventEntryOption(
      allowed: json['allowed'] as bool? ?? false,
      className: json['class'] as String?,
      fee: json['fee'] as int? ?? 0,
      alreadyRegistered: json['already_registered'] as bool? ?? false,
    );
  }
}
