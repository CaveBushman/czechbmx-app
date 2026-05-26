import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double kFontScaleMin = 0.8;
const double kFontScaleMax = 1.4;
const double kFontScaleDefault = 1.2;
const double kFontScaleStep = 0.1;

final fontScaleProvider =
    AsyncNotifierProvider<FontScaleNotifier, double>(FontScaleNotifier.new);

class FontScaleNotifier extends AsyncNotifier<double> {
  static const _key = 'font_scale';

  @override
  Future<double> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key) ?? kFontScaleDefault;
  }

  Future<void> setScale(double scale) async {
    final clamped = scale.clamp(kFontScaleMin, kFontScaleMax);
    state = AsyncData(clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, clamped);
  }
}
