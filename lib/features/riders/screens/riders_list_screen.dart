import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';
import '../models/rider_model.dart';
import '../providers/rider_provider.dart';
import '../rider_repository.dart';

class RidersListScreen extends HookConsumerWidget {
  const RidersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchCtrl = useTextEditingController();
    final genderFilter = useState<String?>(null);
    final bikeFilter = useState<String?>(null); // '20' | '24' | null
    final eliteOnly = useState(false);
    final showFilters = useState(false);
    final searchDebounce = useRef<Timer?>(null);

    void applyFilter() {
      ref.read(ridersFilterProvider.notifier).state = RidersFilter(
        search: searchCtrl.text.trim().isEmpty ? null : searchCtrl.text.trim(),
        gender: genderFilter.value,
        is20: bikeFilter.value == '20' ? true : null,
        is24: bikeFilter.value == '24' ? true : null,
        isElite: eliteOnly.value ? true : null,
      );
    }

    // Debounced search
    useEffect(() {
      void listener() {
        searchDebounce.value?.cancel();
        searchDebounce.value = Timer(
          const Duration(milliseconds: 350),
          applyFilter,
        );
      }

      searchCtrl.addListener(listener);
      return () {
        searchCtrl.removeListener(listener);
        searchDebounce.value?.cancel();
      };
    }, [searchCtrl]);

    final ridersAsync = ref.watch(ridersProvider);
    final colors = context.colors;

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(ridersProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              title: Text(context.l10n.riders),
              actions: [
                IconButton(
                  icon: Icon(
                    showFilters.value
                        ? Icons.filter_alt
                        : Icons.filter_alt_outlined,
                    color: showFilters.value ? AppColors.primary : null,
                  ),
                  onPressed: () => showFilters.value = !showFilters.value,
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: context.l10n.searchRiders,
                      hintStyle: TextStyle(color: colors.textMuted),
                      prefixIcon: Icon(Icons.search, color: colors.textMuted),
                      suffixIcon: searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: colors.textMuted),
                              onPressed: () {
                                searchCtrl.clear();
                                applyFilter();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ),

            // Filter chips
            if (showFilters.value)
              SliverToBoxAdapter(
                child: _FilterBar(
                  genderFilter: genderFilter,
                  bikeFilter: bikeFilter,
                  eliteOnly: eliteOnly,
                  onChanged: applyFilter,
                ),
              ),

            ridersAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                child: _ErrorView(error: err, ref: ref),
              ),
              data: (riders) {
                if (riders.isEmpty) {
                  return const SliverFillRemaining(child: _EmptyView());
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList.separated(
                    itemCount: riders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _RiderTile(rider: riders[i]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final ValueNotifier<String?> genderFilter;
  final ValueNotifier<String?> bikeFilter;
  final ValueNotifier<bool> eliteOnly;
  final VoidCallback onChanged;

  const _FilterBar({
    required this.genderFilter,
    required this.bikeFilter,
    required this.eliteOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Wrap(
        spacing: 8,
        children: [
          _Chip(
            label: context.l10n.men,
            selected: genderFilter.value == 'Muž',
            onTap: () {
              genderFilter.value = genderFilter.value == 'Muž' ? null : 'Muž';
              onChanged();
            },
          ),
          _Chip(
            label: context.l10n.women,
            selected: genderFilter.value == 'Žena',
            onTap: () {
              genderFilter.value = genderFilter.value == 'Žena' ? null : 'Žena';
              onChanged();
            },
          ),
          _Chip(
            label: '20"',
            selected: bikeFilter.value == '20',
            onTap: () {
              bikeFilter.value = bikeFilter.value == '20' ? null : '20';
              onChanged();
            },
          ),
          _Chip(
            label: '24"',
            selected: bikeFilter.value == '24',
            onTap: () {
              bikeFilter.value = bikeFilter.value == '24' ? null : '24';
              onChanged();
            },
          ),
          _Chip(
            label: 'Elite',
            selected: eliteOnly.value,
            onTap: () {
              eliteOnly.value = !eliteOnly.value;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Rider tile ────────────────────────────────────────────────────────────────

class _RiderTile extends HookWidget {
  final RiderModel rider;

  const _RiderTile({required this.rider});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pressed = useState(false);
    return GestureDetector(
      onTap: () => context.go('/riders/${rider.uciId}'),
      onTapDown: (_) => pressed.value = true,
      onTapUp: (_) => pressed.value = false,
      onTapCancel: () => pressed.value = false,
      child: AnimatedScale(
        scale: pressed.value ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Avatar
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(10),
              ),
              child: rider.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: rider.photoUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          _avatarPlaceholder(rider, colors),
                    )
                  : _avatarPlaceholder(rider, colors),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rider.fullName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (rider.categoryLabel.isNotEmpty) rider.categoryLabel,
                      if (rider.city != null && rider.city!.isNotEmpty)
                        rider.city,
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            // Nationality / arrow
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rider.nationality,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colors.textMuted, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _avatarPlaceholder(RiderModel rider, AppColorPalette colors) {
    return Container(
      width: 64,
      height: 64,
      color: colors.surfaceVariant,
      child: Center(
        child: Text(
          rider.firstName.isNotEmpty ? rider.firstName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: colors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ── States ────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final Object error;
  final WidgetRef ref;

  const _ErrorView({required this.error, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isAuth = error is ApiException &&
        ((error as ApiException).statusCode == 401 ||
            (error as ApiException).message.contains('přihlásit'));
    final message = error.toString();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAuth ? Icons.lock_outline : Icons.wifi_off_rounded,
              size: 64,
              color: context.colors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              isAuth ? context.l10n.loginRequired : context.l10n.loadingFailed,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isAuth ? context.l10n.ridersLoginRequired : message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => isAuth
                  ? context.go('/login')
                  : ref.read(ridersProvider.notifier).refresh(),
              icon: Icon(isAuth ? Icons.login : Icons.refresh),
              label: Text(isAuth ? context.l10n.login : context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 64,
            color: context.colors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.noRiders,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }
}
