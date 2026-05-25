import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';

class RidersListShimmer extends StatelessWidget {
  const RidersListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: 10,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => _RiderTileSkeleton(colors: colors),
    );
  }
}

class _RiderTileSkeleton extends StatelessWidget {
  final AppColorPalette colors;
  const _RiderTileSkeleton({required this.colors});

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
        height: 64,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(height: 14, width: 160, color: colors.surfaceVariant),
                  const SizedBox(height: 6),
                  Container(height: 11, width: 110, color: colors.surfaceVariant),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                height: 11,
                width: 28,
                color: colors.surfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
