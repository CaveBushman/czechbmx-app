import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart' hide Element;
import 'package:share_plus/share_plus.dart';
import '../../../core/services/pdf_cache_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/in_app_browser.dart';
import '../../../core/widgets/splash_screen.dart';
import 'foreign_entry_sheet.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../entries/entries_repository.dart';
import '../../entries/providers/entries_provider.dart';
import '../../riders/providers/rider_provider.dart';
import '../models/event_model.dart';
import '../providers/event_provider.dart';

class EventDetailScreen extends ConsumerWidget {
  final int id;

  const EventDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(id));

    return Scaffold(
      body: eventAsync.when(
        loading: () => const SplashLoadingBox(),
        error: (err, _) => _EventDetailError(
          message: err.toString(),
          onRetry: () => ref.invalidate(eventDetailProvider(id)),
        ),
        data: (event) => _EventDetailContent(event: event),
      ),
    );
  }
}

class _EventDetailContent extends StatelessWidget {
  final EventModel event;

  const _EventDetailContent({required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 280,
          backgroundColor: colors.background.withValues(alpha: 0.8),
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: FlexibleSpaceBar(
                background: _EventHero(event: event),
                stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              ),
            ),
          ),
          centerTitle: false,
          title: Text(
            event.name.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5),
          ),
          actions: [
            if (event.raceStart != null && !event.isPast)
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  tooltip: ctx.l10n.addToCalendar,
                  onPressed: () {
                    final start = event.raceStart!;
                    final end = event.doubleRace
                        ? start.add(const Duration(hours: 33))
                        : start.add(const Duration(hours: 8));
                    Add2Calendar.addEvent2Cal(
                      Event(
                        title: event.name,
                        startDate: start,
                        endDate: end,
                        location: event.organizerName ?? '',
                        description: 'czechbmx.cz/event/${event.id}',
                      ),
                    );
                  },
                ),
              ),
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: ctx.l10n.share,
                onPressed: () =>
                    Share.share('https://czechbmx.cz/event/${event.id}'),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              _AnimatedEntry(index: 0, child: _StatusPanel(event: event)),
              if (!event.canceled && !event.isPast) ...[
                const SizedBox(height: 12),
                _AnimatedEntry(index: 0, child: _RaceCountdown(raceDate: event.raceStart)),
              ],
              const SizedBox(height: 24),

              // Bento Grid pro hlavní info
              _AnimatedEntry(
                index: 1,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _BentoCard(
                        icon: Icons.calendar_month_outlined,
                        label: context.l10n.eventDate,
                        value: event.date != null
                            ? DateFormat('d. MMMM', context.l10n.languageCode).format(event.date!)
                            : context.l10n.noData,
                        subValue: event.date != null ? DateFormat('EEEE', context.l10n.languageCode).format(event.date!) : null,
                        primary: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _BentoCard(
                        icon: Icons.flag_outlined,
                        label: context.l10n.eventType,
                        value: event.type.label,
                        color: _eventTypeColor(event.type, context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              if (event.organizerName != null) ...[
                _AnimatedEntry(index: 2, child: _OrganizerCard(event: event)),
                const SizedBox(height: 24),
              ],

              _AnimatedEntry(index: 3, child: _ActionGrid(event: event)),
              const SizedBox(height: 20),

              // Technické detaily v čistším gridu
              if (event.system != null || event.director != null || event.uciEventCode != null)
                _AnimatedEntry(
                  index: 4,
                  child: _TechnicalGrid(event: event),
                ),

              if (event.eshopPickupEnabled) ...[
                const SizedBox(height: 20),
                _Section(
                  title: context.l10n.eshopPickup,
                  children: [
                    if (event.eshopPickupLocation != null)
                      _InfoTile(
                        icon: Icons.place_outlined,
                        label: context.l10n.place,
                        value: event.eshopPickupLocation!,
                      ),
                    if (event.eshopPickupTime != null)
                      _InfoTile(
                        icon: Icons.schedule_outlined,
                        label: context.l10n.time,
                        value: event.eshopPickupTime!,
                      ),
                    if (event.eshopPickupNote != null)
                      _InfoTile(
                        icon: Icons.notes_outlined,
                        label: context.l10n.note,
                        value: event.eshopPickupNote!,
                      ),
                  ],
                ),
              ],
              if (event.documentLinks.isNotEmpty) ...[
                const SizedBox(height: 20),
                _Section(
                  title: context.l10n.documents,
                  children: event.documentLinks
                      .map(
                        (link) => _LinkTile(
                          icon: link.icon,
                          label: link.label(context),
                          url: link.url,
                        ),
                      )
                      .toList(),
                ),
              ],
              if (event.photos.isNotEmpty) ...[
                const SizedBox(height: 20),
                _EventGallery(photos: event.photos),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

class _EventHero extends StatelessWidget {
  final EventModel event;

  const _EventHero({required this.event});

  @override
  Widget build(BuildContext context) {
    final typeColor = _eventTypeColor(event.type, context);
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.8, -0.5),
          radius: 1.5,
          colors: [
            typeColor.withValues(alpha: 0.6),
            context.colors.background,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 2.0,
                  colors: [Colors.white.withValues(alpha: 0.04), Colors.transparent],
                ),
              ),
            ),
          ),
          // "CZE" Watermark - symbol národního týmu a racingu
          Positioned(
            right: -20,
            bottom: -10,
            child: Opacity(
              opacity: 0.08,
              child: Text(
                'CZE',
                style: TextStyle(
                  fontSize: 180,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -10,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter:
                  _TrackPainter(color: Colors.white.withValues(alpha: 0.15)),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Hero(
                      tag: 'event_type_${event.id}',
                      child: _HeroBadge(label: event.type.label),
                    ),
                    if (event.canceled) _HeroBadge(label: context.l10n.canceled, color: Colors.redAccent),
                    if (event.isRegistrationOpen) _HeroBadge(label: context.l10n.registrationOpen, color: AppColors.success),
                  ],
                ),
                const SizedBox(height: 12),
                Hero(
                  tag: 'event_title_${event.id}',
                  child: Text(
                    event.name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.displayLarge!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      height: 1.1,
                      shadows: [
                        Shadow(color: Colors.black.withValues(alpha: 0.5), offset: const Offset(0, 4), blurRadius: 15),
                      ],
                    ),
                  ),
                ),
                if (event.date != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    DateFormat.yMMMMEEEEd(context.l10n.languageCode)
                        .format(event.date!),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const _HeroBadge({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? Colors.white;
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.15),
          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final Color? color;
  final bool primary;

  const _BentoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    this.color,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accentColor = color ?? (primary ? AppColors.primary : colors.textPrimary);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 28),
          const SizedBox(height: 24),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: primary ? accentColor : colors.textPrimary,
                  height: 1.1,
                ),
          ),
          if (subValue != null)
            Text(
              subValue!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
        ],
      ),
    );
  }
}

class _TechnicalGrid extends StatelessWidget {
  final EventModel event;
  const _TechnicalGrid({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.5)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.8,
                  colors: [Colors.white.withValues(alpha: 0.05), Colors.transparent],
                ),
              ),
            ),
          ),
          Column(
            children: [
              if (event.system != null)
                _InfoTile(icon: Icons.account_tree_outlined, label: context.l10n.raceSystem, value: event.system!),
          if (event.director != null)
            _InfoTile(icon: Icons.supervisor_account_outlined, label: context.l10n.raceDirector, value: event.director!),
          if (event.isUciRace || event.uciEventCode != null)
            _InfoTile(icon: Icons.public_outlined, label: context.l10n.uciCode, value: event.uciEventCode ?? context.l10n.yes),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedEntry extends StatelessWidget {
  final int index;
  final Widget child;

  const _AnimatedEntry({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
class _OrganizerCard extends StatelessWidget {
  final EventModel event;

  const _OrganizerCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_city_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.organizer.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.organizerName!,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          if (event.hasTrackCoordinates)
            IconButton.filledTonal(
              onPressed: () => _openNavigation(event),
              icon: const Icon(Icons.near_me_outlined),
              style: IconButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final EventModel event;

  const _StatusPanel({required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = event.canceled
        ? AppColors.error
        : event.isRegistrationOpen
            ? AppColors.success
            : AppColors.warning;
    final statusText = event.canceled
        ? context.l10n.canceled
        : event.isRegistrationOpen
            ? context.l10n.registrationOpen
            : context.l10n.registrationClosed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.how_to_reg_outlined, color: statusColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusText,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (event.regOpenFrom != null)
            _InlineMeta(
              label: context.l10n.registrationFrom,
              value: _formatDateTime(context, event.regOpenFrom!),
            ),
          if (event.regOpenTo != null)
            _InlineMeta(
              label: context.l10n.registrationTo,
              value: _formatDateTime(context, event.regOpenTo!),
            ),
          if (event.unregisterTo != null)
            _InlineMeta(
              label: context.l10n.unregisterTo,
              value: _formatDateTime(context, event.unregisterTo!),
            ),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final EventModel event;

  const _ActionGrid({required this.event});

  @override
  Widget build(BuildContext context) {
    final actions = <_EventAction>[
      if (event.isRegistrationOpen)
        _EventAction(
          icon: Icons.app_registration,
          label: context.l10n.register,
          onTap: () => _openNativeEntrySheet(context, event),
          primary: true,
        ),
      if (event.isRegistrationOpen)
        _EventAction(
          icon: Icons.public_outlined,
          label: context.l10n.foreignRider,
          onTap: () => openForeignEntrySheet(context, event),
        ),
      if (event.hasTrackCoordinates)
        _EventAction(
          icon: Icons.navigation_outlined,
          label: context.l10n.navigateToTrack,
          onTap: () => _openNavigation(event),
        ),
      _EventAction(
        icon: Icons.groups_outlined,
        label: context.l10n.registeredRiders,
        onTap: () => context.push('/events/${event.id}/riders'),
      ),
      _EventAction(
        icon: Icons.description_outlined,
        label: context.l10n.proposition,
        url: event.propositionUrl ?? event.webPropositionUrl,
      ),
      _EventAction(
        icon: Icons.leaderboard_outlined,
        label: context.l10n.results,
        url: event.htmlResultsUrl ?? event.webResultsUrl,
      ),
      if (event.youtubeLink != null)
        _EventAction(
          icon: Icons.play_circle_outline,
          label: 'YouTube',
          url: event.youtubeLink!,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actions
              .map((action) => SizedBox(width: itemWidth, child: action))
              .toList(),
        );
      },
    );
  }
}

class _EventAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? url;
  final VoidCallback? onTap;
  final bool primary;

  const _EventAction({
    required this.icon,
    required this.label,
    this.url,
    this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap ?? () => _openUrl(url!, context: context, title: label),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : colors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primary 
                ? AppColors.primary 
                : colors.border.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: primary ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: primary ? Colors.white : colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openNativeEntrySheet(
  BuildContext context,
  EventModel event,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _EventEntrySheet(event: event),
  );
}

class _EventEntrySheet extends ConsumerStatefulWidget {
  final EventModel event;

  const _EventEntrySheet({required this.event});

  @override
  ConsumerState<_EventEntrySheet> createState() => _EventEntrySheetState();
}

class _EventEntrySheetState extends ConsumerState<_EventEntrySheet> {
  Future<EventEntryInfo>? _future;
  final Set<String> _selected = {};
  bool _initializedSelection = false;
  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = ref.read(currentUserProvider);
    final riderUciId = user?.riderUciId;
    if (_future == null && riderUciId != null) {
      _future = ref.read(entriesRepositoryProvider).fetchEventEntryInfo(
            eventId: widget.event.id,
            riderUciId: riderUciId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final riderUciId = user?.riderUciId;
    final colors = context.colors;

    if (user == null) {
      return _EntrySheetScaffold(
        title: context.l10n.register,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.notLoggedIn),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.go('/login');
              },
              icon: const Icon(Icons.login),
              label: Text(context.l10n.login),
            ),
          ],
        ),
      );
    }

    if (riderUciId == null) {
      return _EntrySheetScaffold(
        title: context.l10n.register,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.noRiderLinked),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                openForeignEntrySheet(context, widget.event);
              },
              icon: const Icon(Icons.public_outlined),
              label: Text(context.l10n.foreignRiderEntry),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<EventEntryInfo>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _EntrySheetScaffold(
            title: widget.event.name,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return _EntrySheetScaffold(
            title: widget.event.name,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(snapshot.error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _future = ref
                          .read(entriesRepositoryProvider)
                          .fetchEventEntryInfo(
                            eventId: widget.event.id,
                            riderUciId: riderUciId,
                          );
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.retry),
                ),
              ],
            ),
          );
        }

        final info = snapshot.data!;
        final selectable = info.selectableOptions.toList();
        if (!_initializedSelection) {
          if (selectable.isNotEmpty) _selected.add(selectable.first.key);
          _initializedSelection = true;
        }

        if (!info.registrationOpen || selectable.isEmpty) {
          return _EntrySheetScaffold(
            title: widget.event.name,
            child: Text(
              selectable.isEmpty
                  ? context.l10n.noCategoryAvailable
                  : context.l10n.registrationClosed,
              textAlign: TextAlign.center,
            ),
          );
        }

        final totalFee = info.feeFor(_selected);
        final rider =
            ref.watch(riderDetailProvider(info.riderUciId)).valueOrNull;
        final riderName = _firstNonEmpty([
          info.riderFullName,
          rider?.fullName,
          user.fullName,
        ]);
        return _EntrySheetScaffold(
          title: info.eventName,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EntryRiderHeader(
                riderName: riderName,
                uciId: info.riderUciId,
                textColor: colors.textSecondary,
              ),
              const SizedBox(height: 12),
              ...info.options.entries.map((entry) {
                final option = entry.value;
                final enabled = option.allowed && !option.alreadyRegistered;
                return CheckboxListTile(
                  value: _selected.contains(entry.key),
                  onChanged: enabled
                      ? (value) {
                          setState(() {
                            if (value == true) {
                              if (entry.key == 'is_beginner') {
                                _selected
                                  ..clear()
                                  ..add(entry.key);
                              } else {
                                _selected
                                  ..remove('is_beginner')
                                  ..add(entry.key);
                              }
                            } else {
                              _selected.remove(entry.key);
                            }
                          });
                        }
                      : null,
                  title: Text(_entryOptionLabel(context, entry.key, option)),
                  subtitle: Text(
                    option.alreadyRegistered
                        ? context.l10n.alreadyRegistered
                        : option.allowed
                            ? '${option.fee} ${context.l10n.czk}'
                            : context.l10n.notAvailable,
                  ),
                  contentPadding: EdgeInsets.zero,
                );
              }),
              const SizedBox(height: 12),
              _CreditAndTotalRow(user: user, totalFee: totalFee),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _selected.isEmpty || _submitting
                    ? null
                    : () => _submit(info),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(context.l10n.register),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit(EventEntryInfo info) async {
    setState(() => _submitting = true);
    try {
      await ref.read(entriesRepositoryProvider).enterEvent(
            eventId: widget.event.id,
            riderUciId: info.riderUciId,
            is20: _selected.contains('is_20'),
            is24: _selected.contains('is_24'),
            isBeginner: _selected.contains('is_beginner'),
          );
      ref.invalidate(myEntriesProvider);
      ref.read(authProvider.notifier).refreshUser();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.entrySuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _EntryRiderHeader extends StatelessWidget {
  final String? riderName;
  final int uciId;
  final Color textColor;

  const _EntryRiderHeader({
    required this.riderName,
    required this.uciId,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final name = riderName?.trim();
    if (name == null || name.isEmpty) {
      return Text(
        '${context.l10n.rider} UCI ID: $uciId',
        style:
            Theme.of(context).textTheme.bodyMedium!.copyWith(color: textColor),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.l10n.rider}: $name',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 2),
        Text(
          '${context.l10n.uciId}: $uciId',
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: textColor),
        ),
      ],
    );
  }
}

class _EntrySheetScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const _EntrySheetScaffold({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ── Credit + total row in entry sheet ────────────────────────────────────────

class _CreditAndTotalRow extends StatelessWidget {
  final UserModel? user;
  final int totalFee;
  const _CreditAndTotalRow({required this.user, required this.totalFee});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final credit = user?.credit ?? 0;
    final canAfford = credit >= totalFee;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${context.l10n.total}: $totalFee ${context.l10n.czk}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${context.l10n.credit}: $credit ${context.l10n.czk}',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: canAfford ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (!canAfford)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
                const SizedBox(width: 4),
                Text(
                  context.l10n.topUpCredit,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Race countdown chip ────────────────────────────────────────────────────────

class _RaceCountdown extends StatelessWidget {
  final DateTime? raceDate;
  const _RaceCountdown({required this.raceDate});

  @override
  Widget build(BuildContext context) {
    if (raceDate == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final race = DateTime(raceDate!.year, raceDate!.month, raceDate!.day);
    final diff = race.difference(today).inDays;
    if (diff < 0) return const SizedBox.shrink();

    final String label;
    final Color color;
    if (diff == 0) {
      label = context.l10n.raceToday;
      color = AppColors.success;
    } else if (diff == 1) {
      label = context.l10n.raceTomorrow;
      color = AppColors.warning;
    } else {
      label = '$diff ${context.l10n.daysUntilRace}';
      color = AppColors.primary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}

String _entryOptionLabel(BuildContext context, String key, EventEntryOption option) {
  final className = option.className;
  final suffix = className == null || className.isEmpty ? '' : ' - $className';
  return switch (key) {
    'is_20' => '20"$suffix',
    'is_24' => '24"$suffix',
    'is_beginner' => '${context.l10n.beginner}$suffix',
    _ => key,
  };
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          ...children,
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: context.colors.textSecondary, size: 20),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _LinkTile({
    required this.icon,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: context.colors.textSecondary, size: 20),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: context.colors.textMuted,
      ),
      onTap: () => _openUrl(url, context: context, title: label),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  final String label;
  final String value;

  const _InlineMeta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _EventDetailError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _EventDetailError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.eventsLoadFailed,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  final Color color;

  const _TrackPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Stylizovaný "BMX Rhythm Section" a startovní pahorek
    final path = Path()
      // Startovní pahorek (Starting Hill)
      ..moveTo(-50, size.height * 0.1)
      ..lineTo(size.width * 0.2, size.height * 0.45)
      // První skok (Double)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.2,
        size.width * 0.45,
        size.height * 0.45,
      )
      // Druhý skok a nájezd do zatáčky
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.65,
        size.width + 50,
        size.height * 0.4,
      );
    
    canvas.drawPath(path, paint);

    // Startovní brána (Start Gate) - symbol 8 pozic
    final gatePaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
      
    for (var i = 0; i < 8; i++) {
      final startX = size.width * 0.05 + i * 14;
      final startY = size.height * 0.25 + i * 8;
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX + 10, startY - 15),
        gatePaint,
      );
    }

    // Cílová čára (Finish Grid) v dálce
    final finishPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    for (var i = 0; i < 10; i++) {
      canvas.drawLine(
        Offset(size.width * 0.85 + i * 5, 0),
        Offset(size.width * 0.85 + i * 5, size.height),
        finishPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrackPainter oldDelegate) =>
      oldDelegate.color != color;
}

Color _eventTypeColor(EventType type, BuildContext context) {
  return switch (type) {
    EventType.mistrovstviCrJednotlivcu ||
    EventType.mistrovstviCrDruzstev =>
      const Color(0xFFFFD700),
    EventType.ceskyPohar => AppColors.primary,
    EventType.ceskaLiga => const Color(0xFF22C55E),
    EventType.moravskaLiga => const Color(0xFF8B5CF6),
    EventType.evropskyPohar || EventType.mistrovstviEvropy => Colors.blue,
    EventType.mistrovstviSveta ||
    EventType.svetovyPohar =>
      const Color(0xFFEC4899),
    _ => context.colors.textMuted,
  };
}

String _formatDateTime(BuildContext context, DateTime dateTime) {
  return DateFormat('d. M. y HH:mm', context.l10n.languageCode)
      .format(dateTime);
}

/// Returns true for URLs that should open outside the app.
///
/// Currently we keep YouTube and Stripe checkout external, while other
/// HTTP/HTTPS links are rendered inside the app browser.
bool _isExternalBrowserLink(String url) {
  final uri = Uri.tryParse(url);
  final host = uri?.host ?? '';
  final path = uri?.path.toLowerCase() ?? '';
  return host.contains('youtube.com') ||
      host.contains('youtu.be') ||
      host.contains('stripe.com') ||
      path.endsWith('.pdf');
}

Future<void> _openUrl(String url,
    {BuildContext? context, String? title}) async {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
  if (path.endsWith('.pdf') && context != null && context.mounted) {
    final ctx = context;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(ctx.l10n.downloadingPdf),
        duration: const Duration(seconds: 60),
      ),
    );
    await PdfCacheService.openPdf(
      url,
      onDone: () {
        if (ctx.mounted) ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
      },
      onError: (e) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      },
    );
    return;
  }

  final external = _isExternalBrowserLink(url);
  if (context != null && context.mounted && !external) {
    openInApp(context, url, title: title);
    return;
  }

  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }
}

Future<void> _openNavigation(EventModel event) async {
  // Navigation is intentionally launched externally because the app does not
  // provide a built-in maps UI for directions.
  final lat = event.organizerLat;
  final lon = event.organizerLon;
  if (lat == null || lon == null) return;

  final label = Uri.encodeComponent(event.organizerName ?? event.name);
  final candidates = [
    Uri.parse('google.navigation:q=$lat,$lon'),
    Uri.parse('geo:$lat,$lon?q=$lat,$lon($label)'),
    Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving',
    ),
  ];

  for (final uri in candidates) {
    if (await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }
  }
}

extension on EventModel {
  List<_EventDocumentLink> get documentLinks {
    return [
      if (propositionUrl != null)
        _EventDocumentLink(
          icon: Icons.description_outlined,
          labelKey: 'proposition',
          url: propositionUrl!,
        ),
      if (seriesUrl != null)
        _EventDocumentLink(
          icon: Icons.format_list_numbered_outlined,
          labelKey: 'series',
          url: seriesUrl!,
        ),
      if (bemRidersListUrl != null)
        _EventDocumentLink(
          icon: Icons.groups_outlined,
          labelKey: 'ridersList',
          url: bemRidersListUrl!,
        ),
      if (fullResultsUrl != null)
        _EventDocumentLink(
          icon: Icons.emoji_events_outlined,
          labelKey: 'fullResults',
          url: fullResultsUrl!,
        ),
      if (xlsResultsUrl != null)
        _EventDocumentLink(
          icon: Icons.table_chart_outlined,
          labelKey: 'xlsResults',
          url: xlsResultsUrl!,
        ),
      if (fastRidersUrl != null)
        _EventDocumentLink(
          icon: Icons.speed_outlined,
          labelKey: 'fastRiders',
          url: fastRidersUrl!,
        ),
    ];
  }
}

class _EventDocumentLink {
  final IconData icon;
  final String labelKey;
  final String url;

  const _EventDocumentLink({
    required this.icon,
    required this.labelKey,
    required this.url,
  });

  String label(BuildContext context) => context.l10n.t(labelKey);
}

// ── Event photo gallery ───────────────────────────────────────────────────────

class _EventGallery extends StatelessWidget {
  final List<EventPhoto> photos;
  const _EventGallery({required this.photos});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.gallery,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final photo = photos[index];
              return GestureDetector(
                onTap: () => _openGallery(context, index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: photo.photoUrl,
                    width: 260,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 260,
                      color: context.colors.surfaceVariant,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 260,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: context.colors.textMuted.withValues(alpha: 0.5),
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openGallery(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) =>
            _GalleryViewer(photos: photos, initialIndex: initialIndex),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}

class _GalleryViewer extends StatefulWidget {
  final List<EventPhoto> photos;
  final int initialIndex;
  const _GalleryViewer({required this.photos, required this.initialIndex});

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final PageController _pageController;
  late int _current;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails d) {
    setState(() => _dragOffset += d.delta.dy);
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    if (_dragOffset.abs() > 80 || d.velocity.pixelsPerSecond.dy.abs() > 400) {
      Navigator.pop(context);
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  Future<void> _shareCurrentPhoto() async {
    final url = widget.photos[_current].photoUrl;
    await Share.share(url, subject: widget.photos[_current].caption);
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_current];
    final opacity = (1 - (_dragOffset.abs() / 300)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: AnimatedContainer(
          duration: _dragOffset == 0 ? const Duration(milliseconds: 200) : Duration.zero,
          color: Colors.black.withValues(alpha: 0.87 * opacity),
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.photos.length,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemBuilder: (_, index) => Center(
                    child: InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: widget.photos[index].photoUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                ),
                // Top bar: close + share
                Positioned(
                  top: MediaQuery.of(context).padding.top + 4,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined, color: Colors.white, size: 22),
                        tooltip: context.l10n.sharePhoto,
                        onPressed: _shareCurrentPhoto,
                      ),
                    ],
                  ),
                ),
                // Caption + counter
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      if (photo.caption.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            photo.caption,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              shadows: [Shadow(blurRadius: 4)],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        '${_current + 1} / ${widget.photos.length}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
