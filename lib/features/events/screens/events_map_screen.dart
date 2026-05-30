import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../clubs/models/club_model.dart';
import '../../clubs/providers/club_provider.dart';

class EventsMapScreen extends ConsumerWidget {
  const EventsMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(clubsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.clubsMap)),
      body: clubsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (clubs) {
          final mapped =
              clubs.where((c) => c.lat != null && c.lon != null).toList();
          if (mapped.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined,
                      size: 72, color: context.colors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.noEventsWithLocation,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }
          return _MapBody(clubs: mapped);
        },
      ),
    );
  }
}

class _MapBody extends StatefulWidget {
  final List<ClubModel> clubs;

  const _MapBody({required this.clubs});

  @override
  State<_MapBody> createState() => _MapBodyState();
}

class _MapBodyState extends State<_MapBody> {
  late final MapController _mapController;
  late final List<Marker> _markers;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _markers = widget.clubs
        .map(
          (club) => Marker(
            point: LatLng(club.lat!, club.lon!),
            width: 40,
            height: 48,
            child: _MarkerPin(
              onTap: () => _onMarkerTapped(club),
            ),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng get _center {
    final lats = widget.clubs.map((c) => c.lat!);
    final lons = widget.clubs.map((c) => c.lon!);
    return LatLng(
      lats.reduce((a, b) => a + b) / lats.length,
      lons.reduce((a, b) => a + b) / lons.length,
    );
  }

  void _onMarkerTapped(ClubModel club) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _ClubSheet(
        club: club,
        colors: colors,
        textTheme: textTheme,
        onClubDetail: () {
          Navigator.of(sheetCtx).pop();
          context.push('/clubs/${club.id}');
        },
        onNavigate: () {
          Navigator.of(sheetCtx).pop();
          _launchNavigation(club);
        },
      ),
    );
  }

  Future<void> _launchNavigation(ClubModel club) async {
    final lat = club.lat!;
    final lon = club.lon!;
    final label = Uri.encodeComponent(club.name);

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
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 7.5,
        maxZoom: 18,
        minZoom: 5,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.czechbmx_app',
          maxZoom: 18,
        ),
        MarkerLayer(markers: _markers),
      ],
    );
  }
}

// ── Marker pin widget ─────────────────────────────────────────────────────────

class _MarkerPin extends StatelessWidget {
  final VoidCallback onTap;

  const _MarkerPin({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.groups, color: Colors.white, size: 20),
          ),
          CustomPaint(
            size: const Size(12, 8),
            painter: _PinTailPainter(),
          ),
        ],
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
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

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _ClubSheet extends StatelessWidget {
  final ClubModel club;
  final dynamic colors;
  final TextTheme textTheme;
  final VoidCallback onClubDetail;
  final VoidCallback onNavigate;

  const _ClubSheet({
    required this.club,
    required this.colors,
    required this.textTheme,
    required this.onClubDetail,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 32 + MediaQuery.viewPaddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Club name
          Text(club.name, style: textTheme.titleMedium),

          // City
          if (club.city != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: colors.textMuted),
                const SizedBox(width: 4),
                Text(
                  club.city!,
                  style: TextStyle(fontSize: 13, color: colors.textMuted),
                ),
              ],
            ),
          ],

          const SizedBox(height: 18),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onClubDetail,
                  icon: const Icon(Icons.groups_outlined, size: 18),
                  label: const Text(
                    'Detail klubu',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation_outlined, size: 18),
                  label: const Text(
                    'Navigovat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
