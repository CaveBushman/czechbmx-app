import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/license_provider.dart';

class LicenseResultScreen extends ConsumerWidget {
  final int uciId;

  const LicenseResultScreen({super.key, required this.uciId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final licenseAsync = ref.watch(licenseProvider(uciId));
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.licenseCheck),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: context.l10n.qrScanUciId,
            onPressed: () => context.pushReplacement('/commissar/scan'),
          ),
        ],
      ),
      body: licenseAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
            ],
          ),
        ),
        error: (err, _) {
          final apiErr = err is ApiException ? err : null;
          final code = apiErr?.statusCode;
          final is401 = code == 401;
          final is403 = code == 403;
          final errMsg = apiErr?.message ?? err.toString();

          final IconData icon;
          final String title;
          if (is401) {
            icon = Icons.lock_clock_outlined;
            title = 'Relace vypršela – přihlaste se znovu';
          } else if (is403) {
            icon = Icons.lock_outline;
            title = 'Přístup odepřen';
          } else {
            icon = Icons.error_outline;
            title = context.l10n.riderNotFound;
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errMsg,
                    style: TextStyle(color: colors.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'UCI ID: $uciId',
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  if (is401)
                    FilledButton.icon(
                      onPressed: () => context.go('/login'),
                      icon: const Icon(Icons.login),
                      label: const Text('Přihlásit se'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    )
                  else ...[
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(licenseProvider(uciId)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Zkusit znovu'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.pushReplacement('/commissar/scan'),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: Text(context.l10n.scanQrCode),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        data: (info) {
          final isValid = info.licenseValid;
          final Color statusColor = isValid == true
              ? AppColors.success
              : isValid == false
                  ? AppColors.error
                  : AppColors.warning;
          final IconData statusIcon = isValid == true
              ? Icons.check_circle
              : isValid == false
                  ? Icons.cancel
                  : Icons.help_outline;
          final String statusLabel = isValid == true
              ? context.l10n.licenseValid
              : isValid == false
                  ? context.l10n.licenseInvalid
                  : context.l10n.licenseUnknown;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status banner
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.5),
                        width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Rider card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Row(
                        icon: Icons.person_outline,
                        label: '${context.l10n.firstName} / ${context.l10n.lastName}',
                        value: info.fullName.isNotEmpty
                            ? info.fullName
                            : '—',
                      ),
                      const SizedBox(height: 12),
                      _Row(
                        icon: Icons.badge_outlined,
                        label: 'UCI ID',
                        value: info.uciId.toString(),
                      ),
                      if (info.dateOfBirth?.isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        _Row(
                          icon: Icons.cake_outlined,
                          label: context.l10n.dateOfBirth,
                          value: _formatDate(info.dateOfBirth!),
                        ),
                      ],
                      if (info.gender?.isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        _Row(
                          icon: Icons.wc_outlined,
                          label: context.l10n.gender,
                          value: info.gender == 'M'
                              ? context.l10n.genderMale
                              : info.gender == 'F'
                                  ? context.l10n.genderFemale
                                  : info.gender!,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Scan again
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.pushReplacement('/commissar/scan'),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(context.l10n.scanQrCode),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String isoDate) {
    final parts = isoDate.split('-');
    if (parts.length < 3) return isoDate;
    return '${parts[2]}. ${parts[1]}. ${parts[0]}';
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Row(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      TextStyle(fontSize: 11, color: colors.textMuted)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
