class ForeignRiderData {
  final bool found;
  final bool isCzech;
  final int? uciId;
  final String firstName;
  final String lastName;
  final String? dateOfBirth;
  final String gender;
  final String nationality;
  final String plate;
  final String transponder20;
  final String transponder24;

  const ForeignRiderData({
    required this.found,
    this.isCzech = false,
    this.uciId,
    this.firstName = '',
    this.lastName = '',
    this.dateOfBirth,
    this.gender = 'Muž',
    this.nationality = '',
    this.plate = '',
    this.transponder20 = '',
    this.transponder24 = '',
  });

  factory ForeignRiderData.notFound() =>
      const ForeignRiderData(found: false);

  factory ForeignRiderData.fromJson(Map<String, dynamic> json) {
    return ForeignRiderData(
      found: json['found'] as bool? ?? false,
      isCzech: json['is_czech'] as bool? ?? false,
      uciId: json['uci_id'] as int?,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String? ?? 'Muž',
      nationality: json['nationality'] as String? ?? '',
      plate: json['plate'] as String? ?? '',
      transponder20: json['transponder_20'] as String? ?? '',
      transponder24: json['transponder_24'] as String? ?? '',
    );
  }
}

class ForeignEntryOption {
  final bool allowed;
  final String? className;
  final int fee;

  const ForeignEntryOption({
    required this.allowed,
    this.className,
    required this.fee,
  });

  factory ForeignEntryOption.fromJson(Map<String, dynamic> json) {
    return ForeignEntryOption(
      allowed: json['allowed'] as bool? ?? false,
      className: json['class'] as String?,
      fee: json['fee'] as int? ?? 0,
    );
  }
}

class ForeignEntryOptions {
  final ForeignEntryOption is20;
  final ForeignEntryOption isElite;
  final ForeignEntryOption is24;

  const ForeignEntryOptions({
    required this.is20,
    required this.isElite,
    required this.is24,
  });

  factory ForeignEntryOptions.fromJson(Map<String, dynamic> json) {
    return ForeignEntryOptions(
      is20: ForeignEntryOption.fromJson(
          json['is_20'] as Map<String, dynamic>? ?? {}),
      isElite: ForeignEntryOption.fromJson(
          json['is_elite'] as Map<String, dynamic>? ?? {}),
      is24: ForeignEntryOption.fromJson(
          json['is_24'] as Map<String, dynamic>? ?? {}),
    );
  }

  int feeFor({required bool is20, required bool isElite, required bool is24}) {
    var total = 0;
    if (is20) total += isElite ? this.isElite.fee : this.is20.fee;
    if (is24) total += this.is24.fee;
    return total;
  }
}

class ForeignEntryInfo {
  final int eventId;
  final String eventName;
  final bool registrationOpen;
  final ForeignRiderData? rider;
  final ForeignEntryOptions? options;

  const ForeignEntryInfo({
    required this.eventId,
    required this.eventName,
    required this.registrationOpen,
    this.rider,
    this.options,
  });

  factory ForeignEntryInfo.fromJson(Map<String, dynamic> json) {
    final rawRider = json['rider'];
    final rawOptions = json['options'];
    return ForeignEntryInfo(
      eventId: json['event_id'] as int,
      eventName: json['event_name'] as String? ?? '',
      registrationOpen: json['registration_open'] as bool? ?? false,
      rider: rawRider != null
          ? ForeignRiderData.fromJson(rawRider as Map<String, dynamic>)
          : null,
      options: rawOptions != null
          ? ForeignEntryOptions.fromJson(rawOptions as Map<String, dynamic>)
          : null,
    );
  }
}

class ForeignEntryResult {
  final int id;
  final String eventName;
  final String riderFirstName;
  final String riderLastName;
  final String uciId;
  final String? class20;
  final String? class24;
  final int totalFee;
  final int newBalance;

  const ForeignEntryResult({
    required this.id,
    required this.eventName,
    required this.riderFirstName,
    required this.riderLastName,
    required this.uciId,
    this.class20,
    this.class24,
    required this.totalFee,
    required this.newBalance,
  });

  String get riderFullName => '$riderFirstName $riderLastName'.trim();

  factory ForeignEntryResult.fromJson(Map<String, dynamic> json) {
    return ForeignEntryResult(
      id: json['id'] as int,
      eventName: json['event_name'] as String? ?? '',
      riderFirstName: json['rider_first_name'] as String? ?? '',
      riderLastName: json['rider_last_name'] as String? ?? '',
      uciId: json['uci_id'] as String? ?? '',
      class20: json['class_20'] as String?,
      class24: json['class_24'] as String?,
      totalFee: json['total_fee'] as int? ?? 0,
      newBalance: json['new_balance'] as int? ?? 0,
    );
  }
}
