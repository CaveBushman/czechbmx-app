import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/services/home_widget_service.dart';
import '../event_repository.dart';
import '../models/event_model.dart';

final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);

final eventsProvider = AsyncNotifierProvider<EventsNotifier, List<EventModel>>(
  EventsNotifier.new,
);

final eventDetailProvider = FutureProvider.family<EventModel, int>(
  (ref, id) => ref.read(eventRepositoryProvider).fetchEventDetail(id),
);

class EventsNotifier extends AsyncNotifier<List<EventModel>> {
  @override
  Future<List<EventModel>> build() async {
    final year = ref.watch(selectedYearProvider);
    final events =
        await ref.read(eventRepositoryProvider).fetchEvents(year: year);
    _updateWidget(events);
    return events;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final year = ref.read(selectedYearProvider);
    state = await AsyncValue.guard(() async {
      final events = await ref
          .read(eventRepositoryProvider)
          .fetchEvents(year: year, forceRefresh: true);
      _updateWidget(events);
      return events;
    });
  }

  void _updateWidget(List<EventModel> events) {
    HomeWidgetService.updateNextRace(events).ignore();
  }
}

// Group events by month for calendar view
final eventsByMonthProvider = Provider<Map<int, List<EventModel>>>((ref) {
  final events = ref.watch(eventsProvider).valueOrNull ?? [];
  final grouped = <int, List<EventModel>>{};
  for (final event in events) {
    if (event.date != null) {
      final month = event.date!.month;
      grouped.putIfAbsent(month, () => []).add(event);
    }
  }
  return grouped;
});
