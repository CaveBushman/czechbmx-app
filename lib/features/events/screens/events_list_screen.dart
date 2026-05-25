import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../models/event_model.dart';
import '../providers/event_provider.dart';
import '../widgets/event_card.dart';
import '../widgets/events_shimmer.dart';

class EventsListScreen extends ConsumerWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedYearProvider);
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(eventsProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              title: Text(context.l10n.events),
              actions: [_YearPicker(year: year, ref: ref)],
            ),
            eventsAsync.when(
              loading: () => const SliverFillRemaining(
                child: EventsListShimmer(),
              ),
              error: (err, _) => SliverFillRemaining(
                child: _ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.read(eventsProvider.notifier).refresh(),
                ),
              ),
              data: (events) {
                if (events.isEmpty) {
                  return const SliverFillRemaining(child: _EmptyView());
                }
                return _EventsCalendar(events: events);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EventsCalendar extends HookConsumerWidget {
  final List<EventModel> events;

  const _EventsCalendar({required this.events});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byMonth = ref.watch(eventsByMonthProvider);
    final months = byMonth.keys.toList()..sort();
    final selectedYear = ref.watch(selectedYearProvider);

    // Find the exact first upcoming event (only for current year)
    final targetInfo = useMemoized(() {
      if (selectedYear != DateTime.now().year) return null;
      final now = DateTime.now();
      for (final month in months) {
        for (final event in byMonth[month]!) {
          if (event.date != null && !event.date!.isBefore(now)) {
            return (month: month, eventId: event.id);
          }
        }
      }
      return null;
    }, [months, selectedYear]);

    final targetKey = useMemoized(() => GlobalKey(), [targetInfo]);

    // Scroll to the exact upcoming event after first render
    useEffect(() {
      if (targetInfo == null) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = targetKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });
      return null;
    }, [targetInfo]);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: months.map((month) {
            return _MonthSection(
              month: month,
              events: byMonth[month]!,
              targetEventId: month == targetInfo?.month ? targetInfo?.eventId : null,
              targetKey: month == targetInfo?.month ? targetKey : null,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  final int month;
  final List<EventModel> events;
  final int? targetEventId;
  final Key? targetKey;

  const _MonthSection({
    required this.month,
    required this.events,
    this.targetEventId,
    this.targetKey,
  });

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat(
      'MMMM',
      context.l10n.languageCode,
    ).format(DateTime(2000, month)).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 10),
          child: Row(
            children: [
              Text(
                monthName,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                    ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Divider(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              const SizedBox(width: 8),
              Text(
                '${events.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        ...events.map(
          (e) {
            final isNext = e.id == targetEventId;
            final isPast = e.isPast && !e.canceled;
            return Padding(
              key: isNext ? targetKey : null,
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isNext)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          _PulsingDot(),
                          SizedBox(width: 6),
                          Text(
                            'Příští závod',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Opacity(
                    opacity: isPast ? 0.5 : 1.0,
                    child: EventCard(
                      event: e,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.go('/events/${e.id}');
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _YearPicker extends StatelessWidget {
  final int year;
  final WidgetRef ref;

  const _YearPicker({required this.year, required this.ref});

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () =>
              ref.read(selectedYearProvider.notifier).state = year - 1,
        ),
        GestureDetector(
          onTap: () async {
            final picked = await showDialog<int>(
              context: context,
              builder: (_) => _YearDialog(current: year),
            );
            if (picked != null) {
              ref.read(selectedYearProvider.notifier).state = picked;
            }
          },
          child: Text(
            '$year',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: year == currentYear
                      ? AppColors.primary
                      : context.colors.textPrimary,
                ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () =>
              ref.read(selectedYearProvider.notifier).state = year + 1,
        ),
      ],
    );
  }
}

class _YearDialog extends StatelessWidget {
  final int current;

  const _YearDialog({required this.current});

  @override
  Widget build(BuildContext context) {
    final years = List.generate(8, (i) => DateTime.now().year - 3 + i);
    return AlertDialog(
      backgroundColor: context.colors.surface,
      title: Text(context.l10n.selectYear),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: years
            .map(
              (y) => ListTile(
                title: Text('$y'),
                selected: y == current,
                selectedColor: AppColors.primary,
                onTap: () => Navigator.of(context).pop(y),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 64,
            color: context.colors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.eventsLoadFailed,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.retry),
          ),
        ],
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
          Icon(Icons.flag_outlined, size: 64, color: context.colors.textMuted),
          const SizedBox(height: 16),
          Text(
            context.l10n.noEvents,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }
}

// ── Pulsing dot indicator ─────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.45 + 0.55 * _anim.value),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4 * _anim.value),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
