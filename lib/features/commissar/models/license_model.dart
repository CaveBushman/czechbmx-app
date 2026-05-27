class LicenseInfo {
  final int uciId;
  final String firstName;
  final String lastName;
  final String? dateOfBirth;
  final String? gender;
  final bool? licenseValid;

  const LicenseInfo({
    required this.uciId,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
    this.licenseValid,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory LicenseInfo.fromJson(Map<String, dynamic> json) => LicenseInfo(
        uciId: (json['uci_id'] as num?)?.toInt() ?? 0,
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        dateOfBirth: json['date_of_birth'] as String?,
        gender: json['gender'] as String?,
        licenseValid: json['license_valid'] as bool?,
      );
}
