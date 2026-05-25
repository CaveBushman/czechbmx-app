import '../../../core/constants/api_constants.dart';

class RankedRider {
  final int rank;
  final int uciId;
  final String firstName;
  final String lastName;
  final String? club;
  final String? photoUrl;
  final int points;
  final String? ranking;

  const RankedRider({
    required this.rank,
    required this.uciId,
    required this.firstName,
    required this.lastName,
    this.club,
    this.photoUrl,
    required this.points,
    this.ranking,
  });

  String get fullName => '$firstName $lastName'.trim();

  String? get photoAbsoluteUrl =>
      photoUrl != null ? ApiConstants.mediaPath(photoUrl!) : null;

  factory RankedRider.fromJson(Map<String, dynamic> json) => RankedRider(
        rank: json['rank'] as int,
        uciId: json['uci_id'] as int,
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        club: json['club'] as String?,
        photoUrl: json['photo_url'] as String?,
        points: json['points'] as int? ?? 0,
        ranking: json['ranking']?.toString(),
      );
}
