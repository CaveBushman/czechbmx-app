import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/locale_provider.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/providers/deep_link_provider.dart';
import 'core/providers/font_scale_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/home_widget_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/splash_screen.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await HomeWidgetService.init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: CzechBmxApp()));
}

class CzechBmxApp extends ConsumerWidget {
  const CzechBmxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(resolvedThemeModeProvider);
    final locale = ref.watch(appLocaleProvider).valueOrNull;
    final router = ref.watch(appRouterProvider);
    final authAsync = ref.watch(authProvider);
    final isOffline = ref.watch(isOfflineProvider);
    final fontScale = ref.watch(fontScaleProvider).valueOrNull ?? kFontScaleDefault;

    // Cold-start deep link: navigate once the router is ready.
    ref.listen(initialDeepLinkProvider, (_, next) {
      next.whenData((path) {
        if (path != null) router.go(path);
      });
    });

    // Warm-start deep link: app was running when the link arrived.
    ref.listen(deepLinkStreamProvider, (_, next) {
      next.whenData((path) => router.go(path));
    });

    return MaterialApp.router(
      title: 'Czech BMX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
      builder: (context, child) {
        final isLoading = authAsync is AsyncLoading;

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(fontScale),
          ),
          child: Stack(
            children: [
              child!,
              // Offline banner — slides down from the top when no connection.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: AnimatedSlide(
                    offset: isOffline ? Offset.zero : const Offset(0, -1),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    child: IgnorePointer(
                      ignoring: !isOffline,
                      child: const _OfflineBanner(),
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: isLoading
                    ? const SplashScreen(key: ValueKey('splash'))
                    : const SizedBox.shrink(key: ValueKey('none')),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFB71C1C),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                context.l10n.offline,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
