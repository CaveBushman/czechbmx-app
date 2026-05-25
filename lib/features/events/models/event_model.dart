import '../../../core/constants/api_constants.dart';

enum EventType {
  mistrovstviCrJednotlivcu('Mistrovství ČR jednotlivců'),
  mistrovstviCrDruzstev('Mistrovství ČR družstev'),
  ceskyPohar('Český pohár'),
  ceskaLiga('Česká liga'),
  moravskaLiga('Moravská liga'),
  volnyZavod('Volný závod'),
  evropskyPohar('Evropský pohár'),
  mistrovstviEvropy('Mistrovství Evropy'),
  mistrovstviSveta('Mistrovství světa'),
  svetovyPohar('Světový pohár'),
  nehodnocenyZavod('Nehodnocený závod');

  final String label;
  const EventType(this.label);

  static EventType fromString(String value) {
    return EventType.values.firstWhere(
      (e) => e.label == value,
      orElse: () => EventType.volnyZavod,
    );
  }

  bool get isInternational => switch (this) {
        EventType.evropskyPohar ||
        EventType.mistrovstviEvropy ||
        EventType.mistrovstviSveta ||
        EventType.svetovyPohar =>
          true,
        _ => false,
      };

  bool get isChampionship => switch (this) {
        EventType.mistrovstviCrJednotlivcu ||
        EventType.mistrovstviCrDruzstev ||
        EventType.mistrovstviEvropy ||
        EventType.mistrovstviSveta =>
          true,
        _ => false,
      };
}

class EventModel {
  final int id;
  final String name;
  final DateTime? date;
  final bool doubleRace;
  final int? organizerId;
  final EventType type;
  final bool isUciRace;
  final String? director;
  final DateTime? regOpenFrom;
  final DateTime? regOpenTo;
  final DateTime? regCancelTo;
  final bool regOpen;
  final bool eshopPickupEnabled;
  final String? eshopPickupLocation;
  final String? eshopPickupTime;
  final String? eshopPickupNote;
  final String? system;
  final String? youtubeLink;
  final String? proposition;
  final String? series;
  final String? bemRidersList;
  final String? fullResults;
  final String? htmlResults;
  final String? fastRiders;
  final String? xlsResults;
  final String? uecLink;
  final String? uciEventCode;
  final bool canceled;

  const EventModel({
    required this.id,
    required this.name,
    this.date,
    required this.doubleRace,
    this.organizerId,
    required this.type,
    required this.isUciRace,
    this.director,
    this.regOpenFrom,
    this.regOpenTo,
    this.regCancelTo,
    required this.regOpen,
    required this.eshopPickupEnabled,
    this.eshopPickupLocation,
    this.eshopPickupTime,
    this.eshopPickupNote,
    this.system,
    this.youtubeLink,
    this.proposition,
    this.series,
    this.bemRidersList,
    this.fullResults,
    this.htmlResults,
    this.fastRiders,
    this.xlsResults,
    this.uecLink,
    this.uciEventCode,
    required this.canceled,
  });

  bool get isRegistrationOpen {
    if (!regOpen) return false;
    final now = DateTime.now();
    if (regOpenFrom != null && now.isBefore(regOpenFrom!)) return false;
    if (regOpenTo != null && now.isAfter(regOpenTo!)) return false;
    return true;
  }

  bool get isPast {
    if (date == null) return false;
    return date!.isBefore(DateTime.now().subtract(const Duration(days: 1)));
  }

  String? get propositionUrl =>
      proposition != null ? ApiConstants.mediaPath(proposition!) : null;

  String? get seriesUrl => _absoluteFileUrl(series);
  String? get bemRidersListUrl => _absoluteFileUrl(bemRidersList);
  String? get fullResultsUrl => _absoluteFileUrl(fullResults);
  String? get htmlResultsUrl => _absoluteFileUrl(htmlResults);
  String? get fastRidersUrl => _absoluteFileUrl(fastRiders);
  String? get xlsResultsUrl => _absoluteFileUrl(xlsResults);

  String get webDetailUrl => '${ApiConstants.baseUrl}/event/$id';
  String get webRegistrationUrl => '${ApiConstants.baseUrl}/event/entry/$id';
  String get webForeignRegistrationUrl =>
      '${ApiConstants.baseUrl}/event/entry-foreign/$id';
  String get webPropositionUrl =>
      '${ApiConstants.baseUrl}/event/proposition/$id';
  String get webResultsUrl => '${ApiConstants.baseUrl}/event/results/$id';
  String get webRidersUrl => '${ApiConstants.baseUrl}/event/entry-riders/$id';

  DateTime? get unregisterTo => regCancelTo ?? regOpenTo;

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String)
          : null,
      doubleRace: json['double_race'] as bool? ?? false,
      organizerId: json['organizer'] as int?,
      type: EventType.fromString(json['type_for_ranking'] as String? ?? ''),
      isUciRace: json['is_uci_race'] as bool? ?? false,
      director: _stringOrNull(json['director']),
      regOpenFrom: json['reg_open_from'] != null
          ? DateTime.tryParse(json['reg_open_from'] as String)
          : null,
      regOpenTo: json['reg_open_to'] != null
          ? DateTime.tryParse(json['reg_open_to'] as String)
          : null,
      regCancelTo: json['reg_cancel_to'] != null
          ? DateTime.tryParse(json['reg_cancel_to'] as String)
          : null,
      regOpen: json['reg_open'] as bool? ?? false,
      eshopPickupEnabled: json['eshop_pickup_enabled'] as bool? ?? false,
      eshopPickupLocation: _stringOrNull(json['eshop_pickup_location']),
      eshopPickupTime: _stringOrNull(json['eshop_pickup_time']),
      eshopPickupNote: _stringOrNull(json['eshop_pickup_note']),
      system: _stringOrNull(json['system']),
      youtubeLink: _stringOrNull(json['youtube_link']),
      proposition: _stringOrNull(json['proposition']),
      series: _stringOrNull(json['series']),
      bemRidersList: _stringOrNull(json['bem_riders_list']),
      fullResults: _stringOrNull(json['full_results']),
      htmlResults: _stringOrNull(json['html_results']),
      fastRiders: _stringOrNull(json['fast_riders']),
      xlsResults: _stringOrNull(json['xls_results']),
      uecLink: _stringOrNull(json['uec_link']),
      uciEventCode: _stringOrNull(json['uci_event_code']),
      canceled: json['canceled'] as bool? ?? false,
    );
  }

  static String? _stringOrNull(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _absoluteFileUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    return ApiConstants.mediaPath(value);
  }
}

class PaginatedEvents {
  final int count;
  final String? next;
  final List<EventModel> results;

  const PaginatedEvents({
    required this.count,
    this.next,
    required this.results,
  });

  factory PaginatedEvents.fromJson(dynamic json) {
    if (json is List) {
      final items = json
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return PaginatedEvents(count: items.length, results: items);
    }
    final map = json as Map<String, dynamic>;
    final results = (map['results'] as List<dynamic>)
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedEvents(
      count: map['count'] as int? ?? results.length,
      next: map['next'] as String?,
      results: results,
    );
  }
}
