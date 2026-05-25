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
  final DateTime? regOpenFrom;
  final DateTime? regOpenTo;
  final bool regOpen;
  final String? youtubeLink;
  final String? proposition;
  final bool canceled;

  const EventModel({
    required this.id,
    required this.name,
    this.date,
    required this.doubleRace,
    this.organizerId,
    required this.type,
    required this.isUciRace,
    this.regOpenFrom,
    this.regOpenTo,
    required this.regOpen,
    this.youtubeLink,
    this.proposition,
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

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
      doubleRace: json['double_race'] as bool? ?? false,
      organizerId: json['organizer'] as int?,
      type: EventType.fromString(json['type_for_ranking'] as String? ?? ''),
      isUciRace: json['is_uci_race'] as bool? ?? false,
      regOpenFrom: json['reg_open_from'] != null
          ? DateTime.tryParse(json['reg_open_from'] as String)
          : null,
      regOpenTo: json['reg_open_to'] != null
          ? DateTime.tryParse(json['reg_open_to'] as String)
          : null,
      regOpen: json['reg_open'] as bool? ?? false,
      youtubeLink: json['youtube_link'] as String?,
      proposition: json['proposition'] as String?,
      canceled: json['canceled'] as bool? ?? false,
    );
  }
}

class PaginatedEvents {
  final int count;
  final String? next;
  final List<EventModel> results;

  const PaginatedEvents({required this.count, this.next, required this.results});

  factory PaginatedEvents.fromJson(dynamic json) {
    if (json is List) {
      final items = json.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
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
