// Datové modely pro jezdce.
//
// RiderModel       — jeden jezdec z /api/riders/; fromJson() je záměrně tolerantní
//                    (více variant polí pro plate, club — kvůli historickým změnám API)
// RiderResult      — jeden výsledek jezdce z /api/riders/{id}/results/
// PaginatedRiders  — obaluje stránkovanou odpověď (results + next URL)
import '../../../core/constants/api_constants.dart';

class RiderModel {
  final int uciId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String nationality;
  final String gender;
  final String? photo;
  final int? teamId;
  final String? teamName;
  final bool is20;
  final bool is24;
  final bool isElite;
  final bool isActive;
  final String? class20;
  final String? class24;
  final String? plateNumber;
  final String? transponder20;
  final String? transponder24;
  final int points20;
  final int points24;
  final String? ranking20;
  final String? ranking24;

  const RiderModel({
    required this.uciId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.nationality,
    required this.gender,
    this.photo,
    this.teamId,
    this.teamName,
    required this.is20,
    required this.is24,
    required this.isElite,
    required this.isActive,
    this.class20,
    this.class24,
    this.plateNumber,
    this.transponder20,
    this.transponder24,
    this.points20 = 0,
    this.points24 = 0,
    this.ranking20,
    this.ranking24,
  });

  String get fullName {
    final parts = [firstName, if (middleName != null) middleName, lastName];
    return parts.join(' ');
  }

  String? get photoUrl => photo != null ? ApiConstants.mediaPath(photo!) : null;

  String get categoryLabel {
    if (isElite) return is20 ? 'Elite' : 'Elite 24"';
    if (is20 && class20 != null) return class20!;
    if (is24 && class24 != null) return class24!;
    return '';
  }

  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      uciId: _idFromJson(json['uci_id']) ?? 0,
      firstName: _stringFromJson(json['first_name']) ?? '',
      middleName: _stringFromJson(json['middle_name']),
      lastName: _stringFromJson(json['last_name']) ?? '',
      nationality: _stringFromJson(json['nationality']) ?? 'CZE',
      gender: _stringFromJson(json['gender']) ?? '',
      photo: _stringFromJson(json['photo']),
      teamId: _idFromJson(json['team']) ?? _idFromJson(json['club']),
      teamName: _nameFromJson(json['team_name']) ??
          _nameFromJson(json['club_name']) ??
          _nameFromJson(json['team']) ??
          _nameFromJson(json['club']),
      is20: _boolFromJson(json['is_20']),
      is24: _boolFromJson(json['is_24']),
      isElite: _boolFromJson(json['is_elite']),
      isActive: _boolFromJson(json['is_active'], defaultValue: true),
      class20: _stringFromJson(json['class_20']),
      class24: _stringFromJson(json['class_24']),
      plateNumber: (json['plate_text'] ?? json['plate_number'] ?? json['plate'])
          ?.toString(),
      transponder20: json['transponder_20']?.toString(),
      transponder24: json['transponder_24']?.toString(),
      points20: _intFromJson(json['points_20']),
      points24: _intFromJson(json['points_24']),
      ranking20: json['ranking_20']?.toString(),
      ranking24: json['ranking_24']?.toString(),
    );
  }

  static bool _boolFromJson(dynamic value, {bool defaultValue = false}) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    if (value is num) return value != 0;
    return defaultValue;
  }

  static int _intFromJson(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  static String? _stringFromJson(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num) return value.toString();
    return null;
  }

  static int? _idFromJson(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is Map) return _idFromJson(value['id']);
    return null;
  }

  static String? _nameFromJson(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is Map) {
      for (final key in const [
        'team_name',
        'club_name',
        'name',
        'short_name'
      ]) {
        final name = _nameFromJson(value[key]);
        if (name != null) return name;
      }
    }
    return null;
  }
}

class RiderResult {
  final int? eventId;
  final String eventName;
  final DateTime? date;
  final String category;
  final int place;
  final int points;
  final bool is20;
  final bool marked20;
  final bool marked24;

  const RiderResult({
    this.eventId,
    required this.eventName,
    this.date,
    required this.category,
    required this.place,
    required this.points,
    required this.is20,
    required this.marked20,
    required this.marked24,
  });

  factory RiderResult.fromJson(Map<String, dynamic> json) => RiderResult(
        eventId: json['event_id'] as int?,
        eventName: json['event_name'] as String? ?? '',
        date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
        category: json['category'] as String? ?? '',
        place: json['place'] as int? ?? 0,
        points: json['points'] as int? ?? 0,
        is20: json['is_20'] as bool? ?? true,
        marked20: json['marked_20'] as bool? ?? false,
        marked24: json['marked_24'] as bool? ?? false,
      );
}

class PaginatedRiders {
  final int count;
  final String? next;
  final List<RiderModel> results;

  const PaginatedRiders({
    required this.count,
    this.next,
    required this.results,
  });

  factory PaginatedRiders.fromJson(dynamic json) {
    if (json is List) {
      final items = json
          .map((e) => RiderModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return PaginatedRiders(count: items.length, results: items);
    }

    final map = json as Map<String, dynamic>;
    final resultsJson = map['results'] ?? map['data'];
    final resultsList = resultsJson is List ? resultsJson : <dynamic>[];
    final results = resultsList
        .map((e) => RiderModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return PaginatedRiders(
      count: map['count'] as int? ?? results.length,
      next: map['next'] as String?,
      results: results,
    );
  }
}
