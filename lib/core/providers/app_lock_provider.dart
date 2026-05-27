import 'package:hooks_riverpod/hooks_riverpod.dart';

final appLockProvider = StateNotifierProvider<AppLockNotifier, bool>((ref) {
  return AppLockNotifier();
});

class AppLockNotifier extends StateNotifier<bool> {
  AppLockNotifier() : super(true);

  void unlock() => state = false;
  void lock() => state = true;
}
