// Events state management — seznam závodů a detail závodu.
//
// selectedYearProvider    — vybraný rok v filtru závodů (default = aktuální rok)
// eventsProvider          — AsyncNotifier<List<EventModel>>; seznam závodů za vybraný rok
//   Po načtení aktualizuje HomeWidget (widget na ploše telefonu) s info o příštím závodě.
// eventDetailProvider(id) — FutureProvider.family; detail jednoho závodu z /api/events/{id}/
// eventResultsProvider(id)— FutureProvider.family; výsledky závodu z /api/events/{id}/results/
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/services/home_widget_service.dart';
import '../event_repository.dart';
import '../models/event_model.dart';
import '../models/event_results_model.dart';

final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);

final eventsProvider = AsyncNotifierProvider<EventsNotifier, List<EventModel>>(
  EventsNotifier.new,
);

final eventDetailProvider = FutureProvider.family<EventModel, int>(
  (ref, id) => ref.read(eventRepositoryProvider).fetchEventDetail(id),
);

final eventResultsProvider = FutureProvider.family<EventResultsData, int>(
  (ref, id) => ref.read(eventRepositoryProvider).fetchEventResults(id),
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
