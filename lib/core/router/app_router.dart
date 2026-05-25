import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/events/screens/events_list_screen.dart';
import '../../features/news/screens/news_detail_screen.dart';
import '../../features/news/screens/news_list_screen.dart';
import '../../features/riders/screens/rider_detail_screen.dart';
import '../../features/riders/screens/riders_list_screen.dart';
import '../theme/app_colors.dart';
import '../theme/theme_settings_tile.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<AuthState?>(null);

  ref.listen(authProvider, (_, next) {
    authNotifier.value = next.valueOrNull;
  });

  return GoRouter(
    initialLocation: '/news',
    refreshListenable: authNotifier,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
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
                builder: (context, state) => NewsDetailScreen(
                  slug: state.pathParameters['slug']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/events',
            builder: (context, state) => const EventsListScreen(),
          ),
          GoRoute(
            path: '/riders',
            builder: (context, state) => const RidersListScreen(),
            routes: [
              GoRoute(
                path: ':uciId',
                builder: (context, state) => RiderDetailScreen(
                  uciId: int.parse(state.pathParameters['uciId']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const _ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

// Kept for backward compat — screens still use the singleton during migration
final appRouter = GoRouter(
  initialLocation: '/news',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
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
              builder: (context, state) => NewsDetailScreen(
                slug: state.pathParameters['slug']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/events',
          builder: (context, state) => const EventsListScreen(),
        ),
        GoRoute(
          path: '/riders',
          builder: (context, state) => const RidersListScreen(),
          routes: [
            GoRoute(
              path: ':uciId',
              builder: (context, state) => _ComingSoonScreen(
                title: 'Jezdec #${state.pathParameters['uciId']}',
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const _ProfileScreen(),
        ),
      ],
    ),
  ],
);

// ── Shell (bottom nav) ────────────────────────────────────────────────────────

class _MainShell extends StatelessWidget {
  final Widget child;

  const _MainShell({required this.child});

  static const _tabs = ['/news', '/events', '/riders', '/profile'];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabs.indexWhere((t) => location.startsWith(t));

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: context.colors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper, color: AppColors.primary),
            label: 'Aktuality',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag, color: AppColors.primary),
            label: 'Závody',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bike_outlined),
            selectedIcon: Icon(Icons.directions_bike, color: AppColors.primary),
            label: 'Jezdci',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ── Profile screen ────────────────────────────────────────────────────────────

class _ProfileScreen extends ConsumerWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline, size: 80, color: context.colors.textMuted),
              const SizedBox(height: 16),
              Text('Nejste přihlášeni', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Přihlaste se pro přístup k profilu a dalším funkcím.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login),
                label: const Text('Přihlásit se'),
              ),
              const SizedBox(height: 40),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: ThemeSettingsTile(),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Odhlásit se',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar circle
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(user.fullName, style: Theme.of(context).textTheme.displayMedium),
          ),
          Center(
            child: Text('@${user.username}', style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(height: 32),

          // Info tiles
          _InfoTile(icon: Icons.email_outlined, label: 'E-mail', value: user.email),
          if (user.credit > 0)
            _InfoTile(icon: Icons.stars_outlined, label: 'Kredit', value: '${user.credit} Kč'),

          // Role badges
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: [
              if (user.isAdmin) const _RoleBadge('Admin', AppColors.primary),
              if (user.isRider) const _RoleBadge('Jezdec', AppColors.success),
              if (user.isClubManager) const _RoleBadge('Manažer klubu', Colors.blue),
              if (user.isCommissar) const _RoleBadge('Komisař', Colors.purple),
              if (user.isTrainer) const _RoleBadge('Trenér', Colors.teal),
            ],
          ),

          // Theme settings
          const SizedBox(height: 24),
          const ThemeSettingsTile(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: context.colors.textMuted, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _RoleBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}

// ── Coming soon ───────────────────────────────────────────────────────────────

class _ComingSoonScreen extends StatelessWidget {
  final String title;

  const _ComingSoonScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Připravujeme pro vás', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Sekce $title bude brzy k dispozici.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
