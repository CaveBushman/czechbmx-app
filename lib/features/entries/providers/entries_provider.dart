// Entries (přihlášky na závody) — state management.
//
// eventRegisteredRidersProvider(eventId)
//   → FutureProvider.family; stahuje HTML stránku přihlášených jezdců
//     a parsuje ji do EventRegisteredRiders (viz event_registered_rider_model.dart)
//   → Zobrazuje EventRegisteredRidersScreen
//
// myEntriesProvider — AsyncNotifier<List<EntryModel>>
//   → přihlášky přihlášeného uživatele na budoucí závody (/api/entries/my/)
//   → refresh() — explicitní refresh (pull-to-refresh v ProfileScreen)
//   → cancel(entryId) — storno přihlášky → refundace kreditu → update state
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../entries_repository.dart';
import '../models/entry_model.dart';
import '../models/event_registered_rider_model.dart';

final eventRegisteredRidersProvider =
    FutureProvider.family<EventRegisteredRiders, int>(
  (ref, eventId) => ref
      .read(entriesRepositoryProvider)
      .fetchEventRegisteredRiders(eventId: eventId),
);

final myEntriesProvider =
    AsyncNotifierProvider<MyEntriesNotifier, List<EntryModel>>(
  MyEntriesNotifier.new,
);

class MyEntriesNotifier extends AsyncNotifier<List<EntryModel>> {
  @override
  Future<List<EntryModel>> build() =>
      ref.read(entriesRepositoryProvider).fetchMyEntries();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(entriesRepositoryProvider).fetchMyEntries(),
    );
  }

  Future<int?> cancel(int entryId) async {
    final entry = state.valueOrNull?.where((e) => e.id == entryId).firstOrNull;
    final newBalance =
        await ref.read(entriesRepositoryProvider).cancelEntry(entryId);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((e) => e.id != entryId).toList());
    ref.read(authProvider.notifier).refreshUser();
    // Odhlásíme zařízení z FCM topicu — uživatel již není přihlášen na závod.
    if (entry != null) {
      NotificationService.unsubscribeFromEvent(entry.eventId).ignore();
    }
    return newBalance;
  }
}
