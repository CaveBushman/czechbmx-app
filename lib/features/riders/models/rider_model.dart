import '../../../core/constants/api_constants.dart';

class RiderModel {
  final int uciId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String nationality;
  final String? dateOfBirth;
  final String gender;
  final String? photo;
  final int? clubId;
  final bool is20;
  final bool is24;
  final bool isElite;
  final bool isActive;
  final String? class20;
  final String? class24;
  final String? city;
  final String? plateNumber;
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
    this.dateOfBirth,
    required this.gender,
    this.photo,
    this.clubId,
    required this.is20,
    required this.is24,
    required this.isElite,
    required this.isActive,
    this.class20,
    this.class24,
    this.city,
    this.plateNumber,
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

  int? get age {
    if (dateOfBirth == null) return null;
    final dob = DateTime.tryParse(dateOfBirth!);
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      uciId: json['uci_id'] as int,
      firstName: json['first_name'] as String? ?? '',
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String? ?? '',
      nationality: json['nationality'] as String? ?? 'CZE',
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String? ?? '',
      photo: json['photo'] as String?,
      clubId: json['club'] as int?,
      is20: json['is_20'] as bool? ?? false,
      is24: json['is_24'] as bool? ?? false,
      isElite: json['is_elite'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      class20: json['class_20'] as String?,
      class24: json['class_24'] as String?,
      city: json['city'] as String?,
      plateNumber: json['plate_number']?.toString(),
      points20: json['points_20'] as int? ?? 0,
      points24: json['points_24'] as int? ?? 0,
      ranking20: json['ranking_20']?.toString(),
      ranking24: json['ranking_24']?.toString(),
    );
  }
}

class PaginatedRiders {
  final int count;
  final String? next;
  final List<RiderModel> results;

  const PaginatedRiders({required this.count, this.next, required this.results});

  factory PaginatedRiders.fromJson(dynamic json) {
    if (json is List) {
      final items = json.map((e) => RiderModel.fromJson(e as Map<String, dynamic>)).toList();
      return PaginatedRiders(count: items.length, results: items);
    }
    final map = json as Map<String, dynamic>;
    final results = (map['results'] as List<dynamic>)
        .map((e) => RiderModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedRiders(
      count: map['count'] as int? ?? results.length,
      next: map['next'] as String?,
      results: results,
    );
  }
}
