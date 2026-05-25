class EntryModel {
  final int id;
  final int eventId;
  final String eventName;
  final DateTime? eventDate;
  final int? riderUciId;
  final String riderFirstName;
  final String riderLastName;
  final bool is20;
  final bool is24;
  final bool isBeginner;
  final String? class20;
  final String? class24;
  final int totalFee;
  final bool canCancel;
  final DateTime? transactionDate;

  const EntryModel({
    required this.id,
    required this.eventId,
    required this.eventName,
    this.eventDate,
    this.riderUciId,
    required this.riderFirstName,
    required this.riderLastName,
    required this.is20,
    required this.is24,
    required this.isBeginner,
    this.class20,
    this.class24,
    required this.totalFee,
    required this.canCancel,
    this.transactionDate,
  });

  String get riderFullName => '$riderFirstName $riderLastName'.trim();

  String get categoryLabel {
    final parts = <String>[];
    if (is20 && class20 != null && class20!.isNotEmpty) parts.add('20" $class20');
    if (is24 && class24 != null && class24!.isNotEmpty) parts.add('24" $class24');
    if (isBeginner) parts.add('Začátečník');
    return parts.join(', ');
  }

  factory EntryModel.fromJson(Map<String, dynamic> json) => EntryModel(
        id: json['id'] as int,
        eventId: json['event'] as int,
        eventName: json['event_name'] as String? ?? '',
        eventDate: json['event_date'] != null
            ? DateTime.tryParse(json['event_date'] as String)
            : null,
        riderUciId: json['rider_uci_id'] as int?,
        riderFirstName: json['rider_first_name'] as String? ?? '',
        riderLastName: json['rider_last_name'] as String? ?? '',
        is20: json['is_20'] as bool? ?? false,
        is24: json['is_24'] as bool? ?? false,
        isBeginner: json['is_beginner'] as bool? ?? false,
        class20: json['class_20'] as String?,
        class24: json['class_24'] as String?,
        totalFee: json['total_fee'] as int? ?? 0,
        canCancel: json['can_cancel'] as bool? ?? false,
        transactionDate: json['transaction_date'] != null
            ? DateTime.tryParse(json['transaction_date'] as String)
            : null,
      );
}
