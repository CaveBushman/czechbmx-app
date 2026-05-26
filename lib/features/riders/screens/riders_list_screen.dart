import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import '../models/rider_model.dart';
import '../providers/favorite_riders_provider.dart';
import '../providers/rider_provider.dart';
import '../rider_repository.dart';
import '../widgets/riders_shimmer.dart';

class RidersListScreen extends HookConsumerWidget {
  const RidersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchCtrl = useTextEditingController();
    final genderFilter = useState<String?>(null);
    final bikeFilter = useState<String?>(null); // '20' | '24' | null
    final eliteOnly = useState(false);
    final favoriteOnly = useState(false);
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
    final favorites = ref.watch(favoriteRidersProvider);
    final colors = context.colors;
    final showList = useState(false);

    useEffect(() {
      if (ridersAsync is AsyncData<List<RiderModel>>) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!showList.value) showList.value = true;
        });
      } else {
        showList.value = false;
      }
      return null;
    }, [ridersAsync]);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(ridersProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: colors.background.withValues(alpha: 0.8),
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(color: Colors.transparent),
                ),
              ),
              title: Text(
                context.l10n.riders.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
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
                          : Icon(Icons.search, color: colors.textMuted.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: colors.surfaceVariant.withValues(alpha: 0.6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
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
                  favoriteOnly: favoriteOnly,
                  onChanged: applyFilter,
                ),
              ),

            ridersAsync.when(
              loading: () => const SliverFillRemaining(
                child: RidersListShimmer(),
              ),
              error: (err, _) => SliverFillRemaining(
                child: _ErrorView(error: err, ref: ref),
              ),
              data: (riders) {
                final displayed = favoriteOnly.value
                    ? riders.where((r) => favorites.contains(r.uciId)).toList()
                    : riders;
                if (displayed.isEmpty) {
                  return const SliverFillRemaining(child: _EmptyView());
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  sliver: SliverList.separated(
                    itemCount: displayed.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _AnimatedRiderTile(
                      rider: displayed[i],
                      show: showList.value,
                      index: i,
                    ),
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
  final ValueNotifier<bool> favoriteOnly;
  final VoidCallback onChanged;

  const _FilterBar({
    required this.genderFilter,
    required this.bikeFilter,
    required this.eliteOnly,
    required this.favoriteOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: context.colors.background.withValues(alpha: 0.5),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
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
                label: context.l10n.elite,
                selected: eliteOnly.value,
                onTap: () {
                  eliteOnly.value = !eliteOnly.value;
                  onChanged();
                },
              ),
              _Chip(
                label: context.l10n.myRiders,
                icon: Icons.favorite,
                selected: favoriteOnly.value,
                onTap: () {
                  favoriteOnly.value = !favoriteOnly.value;
                  onChanged();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? Colors.white : colors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : colors.surfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : colors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedRiderTile extends StatelessWidget {
  final RiderModel rider;
  final bool show;
  final int index;

  const _AnimatedRiderTile({
    required this.rider,
    required this.show,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: show ? 1.0 : 0.0),
      duration: Duration(milliseconds: 400 + (index % 10) * 50),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _RiderTile(rider: rider),
    );
  }
}

// ── Rider tile ────────────────────────────────────────────────────────────────

class _RiderTile extends HookConsumerWidget {
  final RiderModel rider;

  const _RiderTile({required this.rider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final pressed = useState(false);
    final accentColor = avatarColor(rider.uciId);
    final teamsMap = ref.watch(teamsMapProvider).valueOrNull ?? {};
    final teamLabel = rider.teamName?.isNotEmpty == true
        ? rider.teamName!
        : (rider.teamId != null ? teamsMap[rider.teamId] : null) ?? '';

    final isFavorite = ref.watch(
      favoriteRidersProvider.select((s) => s.contains(rider.uciId)),
    );

    final displayCategory = [
      if (rider.categoryLabel.isNotEmpty) rider.categoryLabel,
      if (teamLabel.isNotEmpty) teamLabel,
    ].join(' · ');

    return AnimatedScale(
      scale: pressed.value ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('/riders/${rider.uciId}');
          },
          onHighlightChanged: (highlight) => pressed.value = highlight,
          child: Container(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentColor.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
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
                ),
                const SizedBox(width: 8),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rider.fullName.toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayCategory.isEmpty ? context.l10n.bmxRider : displayCategory.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Nationality / favorite / arrow
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: colors.textMuted.withValues(alpha: 0.5),
                      size: 14,
                    ),
                    GestureDetector(
                      onTap: () => ref
                          .read(favoriteRidersProvider.notifier)
                          .toggle(rider.uciId),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(8, 0, 12, 0),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isFavorite 
                            ? Colors.redAccent.withValues(alpha: 0.1) 
                            : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) => ScaleTransition(
                            scale: anim,
                            child: child,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(isFavorite),
                            color: isFavorite
                                ? Colors.redAccent
                                : colors.textMuted,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(RiderModel rider, AppColorPalette colors) {
    final color = avatarColor(rider.uciId);
    return Container(
      width: 64,
      height: 64,
      color: color.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          rider.firstName.isNotEmpty ? rider.firstName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
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
        (error as ApiException).statusCode == 401;
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
