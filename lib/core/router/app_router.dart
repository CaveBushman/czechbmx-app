import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/events/screens/event_detail_screen.dart';
import '../../features/events/screens/event_registered_riders_screen.dart';
import '../../features/events/screens/events_list_screen.dart';
import '../../features/news/screens/news_detail_screen.dart';
import '../../features/news/screens/news_list_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/rankings/screens/rankings_screen.dart';
import '../../features/riders/screens/rider_detail_screen.dart';
import '../../features/riders/screens/riders_list_screen.dart';
import '../../features/profile/screens/credit_topup_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/shop/screens/cart_screen.dart';
import '../../features/shop/screens/product_detail_screen.dart';
import '../../features/shop/screens/shop_list_screen.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../../features/profile/screens/profile_screen.dart';

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
    initialLocation: '/news',
    refreshListenable: Listenable.merge([authNotifier, onboardingNotifier]),
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Map web-style /event/{id} → app route /events/{id}
      if (loc.startsWith('/event/') && !loc.startsWith('/events/')) {
        return loc.replaceFirst('/event/', '/events/');
      }
      // Map custom scheme paths: czechbmx://news/{slug} → /news/{slug}
      // (GoRouter strips scheme, path arrives as-is)

      // Onboarding: wait until state is known
      final onboarded = onboardingNotifier.value;
      if (onboarded == null) return null; // still loading
      if (!onboarded && loc != '/onboarding') return '/onboarding';

      final authState = authNotifier.value;
      final isLogin = loc == '/login';
      if (authState is AuthAuthenticated && isLogin) return '/news';
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
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
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

class _MainShell extends StatelessWidget {
  final Widget child;

  const _MainShell({required this.child});

  static const _tabs = [
    '/news',
    '/events',
    '/riders',
    '/rankings',
    '/shop',
    '/profile'
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabs.indexWhere((t) => location.startsWith(t));

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
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'search_fab',
        backgroundColor: context.colors.card,
        foregroundColor: context.colors.textPrimary,
        elevation: 2,
        onPressed: () => context.push('/search'),
        tooltip: context.l10n.search,
        child: const Icon(Icons.search_rounded, size: 22),
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
            icon: const Icon(Icons.newspaper_outlined),
            selectedIcon: const Icon(Icons.newspaper, color: AppColors.primary),
            label: context.l10n.news,
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
            icon: const Icon(Icons.shopping_bag_outlined),
            selectedIcon:
                const Icon(Icons.shopping_bag, color: AppColors.primary),
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
