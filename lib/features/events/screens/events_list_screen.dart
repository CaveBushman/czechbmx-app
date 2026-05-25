import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../models/event_model.dart';
import '../providers/event_provider.dart';
import '../widgets/event_card.dart';

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
              title: const Text('Závody'),
              actions: [
                _YearPicker(year: year, ref: ref),
              ],
            ),
            eventsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (err, _) => SliverFillRemaining(
                child: _ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.read(eventsProvider.notifier).refresh(),
                ),
              ),
              data: (events) {
                if (events.isEmpty) return const SliverFillRemaining(child: _EmptyView());
                return _EventsCalendar(events: events);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EventsCalendar extends ConsumerWidget {
  final List<EventModel> events;

  const _EventsCalendar({required this.events});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byMonth = ref.watch(eventsByMonthProvider);
    final months = byMonth.keys.toList()..sort();

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      sliver: SliverList.builder(
        itemCount: months.length,
        itemBuilder: (context, index) {
          final month = months[index];
          final monthEvents = byMonth[month]!;
          return _MonthSection(month: month, events: monthEvents);
        },
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  final int month;
  final List<EventModel> events;

  const _MonthSection({required this.month, required this.events});

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM', 'cs')
        .format(DateTime(2000, month))
        .toUpperCase();

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
              Expanded(child: Divider(color: AppColors.primary.withValues(alpha: 0.3))),
              const SizedBox(width: 8),
              Text(
                '${events.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        ...events.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: EventCard(event: e),
          ),
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
          onPressed: () => ref.read(selectedYearProvider.notifier).state = year - 1,
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
                  color: year == currentYear ? AppColors.primary : context.colors.textPrimary,
                ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => ref.read(selectedYearProvider.notifier).state = year + 1,
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
      title: const Text('Vybrat rok'),
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
          Icon(Icons.wifi_off_rounded, size: 64, color: context.colors.textMuted),
          const SizedBox(height: 16),
          Text('Nepodařilo se načíst závody',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Zkusit znovu'),
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
          Text('Žádné závody', style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }
}
