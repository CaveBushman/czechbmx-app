import 'package:czechbmx_app/features/events/models/event_model.dart';
import 'package:czechbmx_app/features/news/models/news_model.dart';
import 'package:czechbmx_app/features/riders/models/rider_model.dart';
import 'package:czechbmx_app/core/constants/api_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiConstants', () {
    test('normalizes relative media paths', () {
      expect(
        ApiConstants.mediaPath('media/news/photo.jpg'),
        'https://czechbmx.cz/media/news/photo.jpg',
      );
      expect(
        ApiConstants.mediaPath('/media/news/photo.jpg'),
        'https://czechbmx.cz/media/news/photo.jpg',
      );
      expect(
        ApiConstants.mediaPath('https://cdn.example.cz/photo.jpg'),
        'https://cdn.example.cz/photo.jpg',
      );
    });
  });

  group('NewsModel', () {
    test('parses paginated responses and builds media URLs', () {
      final page = PaginatedNews.fromJson({
        'count': 1,
        'next': null,
        'previous': null,
        'results': [
          {
            'id': 7,
            'title': 'Novinka',
            'slug': 'novinka',
            'tags': [1, 2],
            'photo_01': '/media/news/photo.jpg',
            'time_to_read': 3,
            'view_count': 12,
            'published_audio': true,
            'on_homepage': false,
            'published': true,
          },
        ],
      });

      expect(page.count, 1);
      expect(page.results.single.identifier, 'novinka');
      expect(
        page.results.single.photo01Url,
        'https://czechbmx.cz/media/news/photo.jpg',
      );
    });
  });

  group('EventModel', () {
    test('maps event type flags and proposition URL', () {
      final event = EventModel.fromJson({
        'id': 10,
        'name': 'Evropský pohár',
        'date': '2026-06-01',
        'double_race': true,
        'type_for_ranking': 'Evropský pohár',
        'is_uci_race': true,
        'reg_open': false,
        'organizer_name': 'BMX Klub Praha',
        'organizer_lat': 50.123,
        'organizer_lon': 14.456,
        'proposition': '/media/events/propozice.pdf',
        'canceled': false,
      });

      expect(event.type, EventType.evropskyPohar);
      expect(event.type.isInternational, isTrue);
      expect(
        event.propositionUrl,
        'https://czechbmx.cz/media/events/propozice.pdf',
      );
      expect(event.organizerName, 'BMX Klub Praha');
      expect(event.organizerLat, 50.123);
      expect(event.organizerLon, 14.456);
      expect(event.hasTrackCoordinates, isTrue);
    });
  });

  group('RiderModel', () {
    test('parses rider categories and ranking fields', () {
      final rider = RiderModel.fromJson({
        'uci_id': 123,
        'first_name': 'Jan',
        'last_name': 'Novak',
        'nationality': 'CZE',
        'gender': 'Muz',
        'is_20': true,
        'is_24': false,
        'is_elite': true,
        'is_active': true,
        'class_20': 'Men Elite',
        'plate_text': '101',
        'transponder_20': 'RX-123',
        'points_20': 150,
        'ranking_20': 1,
      });

      expect(rider.fullName, 'Jan Novak');
      expect(rider.categoryLabel, 'Elite');
      expect(rider.plateNumber, '101');
      expect(rider.transponder20, 'RX-123');
      expect(rider.points20, 150);
      expect(rider.ranking20, '1');
    });
  });
}
