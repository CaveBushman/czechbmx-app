import 'package:hooks_riverpod/hooks_riverpod.dart';
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
    final newBalance =
        await ref.read(entriesRepositoryProvider).cancelEntry(entryId);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((e) => e.id != entryId).toList());
    ref.read(authProvider.notifier).refreshUser();
    return newBalance;
  }
}
