// Výsledky jednoho závodu — načítají se z /api/events/{id}/results/.
//
// EventResultsData  — obal s event_id a seznamem kategorií
// EventResultCategory — jedna kategorie s výsledkovou listinou
// EventResultEntry  — jeden výsledek (místo, jezdec, klub, body)

class EventResultEntry {
  final int place;
  final String firstName;
  final String lastName;
  final String club;
  final int? uciId;
  final int points;
  final bool is20;

  const EventResultEntry({
    required this.place,
    required this.firstName,
    required this.lastName,
    required this.club,
    this.uciId,
    required this.points,
    required this.is20,
  });

  String get fullName {
    final parts = [firstName, lastName].where((s) => s.isNotEmpty);
    return parts.join(' ');
  }

  factory EventResultEntry.fromJson(Map<String, dynamic> json) =>
      EventResultEntry(
        place: json['place'] as int? ?? 0,
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        club: json['club'] as String? ?? '',
        uciId: json['uci_id'] as int?,
        points: json['points'] as int? ?? 0,
        is20: json['is_20'] as bool? ?? true,
      );
}

class EventResultCategory {
  final String category;
  final List<EventResultEntry> results;

  const EventResultCategory({
    required this.category,
    required this.results,
  });

  factory EventResultCategory.fromJson(Map<String, dynamic> json) =>
      EventResultCategory(
        category: json['category'] as String? ?? '',
        results: (json['results'] as List<dynamic>? ?? [])
            .map((e) => EventResultEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class EventResultsData {
  final int eventId;
  final List<EventResultCategory> categories;

  const EventResultsData({
    required this.eventId,
    required this.categories,
  });

  bool get isEmpty => categories.isEmpty;

  factory EventResultsData.fromJson(Map<String, dynamic> json) =>
      EventResultsData(
        eventId: json['event_id'] as int? ?? 0,
        categories: (json['categories'] as List<dynamic>? ?? [])
            .map((e) =>
                EventResultCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
