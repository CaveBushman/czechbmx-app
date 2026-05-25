import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../models/ranking_model.dart';
import '../providers/rankings_provider.dart';

class RankingsScreen extends HookConsumerWidget {
  const RankingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(rankingCategoriesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              floating: true,
              snap: true,
              title: Text(context.l10n.rankings),
              bottom: TabBar(
                tabs: [
                  Tab(text: context.l10n.category20),
                  Tab(text: context.l10n.category24),
                ],
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
              ),
            ),
          ],
          body: categoriesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, _) => _ErrorView(
              error: err,
              onRetry: () => ref.read(rankingCategoriesProvider.notifier).refresh(),
            ),
            data: (allCategories) => TabBarView(
              children: [
                _RankingTab(
                  categories: categories20(allCategories),
                  displayLabel: (c) => c,
                ),
                _RankingTab(
                  categories: categories24(allCategories),
                  displayLabel: displayCategory24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tab ───────────────────────────────────────────────────────────────────────

class _RankingTab extends HookConsumerWidget {
  final List<String> categories;
  final String Function(String) displayLabel;

  const _RankingTab({
    required this.categories,
    required this.displayLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState(categories.isNotEmpty ? categories.first : null);

    useEffect(() {
      if (selected.value == null && categories.isNotEmpty) {
        selected.value = categories.first;
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
            Text(context.l10n.noData, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.colors.border),
            ),
            child: DropdownButton<String>(
              value: selected.value,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: context.colors.card,
              icon: const Icon(Icons.expand_more, color: AppColors.primary),
              style: TextStyle(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              items: categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          displayLabel(c),
                          style: TextStyle(color: context.colors.textPrimary),
                        ),
                      ))
                  .toList(),
              onChanged: (v) => selected.value = v,
            ),
          ),
        ),
        Divider(height: 1, color: context.colors.divider),
        Expanded(
          child: selected.value == null
              ? const SizedBox.shrink()
              : _RankingList(category: selected.value!),
        ),
      ],
    );
  }
}

// ── Ranking list for one category ─────────────────────────────────────────────

class _RankingList extends ConsumerWidget {
  final String category;
  const _RankingList({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(rankingProvider(category));

    return rankingAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: context.colors.textMuted),
              const SizedBox(height: 12),
              Text(err.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(rankingProvider(category)),
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      ),
      data: (riders) {
        if (riders.isEmpty) {
          return Center(
            child: Text(
              context.l10n.noRidersInCategory,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        final leaderPoints = riders.first.points;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: riders.length,
          itemBuilder: (context, i) => _RankRow(
            rider: riders[i],
            leaderPoints: leaderPoints,
          ),
        );
      },
    );
  }
}

// ── Rank row ──────────────────────────────────────────────────────────────────

class _RankRow extends HookWidget {
  final RankedRider rider;
  final int leaderPoints;

  const _RankRow({required this.rider, required this.leaderPoints});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pressed = useState(false);
    final ratio = leaderPoints > 0 ? rider.points / leaderPoints : 0.0;
    final posColor = switch (rider.rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => colors.textMuted,
    };

    return GestureDetector(
      onTap: () => context.go('/riders/${rider.uciId}'),
      onTapDown: (_) => pressed.value = true,
      onTapUp: (_) => pressed.value = false,
      onTapCancel: () => pressed.value = false,
      child: AnimatedScale(
        scale: pressed.value ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            if (colors.brightness == Brightness.light)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
          border: rider.rank <= 3
              ? Border.all(color: posColor.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${rider.rank}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: rider.rank <= 3 ? 18 : 15,
                  fontWeight: FontWeight.w800,
                  color: posColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: rider.photoAbsoluteUrl != null
                  ? CachedNetworkImage(
                      imageUrl: rider.photoAbsoluteUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _avatar(rider, colors),
                    )
                  : _avatar(rider, colors),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rider.fullName,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (rider.club != null && rider.club!.isNotEmpty)
                    Text(
                      rider.club!,
                      style: TextStyle(fontSize: 11, color: colors.textSecondary),
                    ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: colors.brightness == Brightness.dark
                          ? const Color(0xFF334155)
                          : colors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        rider.rank == 1
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${rider.points}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: rider.rank <= 3 ? posColor : colors.textPrimary,
                  ),
                ),
                Text(
                  context.l10n.points,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _avatar(RankedRider rider, AppColorPalette colors) {
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

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

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
            Text(
              context.l10n.rankingsLoadFailed,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
