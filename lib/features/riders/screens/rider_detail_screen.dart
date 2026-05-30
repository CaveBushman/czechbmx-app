// Profil jezdce — detailní zobrazení jednoho závodníka.
//
// Načítá data přes riderDetailProvider(uciId) — cache-first (viz rider_provider.dart).
//
// Sekce na obrazovce:
//   SliverAppBar     — foto jezdce (hero animace z listu), jméno, QR kód, oblíbené
//   Identity & klub  — klub, startovní číslo, UCI ID (kliknutím zkopíruje do clipboardu)
//   Kategorie        — 20"/24" třída + ranking badge (top 3 = oranžový gradient)
//   Transpondery     — transponder 20" a 24" (zobrazí se jen pokud jsou vyplněny)
//   Výsledky         — _RiderResultsSection načítá riderResultsProvider(uciId),
//                      zobrazuje výsledky za posledních 365 dní
//
// Sdílení: _showQrDialog() → QR kód s URL czechbmx.cz/jezdci/{uciId} + tlačítko sdílet
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/splash_screen.dart';
import '../models/rider_model.dart';
import '../providers/favorite_riders_provider.dart';
import '../providers/rider_provider.dart';


class RiderDetailScreen extends ConsumerWidget {
  final int uciId;

  const RiderDetailScreen({super.key, required this.uciId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riderAsync = ref.watch(riderDetailProvider(uciId));

    return riderAsync.when(
      loading: () => const SplashScreen(),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            err.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
      data: (rider) => _RiderDetailBody(rider: rider),
    );
  }
}

void _showQrDialog(BuildContext context, RiderModel rider) {
  final url = 'https://czechbmx.cz/jezdci/${rider.uciId}';
  final l10n = AppLocalizations.of(context);
  final textMuted = context.colors.textMuted;

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.riderQrCode),
      content: SizedBox(
        width: 240,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rider.fullName,
              style: Theme.of(ctx).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              url,
              style: Theme.of(ctx)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.close),
        ),
        TextButton(
          onPressed: () {
            Share.share(
              '${l10n.shareProfile}: $url',
              subject: rider.fullName,
            );
          },
          child: Text(l10n.shareProfile),
        ),
      ],
    ),
  );
}

class _RiderDetailBody extends ConsumerWidget {
  final RiderModel rider;

  const _RiderDetailBody({required this.rider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final teamsMap = ref.watch(teamsMapProvider).valueOrNull ?? {};
    final teamName = rider.teamName?.isNotEmpty == true
        ? rider.teamName!
        : (rider.teamId != null ? teamsMap[rider.teamId] : null);
    final class20 = rider.is20
        ? (rider.class20?.isNotEmpty == true ? rider.class20! : '-')
        : context.l10n.doesNotRide;
    final class24 = rider.is24
        ? (rider.class24?.isNotEmpty == true ? rider.class24! : '-')
        : context.l10n.doesNotRide;
    final isFavorite = ref.watch(
      favoriteRidersProvider.select((s) => s.contains(rider.uciId)),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            centerTitle: false,
            titleSpacing: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_outlined),
                tooltip: context.l10n.riderQrCode,
                onPressed: () => _showQrDialog(context, rider),
              ),
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(isFavorite),
                    color: isFavorite ? Colors.redAccent : null,
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(favoriteRidersProvider.notifier).toggle(rider.uciId);
                },
                tooltip: context.l10n.myRiders,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
              title: Text(
                rider.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'rider_avatar_${rider.uciId}',
                    child: rider.photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: rider.photoUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                _AvatarBackground(rider: rider),
                          )
                        : _AvatarBackground(rider: rider),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(gradient: colors.cardOverlay),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + nationality row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rider.fullName,
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _NationalityBadge(nationality: rider.nationality),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (rider.isElite)
                        const _Badge(
                          label: 'Elite',
                          color: AppColors.primary,
                          icon: Icons.star,
                        ),
                      if (rider.is20)
                        _Badge(label: '20"', color: Colors.blue.shade700),
                      if (rider.is24)
                        _Badge(label: '24"', color: Colors.teal.shade600),
                      if (!rider.isActive)
                        _Badge(
                            label: context.l10n.inactive,
                            color: colors.textMuted),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Group: Identity & Club ──
                  _DetailCard(children: [
                    if (teamName != null && teamName.isNotEmpty)
                      _InfoTile(
                        icon: Icons.groups_outlined,
                        label: context.l10n.clubAffiliation,
                        value: teamName,
                      ),
                    if (rider.plateNumber != null && rider.plateNumber!.isNotEmpty)
                      _InfoTile(
                        icon: Icons.confirmation_number_outlined,
                        label: context.l10n.plateNumber,
                        value: rider.plateNumber!,
                      ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: rider.uciId.toString()));
                          HapticFeedback.mediumImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(context.l10n.uciIdCopied),
                                duration: const Duration(seconds: 1)),
                          );
                        },
                        child: _InfoTile(
                          icon: Icons.badge_outlined,
                          label: 'UCI ID',
                          value: rider.uciId.toString(),
                          trailing: const Icon(Icons.copy_outlined,
                              size: 16, color: Colors.grey),
                        ),
                      ),
                    ),
                  ]),

                  // ── Group: Categories & Rankings ──
                  _DetailCard(
                    title: context.l10n.rankings,
                    children: [
                      _InfoTile(
                        icon: Icons.looks_one_outlined,
                        label: context.l10n.category20,
                        value: class20,
                        trailing: rider.ranking20 != null
                            ? _RankingBadge(
                                rank: rider.ranking20!,
                              )
                            : null,
                      ),
                      _InfoTile(
                        icon: Icons.looks_two_outlined,
                        label: context.l10n.category24,
                        value: class24,
                        trailing: rider.ranking24 != null
                            ? _RankingBadge(
                                rank: rider.ranking24!,
                              )
                            : null,
                      ),
                    ],
                  ),

                  // ── Group: Equipment ──
                  if ((rider.transponder20?.isNotEmpty ?? false) || (rider.transponder24?.isNotEmpty ?? false))
                    _DetailCard(
                      title: context.l10n.transponders,
                      children: [
                        if (rider.transponder20 != null && rider.transponder20!.isNotEmpty)
                          _InfoTile(
                            icon: Icons.sensors_outlined,
                            label: context.l10n.transponder20,
                            value: rider.transponder20!,
                          ),
                        if (rider.transponder24 != null && rider.transponder24!.isNotEmpty)
                          _InfoTile(
                            icon: Icons.sensors_outlined,
                            label: context.l10n.transponder24,
                            value: rider.transponder24!,
                          ),
                      ],
                    ),

                  // ── Group: Výsledky za poslední rok ──
                  _RiderResultsSection(uciId: rider.uciId),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Výsledky za poslední rok ──────────────────────────────────────────────────

class _RiderResultsSection extends ConsumerWidget {
  final int uciId;
  const _RiderResultsSection({required this.uciId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(riderResultsProvider(uciId));

    return resultsAsync.when(
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (results) {
        if (results.isEmpty) return const SizedBox.shrink();
        return _DetailCard(
          title: context.l10n.resultsLastYear,
          children: results.map((r) => _ResultTile(result: r)).toList(),
        );
      },
    );
  }
}

class _ResultTile extends StatelessWidget {
  final RiderResult result;
  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateStr = result.date != null
        ? DateFormat('d. M. yyyy').format(result.date!)
        : '';
    final place = result.place;
    final isTop3 = place >= 1 && place <= 3;
    final placeColor = switch (place) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => colors.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border.withValues(alpha: 0.15))),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: placeColor.withValues(alpha: isTop3 ? 0.15 : 0.06),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.eventName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (result.category.isNotEmpty || dateStr.isNotEmpty)
                  Text(
                    [result.category, dateStr].where((s) => s.isNotEmpty).join(' · '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (result.points > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${result.points} b.',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarBackground extends StatelessWidget {
  final RiderModel rider;

  const _AvatarBackground({required this.rider});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Center(
        child: Opacity(
          opacity: 0.2,
          child: Image.asset(
            'assets/images/logo_kruh.png',
            width: 120,
          ),
        ),
      ),
    );
  }
}

class _NationalityBadge extends StatelessWidget {
  final String nationality;

  const _NationalityBadge({required this.nationality});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        nationality,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _RankingBadge extends StatelessWidget {
  final String rank;

  const _RankingBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final isTopThree = ['1', '2', '3'].contains(rank);
    final color = isTopThree ? AppColors.primary : context.colors.textPrimary;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: isTopThree
            ? LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isTopThree ? null : context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isTopThree
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$rank',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isTopThree ? Colors.white : color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.4,
            ),
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
  final Widget? trailing;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  final String? title;

  const _DetailCard({required this.children, this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                title!.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.5,
                      color: AppColors.primary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}
