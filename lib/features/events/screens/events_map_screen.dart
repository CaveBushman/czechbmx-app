import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../models/event_model.dart';
import '../providers/event_provider.dart';

class EventsMapScreen extends ConsumerWidget {
  const EventsMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.eventsMap)),
      body: eventsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (events) => _MapView(events: events),
      ),
    );
  }
}

class _MapView extends StatelessWidget {
  final List<EventModel> events;

  const _MapView({required this.events});

  @override
  Widget build(BuildContext context) {
    final mapped = events.where((e) => e.hasTrackCoordinates).toList();

    if (mapped.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 72, color: context.colors.textMuted),
            const SizedBox(height: 16),
            Text(
              context.l10n.noEventsWithLocation,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    // Center on Czech Republic as default; shift toward events if available
    final centerLat =
        mapped.map((e) => e.organizerLat!).reduce((a, b) => a + b) /
            mapped.length;
    final centerLon =
        mapped.map((e) => e.organizerLon!).reduce((a, b) => a + b) /
            mapped.length;

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(centerLat, centerLon),
        initialZoom: 7.5,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.czechbmx_app',
        ),
        MarkerLayer(
          markers: mapped
              .map(
                (event) => Marker(
                  point: LatLng(event.organizerLat!, event.organizerLon!),
                  width: 44,
                  height: 54,
                  child: _EventMarker(event: event),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _EventMarker extends StatelessWidget {
  final EventModel event;

  const _EventMarker({required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showEventSheet(context, event),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flag, color: Colors.white, size: 18),
          ),
          CustomPaint(
            size: const Size(12, 8),
            painter: _MarkerTailPainter(),
          ),
        ],
      ),
    );
  }

  void _showEventSheet(BuildContext context, EventModel event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              event.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (event.date != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatDate(event.date!),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: context.colors.textMuted),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/events/${event.id}');
                },
                child: Text(context.l10n.viewDetail),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}. ${date.month}. ${date.year}';
  }
}

class _MarkerTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primary;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
