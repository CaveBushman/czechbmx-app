import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../models/rider_model.dart';
import '../providers/rider_provider.dart';

class RiderDetailScreen extends ConsumerWidget {
  final int uciId;

  const RiderDetailScreen({super.key, required this.uciId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riderAsync = ref.watch(riderDetailProvider(uciId));

    return riderAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(err.toString(), style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
      data: (rider) => _RiderDetailBody(rider: rider),
    );
  }
}

class _RiderDetailBody extends StatelessWidget {
  final RiderModel rider;

  const _RiderDetailBody({required this.rider});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            title: Text(rider.fullName, maxLines: 1, overflow: TextOverflow.ellipsis),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (rider.photoUrl != null)
                    CachedNetworkImage(
                      imageUrl: rider.photoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _AvatarBackground(rider: rider),
                    )
                  else
                    _AvatarBackground(rider: rider),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rider.fullName,
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                            if (rider.city != null && rider.city!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on_outlined,
                                        size: 14, color: colors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(rider.city!,
                                        style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
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
                        _Badge(
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
                          label: 'Neaktivní',
                          color: colors.textMuted,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Info tiles
                  if (rider.categoryLabel.isNotEmpty)
                    _InfoTile(
                      icon: Icons.category_outlined,
                      label: 'Kategorie',
                      value: rider.categoryLabel,
                    ),
                  if (rider.dateOfBirth != null)
                    _InfoTile(
                      icon: Icons.cake_outlined,
                      label: 'Datum narození',
                      value: _formatDob(rider.dateOfBirth!, rider.age),
                    ),
                  _InfoTile(
                    icon: rider.gender == 'Žena'
                        ? Icons.female
                        : Icons.male,
                    label: 'Pohlaví',
                    value: rider.gender,
                  ),
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    label: 'UCI ID',
                    value: rider.uciId.toString(),
                  ),
                  if (rider.plateNumber != null && rider.plateNumber!.isNotEmpty)
                    _InfoTile(
                      icon: Icons.confirmation_number_outlined,
                      label: 'Startovní číslo',
                      value: rider.plateNumber!,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDob(String dob, int? age) {
    try {
      final dt = DateTime.parse(dob);
      final formatted = DateFormat('d. MMMM yyyy', 'cs').format(dt);
      return age != null ? '$formatted ($age let)' : formatted;
    } catch (_) {
      return dob;
    }
  }
}

class _AvatarBackground extends StatelessWidget {
  final RiderModel rider;

  const _AvatarBackground({required this.rider});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.surfaceVariant,
      child: Center(
        child: Text(
          rider.firstName.isNotEmpty ? rider.firstName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.w800,
            color: AppColors.primary.withValues(alpha: 0.3),
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
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colors.border),
      ),
      child: Text(
        nationality,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: context.colors.textSecondary,
          letterSpacing: 1,
        ),
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.textMuted, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
