import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/entries/models/entry_model.dart';
import '../../features/entries/providers/entries_provider.dart';
import '../../features/events/screens/event_detail_screen.dart';
import '../../features/events/screens/events_list_screen.dart';
import '../../features/news/screens/news_detail_screen.dart';
import '../../features/news/screens/news_list_screen.dart';
import '../../features/rankings/screens/rankings_screen.dart';
import '../../features/riders/screens/rider_detail_screen.dart';
import '../../features/riders/screens/riders_list_screen.dart';
import '../../features/profile/screens/credit_topup_screen.dart';
import '../../features/shop/screens/cart_screen.dart';
import '../../features/shop/screens/product_detail_screen.dart';
import '../../features/shop/screens/shop_list_screen.dart';
import '../l10n/app_localizations.dart';
import '../l10n/language_settings_tile.dart';
import '../theme/app_colors.dart';
import '../theme/theme_settings_tile.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<AuthState?>(null);
  ref.onDispose(authNotifier.dispose);

  ref.listen(
    authProvider,
    (_, next) => authNotifier.value = next.valueOrNull,
    fireImmediately: true,
  );

  return GoRouter(
    initialLocation: '/news',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = authNotifier.value;
      final isLogin = state.matchedLocation == '/login';
      if (authState is AuthAuthenticated && isLogin) return '/news';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen()),
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
                  child: EventDetailScreen(
                    id: int.parse(state.pathParameters['id']!),
                  ),
                ),
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
                  child: RiderDetailScreen(
                    uciId: int.parse(state.pathParameters['uciId']!),
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
            builder: (context, state) => const _ProfileScreen(),
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
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: context.colors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
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

// ── Profile screen ────────────────────────────────────────────────────────────

class _ProfileScreen extends HookConsumerWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final photoUploading = useState(false);
    final photoRefreshToken = useState(0);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.profile)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline,
                size: 80,
                color: context.colors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.notLoggedIn,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.ridersLoginRequired,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login),
                label: Text(context.l10n.login),
              ),
              const SizedBox(height: 40),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    LanguageSettingsTile(),
                    SizedBox(height: 12),
                    ThemeSettingsTile(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Future<void> pickAndUploadPhoto() async {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(context.l10n.fromCamera),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(context.l10n.fromGallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null) return;

      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (file == null || !context.mounted) return;

      photoUploading.value = true;
      try {
        final oldPhotoUrl = user.photoUrl;
        final updatedUser =
            await ref.read(authProvider.notifier).updatePhoto(file.path);
        final newPhotoUrl = updatedUser.photoUrl;
        if (oldPhotoUrl != null) {
          await CachedNetworkImage.evictFromCache(oldPhotoUrl);
        }
        if (newPhotoUrl != null && newPhotoUrl != oldPhotoUrl) {
          await CachedNetworkImage.evictFromCache(newPhotoUrl);
        }
        photoRefreshToken.value++;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.photoChanged)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        photoUploading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: context.l10n.logout,
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar with camera button
          Center(
            child: Stack(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: user.photoUrl == null
                        ? AppColors.primaryGradient
                        : null,
                    shape: BoxShape.circle,
                    color: user.photoUrl != null
                        ? context.colors.surfaceVariant
                        : null,
                  ),
                  child: ClipOval(
                    child: user.photoUrl != null
                        ? CachedNetworkImage(
                            key: ValueKey(
                              '${user.photoUrl}-${photoRefreshToken.value}',
                            ),
                            imageUrl: user.photoUrl!,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                            errorWidget: (_, __, ___) => Center(
                              child: Text(
                                user.firstName.isNotEmpty
                                    ? user.firstName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              user.firstName.isNotEmpty
                                  ? user.firstName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: photoUploading.value ? null : pickAndUploadPhoto,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.colors.surface,
                          width: 2,
                        ),
                      ),
                      child: photoUploading.value
                          ? const Padding(
                              padding: EdgeInsets.all(5),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user.fullName,
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
          Center(
            child: Text(
              user.email,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 32),

          // Info tiles
          _InfoTile(
            icon: Icons.email_outlined,
            label: context.l10n.email,
            value: user.email,
          ),
          _CreditTile(credit: user.credit),

          // Linked rider profile
          if (user.isRider && user.riderUciId != null) ...[
            const SizedBox(height: 4),
            _LinkedRiderTile(uciId: user.riderUciId!),
          ],

          // Role badges
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: [
              if (user.isAdmin) const _RoleBadge('Admin', AppColors.primary),
              if (user.isRider) const _RoleBadge('Jezdec', AppColors.success),
              if (user.isClubManager)
                const _RoleBadge('Manažer klubu', Colors.blue),
              if (user.isCommissar) const _RoleBadge('Komisař', Colors.purple),
              if (user.isTrainer) const _RoleBadge('Trenér', Colors.teal),
            ],
          ),

          // My entries
          const SizedBox(height: 28),
          _MyEntriesSection(),

          // Theme settings
          const SizedBox(height: 24),
          const LanguageSettingsTile(),
          const SizedBox(height: 12),
          const ThemeSettingsTile(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── My Entries section ────────────────────────────────────────────────────────

class _MyEntriesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(myEntriesProvider);
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.l10n.myEntries,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () => ref.read(myEntriesProvider.notifier).refresh(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        entriesAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (err, _) => Text(
            err.toString(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    context.l10n.noEntries,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: colors.textMuted),
                  ),
                ),
              );
            }
            return Column(
              children: entries.map((e) => _EntryCard(entry: e)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _EntryCard extends ConsumerWidget {
  final EntryModel entry;
  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final dateStr = entry.eventDate != null
        ? '${entry.eventDate!.day}. ${entry.eventDate!.month}. ${entry.eventDate!.year}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.flag_outlined, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.eventName,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: colors.textMuted),
                  ),
                if (entry.categoryLabel.isNotEmpty)
                  Text(
                    entry.categoryLabel,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: colors.textSecondary),
                  ),
                if (entry.totalFee > 0)
                  Text(
                    '${context.l10n.fee}: ${entry.totalFee} ${context.l10n.czk}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: colors.textMuted),
                  ),
              ],
            ),
          ),
          if (entry.canCancel)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(context.l10n.cancelEntry),
                    content: Text(context.l10n.cancelEntryConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(context.l10n.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: Text(context.l10n.cancelEntry),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  final newBalance = await ref
                      .read(myEntriesProvider.notifier)
                      .cancel(entry.id);
                  if (context.mounted && newBalance != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${context.l10n.creditRefunded}: $newBalance Kč',
                        ),
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: EdgeInsets.zero,
              ),
              child: Text(context.l10n.cancelEntry),
            ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditTile extends StatelessWidget {
  final int credit;

  const _CreditTile({required this.credit});

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
            Icon(Icons.stars_outlined,
                color: context.colors.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.credit,
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    '$credit Kč',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go('/profile/credit'),
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.l10n.topUpCredit),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedRiderTile extends StatelessWidget {
  final int uciId;
  const _LinkedRiderTile({required this.uciId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => context.go('/riders/$uciId'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.directions_bike_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.myRiderProfile,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'UCI ID: $uciId',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall!
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: context.colors.textMuted,
                size: 18,
              ),
            ],
          ),
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
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}
