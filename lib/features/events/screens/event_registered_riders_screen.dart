import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../entries/models/event_registered_rider_model.dart';
import '../../entries/providers/entries_provider.dart';

const _allCategoriesValue = '__all__';

class EventRegisteredRidersScreen extends ConsumerStatefulWidget {
  final int eventId;

  const EventRegisteredRidersScreen({
    super.key,
    required this.eventId,
  });

  @override
  ConsumerState<EventRegisteredRidersScreen> createState() =>
      _EventRegisteredRidersScreenState();
}

class _EventRegisteredRidersScreenState
    extends ConsumerState<EventRegisteredRidersScreen> {
  String _selectedCategory = _allCategoriesValue;

  @override
  Widget build(BuildContext context) {
    final ridersAsync =
        ref.watch(eventRegisteredRidersProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.registeredRiders)),
      body: ridersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(
            eventRegisteredRidersProvider(widget.eventId),
          ),
        ),
        data: _buildContent,
      ),
    );
  }

  Widget _buildContent(EventRegisteredRiders data) {
    final categoryCounts = data.categoryCounts;
    final selectedCategory = categoryCounts.containsKey(_selectedCategory)
        ? _selectedCategory
        : _allCategoriesValue;
    final visibleRiders = data.ridersForCategory(
      selectedCategory == _allCategoriesValue ? null : selectedCategory,
    );
    final selectedCount = visibleRiders.length;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(eventRegisteredRidersProvider(widget.eventId));
        await ref.read(eventRegisteredRidersProvider(widget.eventId).future);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (data.eventName.isNotEmpty) ...[
                    Text(
                      data.eventName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _CategoryFilter(
                    selectedCategory: selectedCategory,
                    totalCount: data.totalRiders,
                    categoryCounts: categoryCounts,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value ?? _allCategoriesValue;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _CountPanel(
                    selectedCategory: selectedCategory,
                    selectedCount: selectedCount,
                    totalCount: data.totalRiders,
                  ),
                ],
              ),
            ),
          ),
          if (visibleRiders.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  context.l10n.noRiders,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList.separated(
                itemCount: visibleRiders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _RegisteredRiderTile(
                  rider: visibleRiders[index],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final String selectedCategory;
  final int totalCount;
  final Map<String, int> categoryCounts;
  final ValueChanged<String?> onChanged;

  const _CategoryFilter({
    required this.selectedCategory,
    required this.totalCount,
    required this.categoryCounts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(selectedCategory),
      initialValue: selectedCategory,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: context.l10n.category,
        prefixIcon: const Icon(Icons.filter_list),
      ),
      items: [
        DropdownMenuItem(
          value: _allCategoriesValue,
          child: Text('${context.l10n.allCategories} ($totalCount)'),
        ),
        ...categoryCounts.entries.map(
          (entry) => DropdownMenuItem(
            value: entry.key,
            child: Text('${entry.key} (${entry.value})'),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _CountPanel extends StatelessWidget {
  final String selectedCategory;
  final int selectedCount;
  final int totalCount;

  const _CountPanel({
    required this.selectedCategory,
    required this.selectedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isAll = selectedCategory == _allCategoriesValue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.groups_outlined, color: colors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAll ? context.l10n.totalRegistered : context.l10n.ridersInCategory,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: colors.textSecondary),
            ),
          ),
          Text(
            isAll ? '$totalCount' : '$selectedCount',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _RegisteredRiderTile extends StatelessWidget {
  final EventRegisteredRider rider;

  const _RegisteredRiderTile({required this.rider});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canOpenDetail =
        rider.uciId != null && rider.detailUrl?.startsWith('/rider/') == true;

    return InkWell(
      onTap:
          canOpenDetail ? () => context.push('/riders/${rider.uciId}') : null,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RiderAvatar(rider: rider),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rider.firstName.isNotEmpty
                        ? '${rider.firstName} ${rider.lastName}'
                        : rider.lastName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MetaChip(
                        icon: Icons.category_outlined,
                        label: rider.categoryLabel,
                      ),
                      if (rider.plateNumber.isNotEmpty)
                        _MetaChip(
                          icon: Icons.pin_outlined,
                          label: rider.plateNumber,
                        ),
                    ],
                  ),
                  if (rider.clubName.isNotEmpty || rider.uciId != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      [
                        if (rider.clubName.isNotEmpty) rider.clubName,
                        if (rider.uciId != null) 'UCI ID: ${rider.uciId}',
                      ].join(' | '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: colors.textMuted,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (canOpenDetail)
              Icon(Icons.chevron_right, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _RiderAvatar extends StatelessWidget {
  final EventRegisteredRider rider;

  const _RiderAvatar({required this.rider});

  @override
  Widget build(BuildContext context) {
    final photoUrl = rider.photoUrl;
    if (photoUrl == null) {
      return _FallbackAvatar(initials: rider.initials);
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: photoUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _FallbackAvatar(initials: rider.initials),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  final String initials;

  const _FallbackAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primary,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
