class ClubModel {
  final int id;
  final String name;
  final String? fullName;
  final String? city;
  final String? region;
  final String? web;
  final String? facebook;
  final String? instagram;
  final String? contactPerson;
  final String? contactPhone;
  final String? contactEmail;
  final bool haveTrack;
  final double? lat;
  final double? lon;
  final String? openingHours;

  const ClubModel({
    required this.id,
    required this.name,
    this.fullName,
    this.city,
    this.region,
    this.web,
    this.facebook,
    this.instagram,
    this.contactPerson,
    this.contactPhone,
    this.contactEmail,
    this.haveTrack = false,
    this.lat,
    this.lon,
    this.openingHours,
  });

  factory ClubModel.fromJson(Map<String, dynamic> json) => ClubModel(
        id: json['id'] as int,
        name: json['team_name'] as String? ?? '',
        fullName: _nonEmpty(json['club_name']),
        city: _nonEmpty(json['city']),
        region: _nonEmpty(json['region']),
        web: _nonEmpty(json['web']),
        facebook: _nonEmpty(json['facebook']),
        instagram: _nonEmpty(json['instagram']),
        contactPerson: _nonEmpty(json['contact_person']),
        contactPhone: _nonEmpty(json['contact_phone']),
        contactEmail: _nonEmpty(json['contact_email']),
        haveTrack: json['have_track'] as bool? ?? false,
        lat: _nonZeroDouble(json['lat']),
        lon: _nonZeroDouble(json['lon']),
        openingHours: _nonEmpty(json['opening_hours']),
      );

  static String? _nonEmpty(dynamic v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  static double? _nonZeroDouble(dynamic v) {
    if (v == null) return null;
    final d = (v as num).toDouble();
    return d == 0.0 ? null : d;
  }
}
