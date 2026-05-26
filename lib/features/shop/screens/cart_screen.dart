import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../models/cart_model.dart';
import '../providers/cart_provider.dart';
import '../shop_repository.dart';

class CartScreen extends HookConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);
    final colors = context.colors;

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.cart)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart_outlined,
                  size: 72, color: colors.textMuted),
              const SizedBox(height: 16),
              Text(context.l10n.cartEmpty,
                  style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.cart)),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _CartItemTile(
          item: items[i],
          onRemove: () => cart.remove(items[i].variantId),
          onQuantityChange: (q) => cart.setQuantity(items[i].variantId, q),
        ),
      ),
      bottomNavigationBar: _CheckoutBar(items: items, cart: cart),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final void Function(int) onQuantityChange;

  const _CartItemTile({
    required this.item,
    required this.onRemove,
    required this.onQuantityChange,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Dismissible(
      key: ValueKey(item.variantId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onRemove(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            if (item.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _imgPlaceholder(colors),
                ),
              )
            else
              _imgPlaceholder(colors),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall!
                        .copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.variantLabel,
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.subtotal.toStringAsFixed(0)} Kč',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            _QuantityControl(
              quantity: item.quantity,
              onChanged: onQuantityChange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder(colors) => Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.shopping_bag_outlined,
            size: 28, color: colors.textMuted),
      );
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final void Function(int) onChanged;

  const _QuantityControl({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(
          icon: Icons.remove,
          onTap: () => onChanged(quantity - 1),
          colors: colors,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '$quantity',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        _btn(
          icon: Icons.add,
          onTap: () => onChanged(quantity + 1),
          colors: colors,
        ),
      ],
    );
  }

  Widget _btn(
      {required IconData icon,
      required VoidCallback onTap,
      required colors}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: colors.textPrimary),
      ),
    );
  }
}

class _CheckoutBar extends HookConsumerWidget {
  final List<CartItem> items;
  final CartNotifier cart;

  const _CheckoutBar({required this.items, required this.cart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final total = cart.total;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.divider)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.l10n.total,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${total.toStringAsFixed(0)} Kč',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showCheckout(context, ref),
                child: Text(
                  context.l10n.checkout,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckout(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CheckoutSheet(items: items, cart: cart),
    );
  }
}

class _CheckoutSheet extends HookConsumerWidget {
  final List<CartItem> items;
  final CartNotifier cart;

  const _CheckoutSheet({required this.items, required this.cart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstNameCtrl = useTextEditingController();
    final lastNameCtrl = useTextEditingController();
    final emailCtrl = useTextEditingController();
    final phoneCtrl = useTextEditingController();
    final noteCtrl = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final loading = useState(false);
    final success = useState(false);
    final error = useState<String?>(null);
    final colors = context.colors;

    Future<void> submit() async {
      if (!formKey.currentState!.validate()) return;
      loading.value = true;
      error.value = null;
      try {
        await ref.read(shopRepositoryProvider).checkout(
          firstName: firstNameCtrl.text.trim(),
          lastName: lastNameCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          note: noteCtrl.text.trim(),
          items: items
              .map((e) => {'variant_id': e.variantId, 'quantity': e.quantity})
              .toList(),
        );
        cart.clear();
        success.value = true;
      } catch (e) {
        error.value = e.toString();
      } finally {
        loading.value = false;
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: success.value
            ? _SuccessView(context: context)
            : Form(
                key: formKey,
                child: ListView(
                  controller: scrollCtrl,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    MediaQuery.of(context).viewInsets.bottom + 32,
                  ),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.checkout,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                            child: _Field(
                          controller: firstNameCtrl,
                          label: context.l10n.firstName,
                          required: true,
                        )),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _Field(
                          controller: lastNameCtrl,
                          label: context.l10n.lastName,
                          required: true,
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      controller: emailCtrl,
                      label: context.l10n.email,
                      keyboardType: TextInputType.emailAddress,
                      required: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return context.l10n.invalidEmail;
                        final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(v.trim());
                        return ok ? null : context.l10n.invalidEmail;
                      },
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      controller: phoneCtrl,
                      label: context.l10n.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      controller: noteCtrl,
                      label: context.l10n.note,
                      maxLines: 3,
                    ),
                    if (error.value != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        error.value!,
                        style: const TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: loading.value ? null : submit,
                        child: loading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                context.l10n.checkout,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final BuildContext context;
  const _SuccessView({required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 80, color: AppColors.success),
            const SizedBox(height: 16),
            Text(
              context.l10n.orderSuccess,
              style: Theme.of(ctx).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.orderSuccessDetail,
              style: Theme.of(ctx).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool required;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines,
    this.required = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: colors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty)
                  ? context.l10n.requiredField
                  : null
              : null),
    );
  }
}
