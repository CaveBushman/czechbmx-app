import 'package:home_widget/home_widget.dart';
import '../../features/events/models/event_model.dart';

class HomeWidgetService {
  HomeWidgetService._();

  static const _appGroupId = 'com.example.czechbmx_app';
  static const _qualifiedName =
      'com.example.czechbmx_app.NextRaceWidgetProvider';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> updateNextRace(List<EventModel> events) async {
    final now = DateTime.now();
    final upcoming = events
        .where((e) => e.date != null && !e.date!.isBefore(now))
        .toList()
      ..sort((a, b) => a.date!.compareTo(b.date!));

    final next = upcoming.isNotEmpty ? upcoming.first : null;

    await HomeWidget.saveWidgetData<String>(
      'next_race_name',
      next?.name ?? '',
    );
    await HomeWidget.saveWidgetData<String>(
      'next_race_date',
      next?.date != null
          ? '${next!.date!.year.toString().padLeft(4, '0')}-'
              '${next.date!.month.toString().padLeft(2, '0')}-'
              '${next.date!.day.toString().padLeft(2, '0')}'
          : '',
    );

    await HomeWidget.updateWidget(
      androidName: _qualifiedName,
    );
  }
}
