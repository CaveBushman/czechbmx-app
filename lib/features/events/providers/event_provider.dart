import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../event_repository.dart';
import '../models/event_model.dart';

final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);

final eventsProvider = AsyncNotifierProvider<EventsNotifier, List<EventModel>>(
  EventsNotifier.new,
);

final eventDetailProvider = FutureProvider.family<EventModel, int>(
  (ref, id) async {
    final cached = ref
        .read(eventsProvider)
        .valueOrNull
        ?.where((event) => event.id == id)
        .firstOrNull;
    if (cached != null) return cached;
    return ref.read(eventRepositoryProvider).fetchEventDetail(id);
  },
);

class EventsNotifier extends AsyncNotifier<List<EventModel>> {
  @override
  Future<List<EventModel>> build() {
    final year = ref.watch(selectedYearProvider);
    return ref.read(eventRepositoryProvider).fetchEvents(year: year);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final year = ref.read(selectedYearProvider);
    state = await AsyncValue.guard(
      () => ref
          .read(eventRepositoryProvider)
          .fetchEvents(year: year, forceRefresh: true),
    );
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
