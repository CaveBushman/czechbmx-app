import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'models/entry_model.dart';
import 'models/event_registered_rider_model.dart';
import 'models/foreign_entry_model.dart';

final entriesRepositoryProvider = Provider<EntriesRepository>(
  (ref) => EntriesRepository(ref.watch(dioProvider)),
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

  Future<EventRegisteredRiders> fetchEventRegisteredRiders({
    required int eventId,
  }) async {
    try {
      final response = await _dio.get<String>(
        ApiConstants.eventRegisteredRiders(eventId),
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'text/html'},
        ),
      );
      return EventRegisteredRiders.fromHtml(
        eventId: eventId,
        html: response.data ?? '',
      );
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

  Future<ForeignEntryInfo> fetchForeignEntryInfo({
    required int eventId,
    String? uciId,
    String? dob,
    String? gender,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (uciId != null && uciId.isNotEmpty) params['uci_id'] = uciId;
      if (dob != null && dob.isNotEmpty) params['dob'] = dob;
      if (gender != null && gender.isNotEmpty) params['gender'] = gender;
      final response = await _dio.get(
        ApiConstants.eventForeignEntryInfo(eventId),
        queryParameters: params.isEmpty ? null : params,
      );
      return ForeignEntryInfo.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ForeignEntryResult> enterForeignRider({
    required int eventId,
    required String uciId,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String gender,
    required String nationality,
    required String plate,
    required String transponder20,
    required String transponder24,
    required bool is20,
    required bool is24,
    required bool isElite,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.eventForeignEnter(eventId),
        data: {
          'uci_id': uciId,
          'first_name': firstName,
          'last_name': lastName,
          'date_of_birth': dateOfBirth,
          'gender': gender,
          'nationality': nationality,
          'plate': plate,
          'transponder_20': transponder20,
          'transponder_24': transponder24,
          'is_20': is20,
          'is_24': is24,
          'is_elite': isElite,
        },
      );
      return ForeignEntryResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<int> cancelForeignEntry(int entryId) async {
    try {
      final response =
          await _dio.post(ApiConstants.foreignEntryCancel(entryId));
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
  final String riderFirstName;
  final String riderLastName;
  final Map<String, EventEntryOption> options;

  const EventEntryInfo({
    required this.eventId,
    required this.eventName,
    required this.registrationOpen,
    required this.riderUciId,
    this.riderFirstName = '',
    this.riderLastName = '',
    required this.options,
  });

  String get riderFullName => '$riderFirstName $riderLastName'.trim();

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
    final rawRider = json['rider'];

    String? riderValue(String key) {
      if (rawRider is Map<String, dynamic>) {
        return _stringOrNull(rawRider[key]);
      }
      if (rawRider is Map) {
        return _stringOrNull(rawRider[key]);
      }
      return null;
    }

    return EventEntryInfo(
      eventId: json['event_id'] as int,
      eventName: json['event_name'] as String? ?? '',
      registrationOpen: json['registration_open'] as bool? ?? false,
      riderUciId: json['rider_uci_id'] as int,
      riderFirstName: _stringOrNull(json['rider_first_name']) ??
          _stringOrNull(json['first_name']) ??
          riderValue('first_name') ??
          '',
      riderLastName: _stringOrNull(json['rider_last_name']) ??
          _stringOrNull(json['last_name']) ??
          riderValue('last_name') ??
          '',
      options: rawOptions.map(
        (key, value) => MapEntry(
          key,
          EventEntryOption.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }

  static String? _stringOrNull(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
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
