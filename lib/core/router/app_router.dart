// Navigační konfigurace celé aplikace (GoRouter).
//
// appRouterProvider vytváří GoRouter se dvěma typy routes:
//   1. Standalone routes (bez bottom nav):
//      /onboarding, /login, /register, /search, /commissar/*, /events-map, /clubs/:id
//   2. Shell routes (s bottom nav — _MainShell):
//      /news, /events, /riders, /rankings, /shop, /profile
//
// Redirect logika (vyhodnocuje se při každé navigaci):
//   - Web deep linky: /event/{id} → /events/{id}, /jezdci/{id} → /riders/{id}
//   - Onboarding: pokud nebyl dokončen, přesměruje na /onboarding
//   - Auth: přihlášený uživatel na /login → /news
//   - Commissar routes: přístupné jen pro adminy a komisaře
//
// Přechody:
//   _slideTransition — slide zleva (detail screens)
//   _fadeTransition  — fade (modální screens: login, onboarding)
//
// _MainShell drží NavigationBar (6 záložek) a AnimatedSwitcher mezi nimi.
// _intParamScreen je helper, který bezpečně parsuje int parametr z URL.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/events/screens/event_detail_screen.dart';
import '../../features/events/screens/event_registered_riders_screen.dart';
import '../../features/events/models/event_model.dart' show EventPhoto;
import '../../features/events/screens/event_gallery_screen.dart';
import '../../features/events/screens/event_results_screen.dart';
import '../../features/events/screens/events_list_screen.dart';
import '../../features/news/screens/news_detail_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/news/screens/news_list_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/rankings/screens/rankings_screen.dart';
import '../../features/riders/screens/rider_detail_screen.dart';
import '../../features/riders/screens/riders_list_screen.dart';
import '../../features/commissar/screens/license_result_screen.dart';
import '../../features/commissar/screens/qr_scanner_screen.dart';
import '../../features/clubs/screens/club_detail_screen.dart';
import '../../features/events/screens/events_map_screen.dart';
import '../../features/profile/screens/credit_topup_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/shop/screens/cart_screen.dart';
import '../../features/shop/screens/product_detail_screen.dart';
import '../../features/shop/screens/shop_list_screen.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/riders/screens/plate_request_screen.dart';
import '../../features/shop/providers/cart_provider.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<AuthState?>(null);
  final onboardingNotifier = ValueNotifier<bool?>(null);
  ref.onDispose(authNotifier.dispose);
  ref.onDispose(onboardingNotifier.dispose);

  ref.listen(
    authProvider,
    (_, next) => authNotifier.value = next.valueOrNull,
    fireImmediately: true,
  );

  ref.listen(
    onboardingProvider,
    (_, next) => onboardingNotifier.value = next.valueOrNull,
    fireImmediately: true,
  );

  return GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: '/home',
    refreshListenable: Listenable.merge([authNotifier, onboardingNotifier]),
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Map web-style /event/{id} → app route /events/{id}
      if (loc.startsWith('/event/') && !loc.startsWith('/events/')) {
        return '/events/${loc.substring('/event/'.length)}';
      }
      // Map web-style /jezdci/{uciId} → app route /riders/{uciId}
      if (loc.startsWith('/jezdci/')) {
        return '/riders/${loc.substring('/jezdci/'.length)}';
      }

      // Onboarding: wait until state is known
      final onboarded = onboardingNotifier.value;
      if (onboarded == null) return null; // still loading
      if (!onboarded && loc != '/onboarding') return '/onboarding';

      final authState = authNotifier.value;
      final isLogin = loc == '/login';
      if (authState is AuthAuthenticated && isLogin) return '/home';

      // Commissar routes: only admins and commissars may access them.
      if (loc.startsWith('/commissar/')) {
        final user = authState is AuthAuthenticated ? authState.user : null;
        if (user == null || (!user.isCommissar && !user.isAdmin)) return '/profile';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _fadeTransition(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fadeTransition(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _fadeTransition(
          key: state.pageKey,
          child: const RegisterScreen(),
        ),
      ),
      // Global search — full screen, outside shell (no bottom nav)
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => _slideTransition(
          key: state.pageKey,
          child: const SearchScreen(),
        ),
      ),
      GoRoute(
        path: '/commissar/scan',
        pageBuilder: (context, state) => _slideTransition(
          key: state.pageKey,
          child: const QrScannerScreen(),
        ),
      ),
      GoRoute(
        path: '/commissar/license/:uciId',
        pageBuilder: (context, state) => _slideTransition(
          key: state.pageKey,
          child: _intParamScreen(
            state: state,
            name: 'uciId',
            builder: (uciId) => LicenseResultScreen(uciId: uciId),
          ),
        ),
      ),
      GoRoute(
        path: '/events-map',
        pageBuilder: (context, state) => _slideTransition(
          key: state.pageKey,
          child: const EventsMapScreen(),
        ),
      ),
      GoRoute(
        path: '/clubs/:id',
        pageBuilder: (context, state) => _slideTransition(
          key: state.pageKey,
          child: _intParamScreen(
            state: state,
            name: 'id',
            builder: (id) => ClubDetailScreen(clubId: id),
          ),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/news',
            builder: (context, state) => const NewsListScreen(),
            routes: [
              GoRoute(
                path: ':slug',
                pageBuilder: (context, state) => _slideTransition(
                  key: state.pageKey,
                  child: NewsDetailScreen(slug: state.pathParameters['slug']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/events',
            builder: (context, state) => const EventsListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _slideTransition(
                  key: state.pageKey,
                  child: _intParamScreen(
                    state: state,
                    name: 'id',
                    builder: (id) => EventDetailScreen(id: id),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'riders',
                    pageBuilder: (context, state) => _slideTransition(
                      key: state.pageKey,
                      child: _intParamScreen(
                        state: state,
                        name: 'id',
                        builder: (id) => EventRegisteredRidersScreen(
                          eventId: id,
                        ),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'gallery',
                    pageBuilder: (context, state) => _slideTransition(
                      key: state.pageKey,
                      child: _intParamScreen(
                        state: state,
                        name: 'id',
                        builder: (id) {
                          final extra =
                              state.extra as Map<String, dynamic>? ?? {};
                          return EventGalleryScreen(
                            eventName: extra['name'] as String? ?? '',
                            photos: ((extra['photos'] as List?) ?? [])
                                .whereType<EventPhoto>()
                                .toList(),
                          );
                        },
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'results',
                    pageBuilder: (context, state) => _slideTransition(
                      key: state.pageKey,
                      child: _intParamScreen(
                        state: state,
                        name: 'id',
                        builder: (id) => EventResultsScreen(
                          eventId: id,
                          eventName: state.extra as String? ?? '',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/riders',
            builder: (context, state) => const RidersListScreen(),
            routes: [
              GoRoute(
                path: ':uciId',
                pageBuilder: (context, state) => _slideTransition(
                  key: state.pageKey,
                  child: _intParamScreen(
                    state: state,
                    name: 'uciId',
                    builder: (uciId) => RiderDetailScreen(uciId: uciId),
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/rankings',
            builder: (context, state) => const RankingsScreen(),
          ),
          GoRoute(
            path: '/shop',
            builder: (context, state) => const ShopListScreen(),
            routes: [
              GoRoute(
                path: 'product/:slug',
                pageBuilder: (context, state) => _slideTransition(
                  key: state.pageKey,
                  child: ProductDetailScreen(
                    slug: state.pathParameters['slug']!,
                  ),
                ),
              ),
              GoRoute(
                path: 'cart',
                pageBuilder: (context, state) => _slideTransition(
                  key: state.pageKey,
                  child: const CartScreen(),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'credit',
                pageBuilder: (context, state) => _slideTransition(
                  key: state.pageKey,
                  child: const CreditTopUpScreen(),
                ),
              ),
              GoRoute(
                path: 'plate-request',
                pageBuilder: (context, state) => _slideTransition(
                  key: state.pageKey,
                  child: const PlateRequestScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

Widget _intParamScreen({
  required GoRouterState state,
  required String name,
  required Widget Function(int value) builder,
}) {
  final value = int.tryParse(state.pathParameters[name] ?? '');
  if (value == null) return const _InvalidRouteScreen();
  return builder(value);
}

class _InvalidRouteScreen extends StatelessWidget {
  const _InvalidRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text(context.l10n.loadingFailed)),
    );
  }
}

// ── Transitions ───────────────────────────────────────────────────────────────

CustomTransitionPage<void> _slideTransition({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.5)));

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

CustomTransitionPage<void> _fadeTransition({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

// ── Shell (bottom nav) ────────────────────────────────────────────────────────

class _MainShell extends ConsumerWidget {
  final Widget child;

  const _MainShell({required this.child});

  static const _tabs = [
    '/home',
    '/events',
    '/riders',
    '/rankings',
    '/shop',
    '/profile'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabs.indexWhere((t) => location.startsWith(t));
    final cartCount = ref.watch(cartProvider.notifier).itemCount;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey(currentIndex < 0 ? 0 : currentIndex),
          child: child,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: context.colors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        height: 60,
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home, color: AppColors.primary),
            label: context.l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.flag_outlined),
            selectedIcon: const Icon(Icons.flag, color: AppColors.primary),
            label: context.l10n.events,
          ),
          NavigationDestination(
            icon: const Icon(Icons.directions_bike_outlined),
            selectedIcon:
                const Icon(Icons.directions_bike, color: AppColors.primary),
            label: context.l10n.riders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events_outlined),
            selectedIcon:
                const Icon(Icons.emoji_events, color: AppColors.primary),
            label: context.l10n.rankings,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.shopping_bag, color: AppColors.primary),
            ),
            label: context.l10n.shop,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person, color: AppColors.primary),
            label: context.l10n.profile,
          ),
        ],
      ),
    );
  }
}
