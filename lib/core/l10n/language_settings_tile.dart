import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../theme/app_colors.dart';
import 'app_localizations.dart';
import 'locale_provider.dart';

class LanguageSettingsTile extends ConsumerWidget {
  const LanguageSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current =
        ref.watch(appLocaleProvider).valueOrNull?.languageCode ?? 'system';
    final colors = context.colors;
    final options = <({String code, String label})>[
      (code: 'system', label: 'System'),
      (code: 'cs', label: 'Čeština'),
      (code: 'en', label: 'English'),
      (code: 'de', label: 'Deutsch'),
      (code: 'sk', label: 'Slovenčina'),
      (code: 'es', label: 'Español'),
      (code: 'it', label: 'Italiano'),
      (code: 'fr', label: 'Français'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language, color: colors.textMuted, size: 20),
              const SizedBox(width: 12),
              Text(context.l10n.languageSettings,
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: current,
            decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12)),
            items: options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option.code,
                    child: Text(option.label),
                  ),
                )
                .toList(),
            onChanged: (code) {
              ref.read(appLocaleProvider.notifier).setLocale(
                    code == null || code == 'system' ? null : Locale(code),
                  );
            },
          ),
        ],
      ),
    );
  }
}
