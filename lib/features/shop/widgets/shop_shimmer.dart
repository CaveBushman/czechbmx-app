import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';

class ShopGridShimmer extends StatelessWidget {
  const ShopGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Dark: border is lighter than surfaceVariant, giving enough shimmer contrast.
    // Light: card (white) sweeps over the surfaceVariant base.
    final highlight = colors.brightness == Brightness.dark
        ? colors.border
        : colors.card;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => _ProductCardSkeleton(
        colors: colors,
        highlight: highlight,
      ),
    );
  }
}

class _ProductCardSkeleton extends StatelessWidget {
  final AppColorPalette colors;
  final Color highlight;
  const _ProductCardSkeleton({required this.colors, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: colors.surfaceVariant,
      highlightColor: highlight,
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 13,
                    width: double.infinity,
                    color: colors.surfaceVariant,
                  ),
                  const SizedBox(height: 5),
                  Container(height: 11, width: 100, color: colors.surfaceVariant),
                  const SizedBox(height: 8),
                  Container(height: 14, width: 64, color: colors.surfaceVariant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
