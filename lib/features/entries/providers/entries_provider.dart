import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../entries_repository.dart';
import '../models/entry_model.dart';

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

  Future<void> cancel(int entryId) async {
    await ref.read(entriesRepositoryProvider).cancelEntry(entryId);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((e) => e.id != entryId).toList());
  }
}
