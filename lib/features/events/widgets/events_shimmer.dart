import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';

class EventsListShimmer extends StatelessWidget {
  const EventsListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => _EventCardSkeleton(colors: colors),
    );
  }
}

class _EventCardSkeleton extends StatelessWidget {
  final AppColorPalette colors;
  const _EventCardSkeleton({required this.colors});

  @override
  Widget build(BuildContext context) {
    // Dark: border is lighter than surfaceVariant, giving enough shimmer contrast.
    // Light: card (white) sweeps over the surfaceVariant base.
    final highlight = colors.brightness == Brightness.dark
        ? colors.border
        : colors.card;
    return Shimmer.fromColors(
      baseColor: colors.surfaceVariant,
      highlightColor: highlight,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: colors.surfaceVariant, width: 3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 58,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 10, width: 80, color: colors.surfaceVariant),
                  const SizedBox(height: 8),
                  Container(
                    height: 15,
                    width: double.infinity,
                    color: colors.surfaceVariant,
                  ),
                  const SizedBox(height: 6),
                  Container(height: 13, width: 160, color: colors.surfaceVariant),
                  const SizedBox(height: 10),
                  Container(
                    height: 20,
                    width: 70,
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
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
