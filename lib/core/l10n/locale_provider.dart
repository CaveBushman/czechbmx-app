import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';

final appLocaleProvider =
    AsyncNotifierProvider<AppLocaleNotifier, Locale?>(AppLocaleNotifier.new);

final currentLocaleCodeProvider = Provider<String>((ref) {
  return ref.watch(appLocaleProvider).valueOrNull?.languageCode ?? 'cs';
});

class AppLocaleNotifier extends AsyncNotifier<Locale?> {
  static const _key = 'app_locale';

  @override
  Future<Locale?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == null || saved == 'system') return null;
    return _supportedOrNull(saved);
  }

  Future<void> setLocale(Locale? locale) async {
    state = AsyncData(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale?.languageCode ?? 'system');
  }

  Locale? _supportedOrNull(String languageCode) {
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == languageCode) return locale;
    }
    return null;
  }
}
