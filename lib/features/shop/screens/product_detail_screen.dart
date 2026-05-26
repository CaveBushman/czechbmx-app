import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/shop_provider.dart';

class ProductDetailScreen extends HookConsumerWidget {
  final String slug;

  const ProductDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(shopProductProvider(slug));

    return productAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(err.toString())),
      ),
      data: (product) => _ProductBody(product: product),
    );
  }
}

class _ProductBody extends HookConsumerWidget {
  final ProductModel product;

  const _ProductBody({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVariants =
        product.variants.where((v) => v.inStock).toList();
    final selected = useState<ProductVariantModel?>(
      activeVariants.isNotEmpty ? activeVariants.first : null,
    );
    final added = useState(false);
    final colors = context.colors;

    void addToCart() {
      final v = selected.value;
      if (v == null) return;
      ref.read(cartProvider.notifier).addItem(CartItem(
            variantId: v.id,
            productSlug: product.slug,
            productName: product.name,
            variantLabel: v.label,
            unitPrice: v.price,
            imageUrl: product.imageAbsoluteUrl,
          ));
      added.value = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) added.value = false;
      });
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => context.push('/shop/cart'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageAbsoluteUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageAbsoluteUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(color: colors.surfaceVariant),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.categoryName != null)
                    Text(
                      product.categoryName!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  if (product.subtitle != null && product.subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        product.subtitle!,
                        style: TextStyle(
                            fontSize: 15, color: colors.textSecondary),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Variant selector
                  if (product.variants.isNotEmpty) ...[
                    Text(
                      context.l10n.selectVariant,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.variants.map((v) {
                        final isSelected = selected.value?.id == v.id;
                        return GestureDetector(
                          onTap: v.inStock ? () => selected.value = v : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : v.inStock
                                      ? colors.surfaceVariant
                                      : colors.surfaceVariant
                                          .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : colors.border,
                              ),
                            ),
                            child: Text(
                              v.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : v.inStock
                                        ? colors.textPrimary
                                        : colors.textMuted,
                                decoration: v.inStock
                                    ? null
                                    : TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Price
                  if (selected.value != null) ...[
                    Text(
                      '${selected.value!.price.toStringAsFixed(0)} Kč',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selected.value!.inStock
                          ? context.l10n.inStock
                          : context.l10n.outOfStock,
                      style: TextStyle(
                        fontSize: 13,
                        color: selected.value!.inStock
                            ? AppColors.success
                            : colors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Description / material
                  if (product.description != null &&
                      product.description!.isNotEmpty) ...[
                    Divider(color: colors.divider),
                    const SizedBox(height: 16),
                    Text(
                      product.description!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                  if (product.material != null &&
                      product.material!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _InfoRow(
                        label: context.l10n.material, value: product.material!, colors: colors),
                  ],
                  if (product.fitNote != null && product.fitNote!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                        label: context.l10n.fitNote, value: product.fitNote!, colors: colors),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: added.value ? AppColors.success : AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: (selected.value == null || !selected.value!.inStock)
                  ? null
                  : addToCart,
              icon: Icon(
                  added.value ? Icons.check : Icons.shopping_cart_outlined),
              label: Text(
                added.value
                    ? context.l10n.addedToCart
                    : selected.value == null
                        ? context.l10n.selectVariant
                        : !selected.value!.inStock
                            ? context.l10n.outOfStock
                            : context.l10n.addToCart,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final dynamic colors;

  const _InfoRow(
      {required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ),
      ],
    );
  }
}
