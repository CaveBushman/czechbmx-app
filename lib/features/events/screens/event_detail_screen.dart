import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/in_app_browser.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../entries/entries_repository.dart';
import '../../entries/providers/entries_provider.dart';
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
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
          expandedHeight: 250,
          title: Text(event.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          flexibleSpace: FlexibleSpaceBar(
            background: _EventHero(event: event),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              _StatusPanel(event: event),
              const SizedBox(height: 14),
              _ActionGrid(event: event),
              const SizedBox(height: 14),
              _Section(
                title: context.l10n.eventInfo,
                children: [
                  _InfoTile(
                    icon: Icons.calendar_month_outlined,
                    label: context.l10n.eventDate,
                    value: event.date != null
                        ? DateFormat.yMMMMEEEEd(context.l10n.languageCode)
                            .format(event.date!)
                        : context.l10n.noData,
                  ),
                  _InfoTile(
                    icon: Icons.flag_outlined,
                    label: context.l10n.eventType,
                    value: event.type.label,
                  ),
                  if (event.system != null)
                    _InfoTile(
                      icon: Icons.account_tree_outlined,
                      label: context.l10n.raceSystem,
                      value: event.system!,
                    ),
                  if (event.director != null)
                    _InfoTile(
                      icon: Icons.supervisor_account_outlined,
                      label: context.l10n.raceDirector,
                      value: event.director!,
                    ),
                  if (event.isUciRace || event.uciEventCode != null)
                    _InfoTile(
                      icon: Icons.public_outlined,
                      label: 'UCI',
                      value: event.uciEventCode ?? context.l10n.yes,
                    ),
                  if (event.doubleRace)
                    _InfoTile(
                      icon: Icons.looks_two_outlined,
                      label: context.l10n.format,
                      value: context.l10n.twoDays,
                    ),
                ],
              ),
              if (event.eshopPickupEnabled) ...[
                const SizedBox(height: 14),
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
                const SizedBox(height: 14),
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
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _openUrl(event.webDetailUrl),
                icon: const Icon(Icons.open_in_new),
                label: Text(context.l10n.openOnWeb),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: colors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
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
    final date = event.date;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            typeColor.withValues(alpha: 0.92),
            const Color(0xFF111827),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter:
                  _TrackPainter(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          Positioned(
            right: -16,
            bottom: 18,
            child: Icon(
              Icons.directions_bike,
              size: 152,
              color: Colors.white.withValues(alpha: 0.12),
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
                    _HeroBadge(label: event.type.label),
                    if (event.canceled)
                      _HeroBadge(
                        label: context.l10n.canceled,
                        color: Colors.redAccent,
                      ),
                    if (event.isRegistrationOpen)
                      _HeroBadge(
                        label: context.l10n.registrationOpen,
                        color: AppColors.success,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  event.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.displayMedium!.copyWith(
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(0, 2),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    DateFormat.yMMMMEEEEd(context.l10n.languageCode)
                        .format(date),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: color == null ? 0.16 : 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.42)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.45)),
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
      if (event.isRegistrationOpen && event.uecLink == null)
        _EventAction(
          icon: Icons.app_registration,
          label: context.l10n.register,
          onTap: () => _openNativeEntrySheet(context, event),
          primary: true,
        ),
      if (event.uecLink != null)
        _EventAction(
          icon: Icons.open_in_new,
          label: context.l10n.register,
          url: event.uecLink!,
          primary: true,
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
        url: event.webRidersUrl,
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
    return FilledButton.icon(
      onPressed: onTap ?? () => _openUrl(url!, context: context, title: label),
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        backgroundColor: primary ? AppColors.primary : colors.surfaceVariant,
        foregroundColor: primary ? Colors.white : colors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      return const _EntrySheetScaffold(
        title: 'Přihlášení na závod',
        child: Text('K účtu není navázaný žádný jezdec.'),
      );
    }

    return FutureBuilder<EventEntryInfo>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _EntrySheetScaffold(
            title: 'Přihlášení na závod',
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return _EntrySheetScaffold(
            title: 'Přihlášení na závod',
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
            title: 'Přihlášení na závod',
            child: Text(
              selectable.isEmpty
                  ? 'Pro jezdce není dostupná žádná nová kategorie.'
                  : context.l10n.registrationClosed,
              textAlign: TextAlign.center,
            ),
          );
        }

        final totalFee = info.feeFor(_selected);
        return _EntrySheetScaffold(
          title: info.eventName,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Jezdec UCI ID: ${info.riderUciId}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: colors.textSecondary),
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
                  title: Text(_entryOptionLabel(entry.key, option)),
                  subtitle: Text(
                    option.alreadyRegistered
                        ? 'Už přihlášeno'
                        : option.allowed
                            ? '${option.fee} Kč'
                            : 'Není dostupné',
                  ),
                  contentPadding: EdgeInsets.zero,
                );
              }),
              const SizedBox(height: 12),
              Text(
                'Celkem: $totalFee Kč',
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
          const SnackBar(content: Text('Přihlášení proběhlo.')),
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

String _entryOptionLabel(String key, EventEntryOption option) {
  final className = option.className;
  final suffix = className == null || className.isEmpty ? '' : ' - $className';
  return switch (key) {
    'is_20' => '20"$suffix',
    'is_24' => '24"$suffix',
    'is_beginner' => 'Začátečník$suffix',
    _ => key,
  };
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colors.border),
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
      leading: Icon(icon, color: context.colors.textMuted),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      dense: true,
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
      leading: Icon(icon, color: context.colors.textMuted),
      title: Text(label),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => _openUrl(url, context: context, title: label),
      dense: true,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 64,
              color: context.colors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.eventsLoadFailed,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
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

class _TrackPainter extends CustomPainter {
  final Color color;

  const _TrackPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(-20, size.height * 0.34)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.12,
        size.width * 0.52,
        size.height * 0.36,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.56,
        size.width + 28,
        size.height * 0.32,
      );
    canvas.drawPath(path, paint);

    final gatePaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 5; i++) {
      final x = size.width * 0.12 + i * 32;
      canvas.drawLine(
        Offset(x, size.height * 0.7),
        Offset(x + 22, size.height * 0.62),
        gatePaint,
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

bool _isYouTube(String url) {
  final host = Uri.tryParse(url)?.host ?? '';
  return host.contains('youtube.com') || host.contains('youtu.be');
}

Future<void> _openUrl(String url,
    {BuildContext? context, String? title}) async {
  if (context != null && context.mounted && !_isYouTube(url)) {
    openInApp(context, url, title: title);
    return;
  }
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }
}

Future<void> _openNavigation(EventModel event) async {
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
