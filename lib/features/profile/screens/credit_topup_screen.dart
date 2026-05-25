import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/in_app_browser.dart';
import '../../auth/providers/auth_provider.dart';

class CreditTopUpScreen extends HookConsumerWidget {
  const CreditTopUpScreen({super.key});

  static const _amounts = [100, 200, 500, 1000, 2000, 5000];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<int?>(null);
    final loading = useState(false);
    final error = useState<String?>(null);
    final customCtrl = useTextEditingController();
    final colors = context.colors;

    useListenable(customCtrl);

    // When user types custom amount, deselect preset
    useEffect(() {
      void listener() {
        if (customCtrl.text.isNotEmpty) selected.value = null;
      }

      customCtrl.addListener(listener);
      return () => customCtrl.removeListener(listener);
    }, [customCtrl]);

    final customValue = int.tryParse(customCtrl.text.trim());
    final customValid =
        customValue != null && customValue >= 100 && customValue <= 10000;
    final effectiveAmount =
        selected.value ?? (customValid ? customValue : null);

    Future<void> proceed() async {
      final amount = effectiveAmount;
      if (amount == null) return;
      loading.value = true;
      error.value = null;
      try {
        final dio = ref.read(dioProvider);
        final response = await dio.post(
          ApiConstants.creditTopUp,
          data: {'amount': amount},
        );
        final url = response.data['checkout_url'] as String?;
        if (url != null && context.mounted) {
          await openInApp(context, url, title: 'Platba kartou');
          ref.read(authProvider.notifier).refreshUser();
        }
      } on DioException catch (e) {
        error.value = ApiException.fromDio(e).message;
      } catch (e) {
        error.value = e.toString();
      } finally {
        loading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.topUpCredit)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.selectAmount,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _amounts.map((amount) {
                final isSelected = selected.value == amount;
                return GestureDetector(
                  onTap: () {
                    selected.value = amount;
                    customCtrl.clear();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 96,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : colors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$amount Kč',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: customCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.l10n.customAmount,
                hintText: context.l10n.minimumAmount,
                suffixText: 'Kč',
                filled: true,
                fillColor: colors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
                errorText: customCtrl.text.isNotEmpty && !customValid
                    ? context.l10n.minimumAmount
                    : null,
              ),
            ),
            if (error.value != null) ...[
              const SizedBox(height: 16),
              Text(
                error.value!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    (effectiveAmount == null || loading.value) ? null : proceed,
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
                        context.l10n.continueToPayment,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
