import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../../core/constants/api_constants.dart';

class EventRegisteredRiders {
  static const uncategorizedCategory = 'Bez kategorie';

  final int eventId;
  final String eventName;
  final List<EventRegisteredRider> riders;

  const EventRegisteredRiders({
    required this.eventId,
    required this.eventName,
    required this.riders,
  });

  int get totalRiders => riders.length;

  Map<String, int> get categoryCounts {
    final counts = <String, int>{};
    for (final rider in riders) {
      counts.update(rider.categoryLabel, (count) => count + 1,
          ifAbsent: () => 1);
    }

    final sortedKeys = counts.keys.toList()..sort();
    return {
      for (final key in sortedKeys) key: counts[key]!,
    };
  }

  List<EventRegisteredRider> ridersForCategory(String? category) {
    if (category == null) return riders;
    return riders.where((rider) => rider.categoryLabel == category).toList();
  }

  factory EventRegisteredRiders.fromHtml({
    required int eventId,
    required String html,
  }) {
    final document = html_parser.parse(html);
    final eventName = _text(document.querySelector('.entry-list-hero h1')) ??
        _text(document.querySelector('h1')) ??
        '';
    final riders = document
        .querySelectorAll('tbody.entry-list-table-body tr, #myTable tbody tr')
        .map(EventRegisteredRider.fromHtmlRow)
        .whereType<EventRegisteredRider>()
        .toList();

    return EventRegisteredRiders(
      eventId: eventId,
      eventName: eventName,
      riders: riders,
    );
  }
}

class EventRegisteredRider {
  final int? uciId;
  final String firstName;
  final String lastName;
  final String clubName;
  final String category;
  final String plateNumber;
  final String? photoUrl;
  final String? detailUrl;

  const EventRegisteredRider({
    this.uciId,
    required this.firstName,
    required this.lastName,
    required this.clubName,
    required this.category,
    required this.plateNumber,
    this.photoUrl,
    this.detailUrl,
  });

  String get fullName {
    final parts = [firstName, lastName].where((part) => part.isNotEmpty);
    return parts.join(' ');
  }

  String get displayName => fullName.isNotEmpty ? fullName : lastName;

  String get categoryLabel => category.isNotEmpty
      ? category
      : EventRegisteredRiders.uncategorizedCategory;

  String get initials {
    final first = firstName.isNotEmpty ? firstName.substring(0, 1) : '';
    final last = lastName.isNotEmpty ? lastName.substring(0, 1) : '';
    final value = '$first$last'.trim();
    return value.isNotEmpty ? value.toUpperCase() : '?';
  }

  static EventRegisteredRider? fromHtmlRow(Element row) {
    final cells = row.querySelectorAll('td');
    if (cells.length < 4) return null;

    final nameCell = cells[0];
    final clubCell = cells[1];
    final categoryCell = cells[2];
    final plateCell = cells[3];
    final detailUrl = _attribute(row, 'data-detail-url');
    final uciId = _intFromText(
      _text(clubCell.querySelector('.entry-list-cell-secondary')) ??
          _uciIdFromDetailUrl(detailUrl),
    );

    final photoSrc = _attribute(nameCell.querySelector('img'), 'src');
    final photoUrl = photoSrc == null ? null : ApiConstants.mediaPath(photoSrc);

    return EventRegisteredRider(
      uciId: uciId,
      lastName: _text(nameCell.querySelector('.entry-list-cell-primary')) ?? '',
      firstName:
          _text(nameCell.querySelector('.entry-list-cell-secondary')) ?? '',
      clubName: _text(clubCell.querySelector('.entry-list-cell-primary')) ?? '',
      category:
          _text(categoryCell.querySelector('.entry-list-cell-secondary')) ??
              _text(categoryCell) ??
              '',
      plateNumber: _text(plateCell) ?? '',
      photoUrl: photoUrl,
      detailUrl: detailUrl,
    );
  }
}

String? _text(Element? element) {
  final text = element?.text.trim().replaceAll(RegExp(r'\s+'), ' ');
  return text == null || text.isEmpty ? null : text;
}

String? _attribute(Element? element, String name) {
  final value = element?.attributes[name]?.trim();
  return value == null || value.isEmpty ? null : value;
}

String? _uciIdFromDetailUrl(String? detailUrl) {
  if (detailUrl == null) return null;
  return RegExp(r'/rider/(\d+)').firstMatch(detailUrl)?.group(1);
}

int? _intFromText(String? value) {
  if (value == null) return null;
  return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
}
