import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../riders/models/rider_model.dart';
import '../providers/rankings_provider.dart';

class RankingsScreen extends HookConsumerWidget {
  const RankingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridersAsync = ref.watch(allRidersProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              floating: true,
              snap: true,
              title: const Text('Žebříček'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: '20"'),
                  Tab(text: '24"'),
                ],
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
              ),
            ),
          ],
          body: ridersAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, _) => _ErrorView(
              message: err.toString(),
              onRetry: () => ref.read(allRidersProvider.notifier).refresh(),
            ),
            data: (riders) => TabBarView(
              children: [
                _RankingTab(
                  riders: riders,
                  is24: false,
                  categories: _activeCategories(riders, false),
                ),
                _RankingTab(
                  riders: riders,
                  is24: true,
                  categories: _activeCategories(riders, true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Only include categories that have at least one rider with points > 0
  List<String> _activeCategories(List<RiderModel> riders, bool is24) {
    final allCats = is24 ? kCategories24 : kCategories20;
    return allCats.where((cat) {
      return riders.any((r) {
        if (!r.isActive) return false;
        if (is24) return r.class24 == cat && r.points24 > 0;
        return r.class20 == cat && r.points20 > 0;
      });
    }).toList();
  }
}

// ── Tab for 20" or 24" ───────────────────────────────────────────────────────

class _RankingTab extends HookWidget {
  final List<RiderModel> riders;
  final bool is24;
  final List<String> categories;

  const _RankingTab({
    required this.riders,
    required this.is24,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final selectedCat = useState(categories.isNotEmpty ? categories.first : null);

    // Re-select if categories change (e.g., refresh)
    useEffect(() {
      if (selectedCat.value == null && categories.isNotEmpty) {
        selectedCat.value = categories.first;
      }
      return null;
    }, [categories]);

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: context.colors.textMuted),
            const SizedBox(height: 16),
            Text('Žádná data', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      );
    }

    final ranked = _buildRanking(riders, selectedCat.value, is24);
    final leaderPoints = ranked.isNotEmpty
        ? (is24 ? ranked.first.points24 : ranked.first.points20)
        : 1;

    return Column(
      children: [
        // Category chips
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = categories[i];
              final selected = cat == selectedCat.value;
              return GestureDetector(
                onTap: () => selectedCat.value = cat,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.primary : context.colors.border,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : context.colors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Divider(height: 1, color: context.colors.divider),
        // Leaderboard
        Expanded(
          child: ranked.isEmpty
              ? Center(
                  child: Text(
                    'Žádní jezdci v kategorii',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: ranked.length,
                  itemBuilder: (context, i) => _RankRow(
                    rider: ranked[i],
                    position: i + 1,
                    is24: is24,
                    leaderPoints: leaderPoints,
                  ),
                ),
        ),
      ],
    );
  }

  List<RiderModel> _buildRanking(
    List<RiderModel> riders,
    String? category,
    bool is24,
  ) {
    if (category == null) return [];
    final filtered = riders.where((r) {
      if (!r.isActive) return false;
      if (is24) return r.class24 == category && r.points24 > 0;
      return r.class20 == category && r.points20 > 0;
    }).toList();
    filtered.sort((a, b) => is24
        ? b.points24.compareTo(a.points24)
        : b.points20.compareTo(a.points20));
    return filtered;
  }
}

// ── Rank row ─────────────────────────────────────────────────────────────────

class _RankRow extends StatelessWidget {
  final RiderModel rider;
  final int position;
  final bool is24;
  final int leaderPoints;

  const _RankRow({
    required this.rider,
    required this.position,
    required this.is24,
    required this.leaderPoints,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final points = is24 ? rider.points24 : rider.points20;
    final ratio = leaderPoints > 0 ? points / leaderPoints : 0.0;

    final posColor = switch (position) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => colors.textMuted,
    };

    return GestureDetector(
      onTap: () => context.go('/riders/${rider.uciId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(10),
          border: position <= 3
              ? Border.all(color: posColor.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          children: [
            // Position
            SizedBox(
              width: 32,
              child: Text(
                '$position',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: position <= 3 ? 18 : 15,
                  fontWeight: FontWeight.w800,
                  color: posColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: rider.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: rider.photoUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _avatar(rider, colors),
                    )
                  : _avatar(rider, colors),
            ),
            const SizedBox(width: 12),
            // Name + bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rider.fullName,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (rider.city != null && rider.city!.isNotEmpty)
                    Text(
                      rider.city!,
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                  const SizedBox(height: 5),
                  // Points bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: colors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        position == 1 ? AppColors.primary : AppColors.primary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$points',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: position <= 3 ? posColor : colors.textPrimary,
                  ),
                ),
                Text(
                  'bodů',
                  style: TextStyle(fontSize: 10, color: colors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(RiderModel rider, AppColorPalette colors) {
    return Container(
      width: 44,
      height: 44,
      color: colors.surfaceVariant,
      child: Center(
        child: Text(
          rider.firstName.isNotEmpty ? rider.firstName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ── Error state ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: context.colors.textMuted),
            const SizedBox(height: 16),
            Text('Nepodařilo se načíst žebříček',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Zkusit znovu'),
            ),
          ],
        ),
      ),
    );
  }
}
