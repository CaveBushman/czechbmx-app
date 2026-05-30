import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../models/club_model.dart';
import '../providers/club_provider.dart';

class ClubDetailScreen extends ConsumerWidget {
  final int clubId;

  const ClubDetailScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubAsync = ref.watch(clubDetailProvider(clubId));

    return clubAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(e.toString())),
      ),
      data: (club) => _ClubDetailBody(club: club),
    );
  }
}

class _ClubDetailBody extends StatelessWidget {
  final ClubModel club;

  const _ClubDetailBody({required this.club});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final initial = club.name.isNotEmpty ? club.name[0].toUpperCase() : '?';

    final hasSocial =
        club.web != null || club.facebook != null || club.instagram != null;
    final hasContact = club.contactPerson != null ||
        club.contactPhone != null ||
        club.contactEmail != null;
    final hasTrackNav = club.haveTrack && club.lat != null && club.lon != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            title: Text(club.name,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, Color(0xFF0D0F1A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      if (club.city != null || club.region != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.6)),
                            const SizedBox(width: 3),
                            Text(
                              [if (club.city != null) club.city!, if (club.region != null) club.region!].join(', '),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Full name
                if (club.fullName != null &&
                    club.fullName!.trim() != club.name.trim()) ...[
                  Text(
                    club.fullName!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: colors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Track ───────────────────────────────────────────────────
                if (club.haveTrack)
                  _Section(
                    title: 'Trať',
                    children: [
                      _Row(
                        icon: Icons.pedal_bike_outlined,
                        label: 'Vlastní trať',
                        value: club.city != null ? club.city! : 'Ano',
                        trailing: hasTrackNav
                            ? _NavButton(
                                lat: club.lat!,
                                lon: club.lon!,
                                name: club.name)
                            : null,
                      ),
                    ],
                  ),

                // ── Provozní doby ───────────────────────────────────────────
                if (club.openingHours != null &&
                    club.openingHours!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Section(
                    title: context.l10n.openingHours,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Text(
                          club.openingHours!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Contact ─────────────────────────────────────────────────
                if (hasContact) ...[
                  const SizedBox(height: 12),
                  _Section(
                    title: 'Kontakt',
                    children: [
                      if (club.contactPerson != null)
                        _Row(
                            icon: Icons.person_outline,
                            label: 'Osoba',
                            value: club.contactPerson!),
                      if (club.contactPhone != null)
                        _ActionRow(
                          icon: Icons.phone_outlined,
                          label: 'Telefon',
                          value: club.contactPhone!,
                          actionIcon: Icons.phone,
                          onTap: () => launchUrl(
                              Uri.parse('tel:${club.contactPhone}')),
                        ),
                      if (club.contactEmail != null)
                        _ActionRow(
                          icon: Icons.email_outlined,
                          label: 'E-mail',
                          value: club.contactEmail!,
                          actionIcon: Icons.send_outlined,
                          onTap: () => launchUrl(
                              Uri.parse('mailto:${club.contactEmail}')),
                        ),
                    ],
                  ),
                ],

                // ── Online ──────────────────────────────────────────────────
                if (hasSocial) ...[
                  const SizedBox(height: 12),
                  _Section(
                    title: 'Online',
                    children: [
                      if (club.web != null)
                        _LinkRow(
                          icon: Icons.language_outlined,
                          iconColor: const Color(0xFF4CAF50),
                          label: 'Web',
                          value: _shortUrl(club.web!),
                          url: club.web!,
                        ),
                      if (club.facebook != null)
                        _LinkRow(
                          icon: Icons.facebook_outlined,
                          iconColor: const Color(0xFF1877F2),
                          label: 'Facebook',
                          value: _shortUrl(club.facebook!),
                          url: club.facebook!,
                        ),
                      if (club.instagram != null)
                        _LinkRow(
                          icon: Icons.camera_alt_outlined,
                          iconColor: const Color(0xFFE1306C),
                          label: 'Instagram',
                          value: _shortUrl(club.instagram!),
                          url: club.instagram!,
                        ),
                    ],
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static String _shortUrl(String url) {
    return url
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'^www\.'), '')
        .replaceFirst(RegExp(r'/$'), '');
  }
}

// ── Section wrapper ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                      height: 1,
                      indent: 56,
                      color: colors.border.withValues(alpha: 0.4)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Row variants ─────────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _Row(
      {required this.icon,
      required this.label,
      required this.value,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.textMuted)),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final IconData actionIcon;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.actionIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Row(
      icon: icon,
      label: label,
      value: value,
      trailing: IconButton(
        icon: Icon(actionIcon, color: AppColors.primary, size: 20),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String url;

  const _LinkRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.textMuted)),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 15, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Navigation button ─────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final double lat;
  final double lon;
  final String name;

  const _NavButton(
      {required this.lat, required this.lon, required this.name});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.navigation_outlined, size: 16),
      label: const Text('Navigovat'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      onPressed: () async {
        final label = Uri.encodeComponent(name);
        final geoUri = Uri.parse('geo:$lat,$lon?q=$lat,$lon($label)');
        if (await canLaunchUrl(geoUri)) {
          await launchUrl(geoUri);
          return;
        }
        final webUri = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
