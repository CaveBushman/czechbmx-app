import 'package:czechbmx_app/features/riders/screens/plate_request_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizePlateRequestGender', () {
    test('maps federation male values to backend form value', () {
      expect(normalizePlateRequestGender('M'), 'Muž');
      expect(normalizePlateRequestGender('male'), 'Muž');
      expect(normalizePlateRequestGender('mužský'), 'Muž');
    });

    test('maps federation female values to backend form value', () {
      expect(normalizePlateRequestGender('F'), 'Žena');
      expect(normalizePlateRequestGender('female'), 'Žena');
      expect(normalizePlateRequestGender('ženský'), 'Žena');
    });

    test('keeps unknown values displayable', () {
      expect(normalizePlateRequestGender('other'), 'Ostatní');
      expect(normalizePlateRequestGender('unknown'), 'Ostatní');
      expect(normalizePlateRequestGender(null), 'Muž');
    });
  });
}
