import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  system('system', 'Dle systému'),
  light('light', 'Světlý'),
  dark('dark', 'Tmavý');

  final String key;
  final String label;
  const AppThemeMode(this.key, this.label);

  ThemeMode get flutterMode => switch (this) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  IconData get icon => switch (this) {
        AppThemeMode.system => Icons.brightness_auto_outlined,
        AppThemeMode.light => Icons.light_mode_outlined,
        AppThemeMode.dark => Icons.dark_mode_outlined,
      };

  static AppThemeMode fromKey(String key) =>
      AppThemeMode.values.firstWhere((e) => e.key == key, orElse: () => AppThemeMode.system);
}

// ── Shared preferences instance ───────────────────────────────────────────────

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (_) => SharedPreferences.getInstance(),
);

// ── Theme mode provider ───────────────────────────────────────────────────────

final themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, AppThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends AsyncNotifier<AppThemeMode> {
  static const _key = 'app_theme_mode';

  @override
  Future<AppThemeMode> build() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final saved = prefs.getString(_key);
    return saved != null ? AppThemeMode.fromKey(saved) : AppThemeMode.system;
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = AsyncData(mode);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_key, mode.key);
  }
}

// ── Convenience: resolved ThemeMode for MaterialApp ──────────────────────────

final resolvedThemeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref.watch(themeModeProvider).valueOrNull ?? AppThemeMode.system;
  return mode.flutterMode;
});
