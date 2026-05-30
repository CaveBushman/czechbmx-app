// Personalizovaný přehled — první záložka aplikace.
//
// Sekce (zobrazují se jen pokud mají obsah):
//   _NextRaceCard       — přihlášený uživatel: jeho příští závod z myEntriesProvider
//                         nepřihlášený: nejbližší nadcházející závod z eventsProvider
//   _FavoriteRidersRow  — horizontální scroll karet oblíbených jezdců s odkazem na detail
//   _UpcomingEventsRow  — horizontální scroll karet příštích 3 závodů
//   _LatestNewsSection  — nejnovějších 5 aktualit (reusuje NewsCard widget)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../entries/models/entry_model.dart';
import '../../entries/providers/entries_provider.dart';
import '../../events/models/event_model.dart';
import '../../events/providers/event_provider.dart';
import '../../news/providers/news_provider.dart';
import '../../news/widgets/news_card.dart';
import '../../riders/models/rider_model.dart';
import '../../riders/providers/favorite_riders_provider.dart';
import '../../riders/providers/rider_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final colors = context.colors;

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(eventsProvider);
          ref.invalidate(newsListProvider);
          if (user != null) ref.invalidate(myEntriesProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: colors.background,
              title: Row(
                children: [
                  Image.asset('assets/images/Logo_kruh.png',
                      width: 28, height: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Czech BMX',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Příští závod ──────────────────────────────────────────
                  _NextRaceSection(isLoggedIn: user != null),
                  const SizedBox(height: 24),

                  // ── Oblíbení jezdci ───────────────────────────────────────
                  _FavoriteRidersSection(),
                  const SizedBox(height: 24),

                  // ── Nadcházející závody ───────────────────────────────────
                  _UpcomingEventsSection(),
                  const SizedBox(height: 24),

                  // ── Nejnovější aktuality ──────────────────────────────────
                  _LatestNewsSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Příští závod ──────────────────────────────────────────────────────────────

class _NextRaceSection extends ConsumerWidget {
  final bool isLoggedIn;
  const _NextRaceSection({required this.isLoggedIn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Zobrazí se jen pokud má přihlášený uživatel konkrétní přihlášku na závod.
    // Nepřihlášený nebo uživatel bez přihlášek → nic (nadcházející závody to pokryjí).
    if (!isLoggedIn) return const SizedBox.shrink();

    final entriesAsync = ref.watch(myEntriesProvider);
    return entriesAsync.when(
      loading: () => const _SectionShimmer(height: 100),
      error: (_, __) => const SizedBox.shrink(),
      data: (entries) {
        final now = DateTime.now();
        final next = entries
            .where((e) => e.eventDate != null && e.eventDate!.isAfter(now))
            .toList()
          ..sort((a, b) => a.eventDate!.compareTo(b.eventDate!));
        if (next.isEmpty) return const SizedBox.shrink();
        return _MyNextRaceCard(entry: next.first);
      },
    );
  }
}

class _MyNextRaceCard extends StatelessWidget {
  final EntryModel entry;
  const _MyNextRaceCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateStr = entry.eventDate != null
        ? DateFormat('d. MMMM yyyy', context.l10n.languageCode)
            .format(entry.eventDate!)
        : '';

    return GestureDetector(
      onTap: () => context.push('/events/${entry.eventId}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.15),
              AppColors.primaryDark.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flag_rounded,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.myNextRace,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.eventName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dateStr.isNotEmpty)
                    Text(dateStr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textMuted,
                            )),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: colors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Oblíbení jezdci ───────────────────────────────────────────────────────────

class _FavoriteRidersSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoriteRidersProvider);
    if (favoriteIds.isEmpty) return const SizedBox.shrink();

    final allRiders = ref.watch(ridersProvider).valueOrNull ?? [];
    final favorites = allRiders
        .where((r) => favoriteIds.contains(r.uciId))
        .toList();
    if (favorites.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: context.l10n.myRiders,
          onTap: () => context.go('/riders'),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) =>
                _FavoriteRiderChip(rider: favorites[i]),
          ),
        ),
      ],
    );
  }
}

class _FavoriteRiderChip extends StatelessWidget {
  final RiderModel rider;
  const _FavoriteRiderChip({required this.rider});

  @override
  Widget build(BuildContext context) {
    final color = context.colors;
    return GestureDetector(
      onTap: () => context.push('/riders/${rider.uciId}'),
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: color.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: rider.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: rider.photoUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          _RiderAvatar(rider: rider),
                    )
                  : _RiderAvatar(rider: rider),
            ),
            const SizedBox(height: 6),
            Text(
              rider.firstName.isNotEmpty ? rider.firstName : rider.fullName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RiderAvatar extends StatelessWidget {
  final RiderModel rider;
  const _RiderAvatar({required this.rider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: AppColors.primary.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          rider.firstName.isNotEmpty ? rider.firstName[0].toUpperCase() : '?',
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary),
        ),
      ),
    );
  }
}

// ── Nadcházející závody ───────────────────────────────────────────────────────

class _UpcomingEventsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    return eventsAsync.when(
      loading: () => const _SectionShimmer(height: 110),
      error: (_, __) => const SizedBox.shrink(),
      data: (events) {
        final now = DateTime.now();
        final upcoming = events
            .where(
                (e) => e.date != null && e.date!.isAfter(now) && !e.canceled)
            .toList()
          ..sort((a, b) => a.date!.compareTo(b.date!));
        if (upcoming.isEmpty) return const SizedBox.shrink();
        final display = upcoming.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: context.l10n.upcomingEvents,
              onTap: () => context.go('/events'),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: display.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) =>
                    _EventChip(event: display[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EventChip extends StatelessWidget {
  final EventModel event;
  const _EventChip({required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateStr = event.date != null
        ? DateFormat('d. M.', context.l10n.languageCode).format(event.date!)
        : '';

    return GestureDetector(
      onTap: () => context.push('/events/${event.id}'),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (event.organizerName != null)
              Text(
                event.organizerName!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                      fontSize: 10,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Nejnovější aktuality ──────────────────────────────────────────────────────

class _LatestNewsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsListProvider);
    return newsAsync.when(
      loading: () => const _SectionShimmer(height: 200),
      error: (_, __) => const SizedBox.shrink(),
      data: (state) {
        if (state.articles.isEmpty) return const SizedBox.shrink();
        final display = state.articles.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: context.l10n.latestNews,
              onTap: () => context.go('/news'),
            ),
            const SizedBox(height: 10),
            ...display.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: NewsCard(
                      news: e.value,
                      featured: e.key == 0,
                    ),
                  ),
                ),
            TextButton(
              onPressed: () => context.go('/news'),
              child: Text(context.l10n.allNews),
            ),
          ],
        );
      },
    );
  }
}

// ── Sdílené pomocné widgety ───────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SectionHeader({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            '›',
            style: TextStyle(
              fontSize: 22,
              color: AppColors.primary,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionShimmer extends StatelessWidget {
  final double height;
  const _SectionShimmer({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
