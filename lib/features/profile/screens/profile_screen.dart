import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/language_settings_tile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_settings_tile.dart';
import '../../../core/widgets/avatar_crop_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../entries/models/entry_model.dart';
import '../../riders/providers/rider_provider.dart';
import '../../entries/providers/entries_provider.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final photoUploading = useState(false);
    // Incremented after a successful upload to bust CachedNetworkImage's disk cache
    // for the same URL (the server reuses the URL, so the old image would show otherwise).
    final photoRefreshToken = useState(0);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.profile)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline,
                size: 80,
                color: context.colors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.notLoggedIn,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.ridersLoginRequired,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login),
                label: Text(context.l10n.login),
              ),
              const SizedBox(height: 40),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    LanguageSettingsTile(),
                    SizedBox(height: 12),
                    ThemeSettingsTile(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Future<void> pickAndUploadPhoto() async {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(context.l10n.fromCamera),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(context.l10n.fromGallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null) return;

      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (file == null || !context.mounted) return;

      final croppedPath = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => AvatarCropScreen(imagePath: file.path),
        ),
      );
      if (croppedPath == null || !context.mounted) return;

      photoUploading.value = true;
      try {
        final oldPhotoUrl = user.photoUrl;
        final updatedUser =
            await ref.read(authProvider.notifier).updatePhoto(croppedPath);
        final newPhotoUrl = updatedUser.photoUrl;
        if (oldPhotoUrl != null) {
          await CachedNetworkImage.evictFromCache(oldPhotoUrl);
        }
        if (newPhotoUrl != null && newPhotoUrl != oldPhotoUrl) {
          await CachedNetworkImage.evictFromCache(newPhotoUrl);
        }
        photoRefreshToken.value++;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.photoChanged)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        photoUploading.value = false;
      }
    }

    final colors = context.colors;
    const avatarSize = 96.0;
    const bannerHeight = 120.0;

    Widget avatarContent = user.photoUrl != null
        ? CachedNetworkImage(
            key: ValueKey('${user.photoUrl}-${photoRefreshToken.value}'),
            imageUrl: user.photoUrl!,
            width: avatarSize,
            height: avatarSize,
            fit: BoxFit.cover,
            placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            errorWidget: (_, __, ___) => _avatarInitial(user.firstName),
          )
        : _avatarInitial(user.firstName);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Header: gradient banner + overlapping avatar ──────────────────
          SizedBox(
            height: bannerHeight + avatarSize / 2,
            child: Stack(
              // Clip.none lets the avatar circle overflow below the banner bottom.
              clipBehavior: Clip.none,
              children: [
                // Gradient banner
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: bannerHeight,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white70),
                          tooltip: context.l10n.logout,
                          onPressed: () => ref.read(authProvider.notifier).logout(),
                        ),
                      ),
                    ),
                  ),
                ),
                // Avatar centered, overlapping banner bottom
                Positioned(
                  top: bannerHeight - avatarSize / 2,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: photoUploading.value ? null : pickAndUploadPhoto,
                      child: Stack(
                        children: [
                          Container(
                            width: avatarSize,
                            height: avatarSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: user.photoUrl == null
                                  ? AppColors.primaryGradient
                                  : null,
                              color: user.photoUrl != null
                                  ? colors.surfaceVariant
                                  : null,
                              border: Border.all(
                                color: colors.background,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(child: avatarContent),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.background, width: 2),
                              ),
                              child: photoUploading.value
                                  ? const Padding(
                                      padding: EdgeInsets.all(5),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Name + email ──────────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Text(user.fullName, style: Theme.of(context).textTheme.displayMedium),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              user.email,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: colors.textMuted),
            ),
          ),

          // ── Role badges ───────────────────────────────────────────────────
          if (user.isAdmin || user.isRider || user.isClubManager || user.isCommissar || user.isTrainer) ...[
            const SizedBox(height: 12),
            Center(
              child: Wrap(
                spacing: 8,
                children: [
                  if (user.isAdmin) const _RoleBadge('Admin', AppColors.primary),
                  if (user.isRider) const _RoleBadge('Jezdec', AppColors.success),
                  if (user.isClubManager) const _RoleBadge('Manažer klubu', Colors.blue),
                  if (user.isCommissar) const _RoleBadge('Komisař', Colors.purple),
                  if (user.isTrainer) const _RoleBadge('Trenér', Colors.teal),
                ],
              ),
            ),
          ],

          // ── Credit + tiles ────────────────────────────────────────────────
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _CreditTile(credit: user.credit),
                _InfoTile(
                  icon: Icons.email_outlined,
                  label: context.l10n.email,
                  value: user.email,
                ),
                if (user.isRider && user.riderUciId != null) ...[
                  const SizedBox(height: 4),
                  _LinkedRiderTile(uciId: user.riderUciId!),
                ] else ...[
                  const SizedBox(height: 8),
                  _PlateRequestTile(),
                ],
                const SizedBox(height: 24),
                const _MyEntriesSection(),
                const SizedBox(height: 24),
                const LanguageSettingsTile(),
                const SizedBox(height: 12),
                const ThemeSettingsTile(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _avatarInitial(String firstName) => Center(
      child: Text(
        firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );

class _MyEntriesSection extends ConsumerWidget {
  const _MyEntriesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(myEntriesProvider);
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.l10n.myEntries,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () => ref.read(myEntriesProvider.notifier).refresh(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        entriesAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (err, _) => Text(
            err.toString(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    context.l10n.noEntries,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: colors.textMuted),
                  ),
                ),
              );
            }
            return Column(
              children: entries.map((e) => _EntryCard(entry: e)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _EntryCard extends ConsumerWidget {
  final EntryModel entry;

  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final dateStr = entry.eventDate != null
        ? '${entry.eventDate!.day}. ${entry.eventDate!.month}. ${entry.eventDate!.year}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20), // Větší radius pro modernější vzhled
        border: Border.all(color: colors.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.flag_outlined, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.eventName,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: colors.textMuted),
                  ),
                if (entry.categoryLabel.isNotEmpty)
                  Text(
                    entry.categoryLabel,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: colors.textSecondary),
                  ),
                if (entry.totalFee > 0)
                  Text(
                    '${context.l10n.fee}: ${entry.totalFee} ${context.l10n.czk}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: colors.textMuted),
                  ),
              ],
            ),
          ),
          if (entry.canCancel)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(context.l10n.cancelEntry),
                    content: Text(context.l10n.cancelEntryConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(context.l10n.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: Text(context.l10n.cancelEntry),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  final newBalance = await ref
                      .read(myEntriesProvider.notifier)
                      .cancel(entry.id);
                  if (context.mounted && newBalance != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${context.l10n.creditRefunded}: $newBalance Kč',
                        ),
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: EdgeInsets.zero,
              ),
              child: Text(context.l10n.cancelEntry),
            ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: context.colors.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class _CreditTile extends StatelessWidget {
  final int credit;

  const _CreditTile({required this.credit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.colors.border.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.stars_outlined,
                color: context.colors.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.credit,
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    '$credit Kč',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go('/profile/credit'),
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.l10n.topUpCredit),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedRiderTile extends ConsumerWidget {
  final int uciId;
  const _LinkedRiderTile({required this.uciId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riderAsync = ref.watch(riderDetailProvider(uciId));
    final rider = riderAsync.valueOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => context.go('/riders/$uciId'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.directions_bike_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.myRiderProfile,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      rider != null ? rider.fullName : 'UCI ID: $uciId',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall!
                          .copyWith(color: AppColors.primary),
                    ),
                    if (rider != null)
                      Text(
                        'UCI ID: $uciId',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: context.colors.textMuted),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: context.colors.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlateRequestTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => context.go('/profile/plate-request'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.confirmation_number_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.requestPlateNumber,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      context.l10n.plateRequestIntro.split('.').first,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(color: context.colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.colors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _RoleBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label.toUpperCase()),
      backgroundColor: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w900,
        fontSize: 10,
      ),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}
