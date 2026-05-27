import 'package:czechbmx_app/features/events/models/event_model.dart';
import 'package:czechbmx_app/features/entries/entries_repository.dart';
import 'package:czechbmx_app/features/entries/models/event_registered_rider_model.dart';
import 'package:czechbmx_app/features/news/models/news_model.dart';
import 'package:czechbmx_app/features/riders/models/rider_model.dart';
import 'package:czechbmx_app/features/riders/rider_repository.dart';
import 'package:czechbmx_app/features/shop/models/product_model.dart';
import 'package:czechbmx_app/features/shop/providers/shop_provider.dart';
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

  group('EventEntryInfo', () {
    test('parses rider name fields', () {
      final info = EventEntryInfo.fromJson({
        'event_id': 10,
        'event_name': 'MASTER CONTEST Moravia',
        'registration_open': true,
        'rider_uci_id': 10047037910,
        'rider_first_name': 'Jan',
        'rider_last_name': 'Novák',
        'options': {
          'is_20': {
            'allowed': true,
            'class': 'Men 17+',
            'fee': 400,
            'already_registered': false,
          },
        },
      });

      expect(info.riderFullName, 'Jan Novák');
      expect(info.riderUciId, 10047037910);
    });
  });

  group('EventRegisteredRiders', () {
    test('parses riders and category counts from public HTML', () {
      final list = EventRegisteredRiders.fromHtml(
        eventId: 311,
        html: '''
          <section class="entry-list-surface">
            <header class="entry-list-hero"><h1>MASTER CONTEST Moravia</h1></header>
            <table id="myTable">
              <tbody class="entry-list-table-body">
                <tr data-detail-url="/rider/10171726962">
                  <td>
                    <img src="/media/images/riders/uni.jpeg" />
                    <div class="entry-list-cell-primary">BITTNER</div>
                    <div class="entry-list-cell-secondary">Jakub Jan</div>
                  </td>
                  <td>
                    <div class="entry-list-cell-primary">BIKE TEAM UNIČOV</div>
                    <div class="entry-list-cell-secondary">10171726962</div>
                  </td>
                  <td><div class="entry-list-cell-secondary">Boys 6</div></td>
                  <td>789</td>
                </tr>
                <tr data-detail-url="/rider/10161378577">
                  <td>
                    <div class="entry-list-cell-primary">BITTNER</div>
                    <div class="entry-list-cell-secondary">Jiří</div>
                  </td>
                  <td>
                    <div class="entry-list-cell-primary">BIKE TEAM UNIČOV</div>
                    <div class="entry-list-cell-secondary">10161378577</div>
                  </td>
                  <td><div class="entry-list-cell-secondary">Boys 9</div></td>
                  <td>901</td>
                </tr>
              </tbody>
            </table>
          </section>
        ''',
      );

      expect(list.eventName, 'MASTER CONTEST Moravia');
      expect(list.totalRiders, 2);
      expect(list.categoryCounts, {'Boys 6': 1, 'Boys 9': 1});
      expect(list.ridersForCategory('Boys 6').single.uciId, 10171726962);
      expect(
        list.ridersForCategory('Boys 6').single.photoUrl,
        'https://czechbmx.cz/media/images/riders/uni.jpeg',
      );
    });
  });

  group('RiderModel', () {
    test('RidersFilter identifies default cacheable queries', () {
      expect(const RidersFilter().isDefault, isTrue);
      expect(const RidersFilter(search: '  ').isDefault, isTrue);
      expect(const RidersFilter(search: 'Novak').isDefault, isFalse);
      expect(const RidersFilter(gender: 'Muž').isDefault, isFalse);
      expect(const RidersFilter(is20: true).isDefault, isFalse);
    });

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
        'club': {'id': 7, 'team_name': 'BMX Praha'},
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
      expect(rider.teamId, 7);
      expect(rider.teamName, 'BMX Praha');
    });
  });

  group('ProductModel', () {
    test('parses numeric fields and category defensively', () {
      final product = ProductModel.fromJson({
        'id': '42',
        'name': null,
        'slug': null,
        'category': '1',
        'category_name': 'Oblečení',
        'total_stock': '8',
        'variants': [
          {
            'id': '9',
            'label': null,
            'price': 'bad-price',
            'stock': '3',
          },
        ],
      });

      expect(product.id, 42);
      expect(product.name, '');
      expect(product.slug, '');
      expect(product.categoryId, 1);
      expect(product.categoryName, 'Oblečení');
      expect(product.totalStock, 8);
      expect(product.variants.single.id, 9);
      expect(product.variants.single.label, '');
      expect(product.variants.single.price, 0);
      expect(product.variants.single.stock, 3);
    });

    test('filters products by selected category slug', () {
      const categories = [
        CategoryModel(id: 1, name: 'Oblečení', slug: 'obleceni'),
        CategoryModel(
          id: 2,
          name: 'Upomínkové předměty',
          slug: 'upominkove-predmety',
        ),
      ];
      const products = [
        ProductModel(
          id: 1,
          name: 'Dres',
          slug: 'dres',
          totalStock: 0,
          variants: [],
          categoryId: 1,
          categoryName: 'Oblečení',
        ),
        ProductModel(
          id: 2,
          name: 'Hrnek',
          slug: 'hrnek',
          totalStock: 5,
          variants: [],
          categoryId: 2,
          categoryName: 'Upomínkové předměty',
        ),
      ];

      final filtered = filterProductsByCategory(
        products: products,
        categories: categories,
        selectedCategorySlug: 'upominkove-predmety',
      );

      expect(filtered.map((p) => p.slug), ['hrnek']);
    });
  });
}
