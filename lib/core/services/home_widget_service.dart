import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../../core/constants/api_constants.dart';
import '../../features/events/models/event_model.dart';
import '../../features/news/models/news_model.dart';

class HomeWidgetService {
  HomeWidgetService._();

  // Android: SharedPreferences file name (no prefix needed)
  // iOS: App Group ID — must start with "group."
  static const _androidAppGroupId = 'com.example.czechbmx_app';
  static const _iosAppGroupId = 'group.com.example.czechbmxApp';
  static String get _appGroupId =>
      defaultTargetPlatform == TargetPlatform.iOS ? _iosAppGroupId : _androidAppGroupId;

  static const _qualifiedName =
      'com.example.czechbmx_app.NextRaceWidgetProvider';

  static const int _maxCalendarEvents = 20; // Zvýšení limitu pro mapu tratí
  static const int _maxNewsItems = 5;

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> updateNextRace(List<EventModel> events) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final upcoming = events
        .where((e) => e.date != null && !_dateOnly(e.date!).isBefore(todayDate))
        .toList()
      ..sort((a, b) => a.date!.compareTo(b.date!));

    final next = upcoming.isNotEmpty ? upcoming.first : null;

    String name = '';
    String dateStr = '';
    int sameDayCount = 1;

    if (next != null) {
      name = next.name;
      final d = next.date!;
      dateStr = _isoDate(d);
      sameDayCount = upcoming
          .where((e) => _dateOnly(e.date!) == _dateOnly(next.date!))
          .length;
    }

    final double? lat = next?.organizerLat;
    final double? lon = next?.organizerLon;
    final String city = next?.organizerCity ?? '';

    await HomeWidget.saveWidgetData<String>('next_race_name', name);
    await HomeWidget.saveWidgetData<String>('next_race_date', dateStr);
    await HomeWidget.saveWidgetData<int>('next_race_same_day_count', sameDayCount);
    await HomeWidget.saveWidgetData<String>('next_race_city', city);
    if (lat != null) await HomeWidget.saveWidgetData<double>('next_race_lat', lat);
    if (lon != null) await HomeWidget.saveWidgetData<double>('next_race_lon', lon);

    await HomeWidget.updateWidget(qualifiedAndroidName: _qualifiedName);
  }

  /// Aktualizuje databázi tratí pro mapu a Android Auto na základě klubů.
  static Future<void> updateTracksCache(List<Map<String, dynamic>> clubs) async {
    // Filtrujeme pouze kluby, které mají v databázi lat/lng
    final trackClubs = clubs.where((c) {
      final lat = c['lat'];
      final lon = c['lng']; // API obvykle vrací 'lng'
      return lat != null && lon != null;
    }).toList();

    // Pro zachování kompatibility s existujícím car_event klíčem v Android Auto
    await HomeWidget.saveWidgetData<int>('car_events_count', trackClubs.length);
    
    for (var i = 0; i < trackClubs.length; i++) {
      final c = trackClubs[i];
      await HomeWidget.saveWidgetData<String>('car_event_${i}_name', c['team_name'] ?? '');
      await HomeWidget.saveWidgetData<String>('car_event_${i}_city', c['city'] ?? '');
      await HomeWidget.saveWidgetData<String>('car_event_${i}_date', ''); // Tratě nemají datum
      
      final lat = c['lat'];
      final lon = c['lng'];
      
      if (lat is num && lon is num) {
        await HomeWidget.saveWidgetData<double>('car_event_${i}_lat', lat.toDouble());
        await HomeWidget.saveWidgetData<double>('car_event_${i}_lon', lon.toDouble());
      }
    }

    await HomeWidget.updateWidget(qualifiedAndroidName: _qualifiedName);
  }

  static Future<void> updateNewsCache(List<NewsModel> articles) async {
    final items = articles.take(_maxNewsItems).toList();
    await HomeWidget.saveWidgetData<int>('car_news_count', items.length);
    for (var i = 0; i < items.length; i++) {
      final a = items[i];
      await HomeWidget.saveWidgetData<String>('car_news_${i}_title', a.title);
      await HomeWidget.saveWidgetData<String>(
          'car_news_${i}_date', a.publishDate ?? '');
    }
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
