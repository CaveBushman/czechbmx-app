import 'package:czechbmx_app/core/services/home_widget_service.dart';
import 'package:czechbmx_app/features/events/models/event_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('home_widget');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('updates Android widget by fully qualified provider name', () async {
    final today = DateTime.now();
    final tomorrow = DateTime(today.year, today.month, today.day + 1);

    await HomeWidgetService.updateNextRace([
      _event(id: 1, name: 'Zitrek BMX', date: tomorrow),
    ]);

    final updateCall =
        calls.singleWhere((call) => call.method == 'updateWidget');
    final args = Map<String, Object?>.from(updateCall.arguments as Map);

    expect(
      args['qualifiedAndroidName'],
      'com.example.czechbmx_app.NextRaceWidgetProvider',
    );
    expect(args['android'], isNull);
  });
}

EventModel _event({
  required int id,
  required String name,
  required DateTime date,
}) {
  return EventModel(
    id: id,
    name: name,
    date: date,
    doubleRace: false,
    type: EventType.ceskaLiga,
    isUciRace: false,
    regOpen: false,
    eshopPickupEnabled: false,
    canceled: false,
  );
}
