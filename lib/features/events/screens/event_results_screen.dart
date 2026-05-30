// Výsledky závodu — zobrazí výsledkové listiny seřazené podle kategorií.
// Dostupné z tlačítka "Výsledky" v EventDetailScreen (pokud má závod výsledky v DB).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../models/event_results_model.dart';
import '../providers/event_provider.dart';
import '../widgets/result_share_card.dart';

class EventResultsScreen extends ConsumerWidget {
  final int eventId;
  final String eventName;

  const EventResultsScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(eventResultsProvider(eventId));

    return DefaultTabController(
      length: resultsAsync.valueOrNull?.categories.length ?? 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.results),
          bottom: resultsAsync.whenOrNull(
            data: (data) => data.isEmpty
                ? null
                : TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: context.colors.textMuted,
                    tabs: data.categories
                        .map((c) => Tab(text: c.category))
                        .toList(),
                  ),
          ),
        ),
        body: resultsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => _ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(eventResultsProvider(eventId)),
          ),
          data: (data) {
            if (data.isEmpty) {
              return Center(
                child: Text(
                  context.l10n.noResults,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }
            return TabBarView(
              children: data.categories
                  .map((cat) => _CategoryResultsList(
                        category: cat,
                        eventName: eventName,
                      ))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

// ── Výsledková listina jedné kategorie ───────────────────────────────────────

class _CategoryResultsList extends StatelessWidget {
  final EventResultCategory category;
  final String eventName;

  const _CategoryResultsList({
    required this.category,
    required this.eventName,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: category.results.length,
      itemBuilder: (context, index) => _ResultRow(
        entry: category.results[index],
        eventName: eventName,
        categoryLabel: category.category,
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final EventResultEntry entry;
  final String eventName;
  final String categoryLabel;

  const _ResultRow({
    required this.entry,
    required this.eventName,
    required this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final place = entry.place;
    final isTop3 = place >= 1 && place <= 3;
    final placeColor = switch (place) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => colors.textMuted,
    };

    final canTap = entry.uciId != null;

    return InkWell(
      onTap: canTap
          ? () => context.push('/riders/${entry.uciId}')
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Místo
            SizedBox(
              width: 40,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: placeColor.withValues(alpha: isTop3 ? 0.14 : 0.07),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$place.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: placeColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Jméno + klub
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.fullName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (entry.club.isNotEmpty)
                    Text(
                      entry.club,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.textMuted),
                    ),
                ],
              ),
            ),
            // Body
            if (entry.points > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${entry.points} b.',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.share_outlined,
                  size: 18, color: colors.textMuted),
              tooltip: context.l10n.shareResult,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => ResultShareCard.share(
                context,
                entry: entry,
                eventName: eventName,
                category: categoryLabel,
              ),
            ),
            if (canTap)
              Icon(Icons.chevron_right,
                  size: 18, color: colors.textMuted.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.retry),
          ),
        ],
      ),
    );
  }
}
