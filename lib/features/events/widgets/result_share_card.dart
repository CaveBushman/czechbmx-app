// Widget pro sdílení výsledku — zachytí se jako obrázek pomocí RepaintBoundary.
// Použití: ResultShareCard.share(context, entry: entry, eventName: '...')
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../models/event_results_model.dart';

class ResultShareCard extends StatelessWidget {
  final EventResultEntry entry;
  final String eventName;
  final String category;

  const ResultShareCard({
    super.key,
    required this.entry,
    required this.eventName,
    required this.category,
  });

  // ── Statická metoda — zachytí widget jako PNG a sdílí přes share_plus ───────
  static Future<void> share(
    BuildContext context, {
    required EventResultEntry entry,
    required String eventName,
    required String category,
  }) async {
    final key = GlobalKey();

    // Zobrazíme overlay s kartičkou (mimo obrazovku) aby šla zachytit.
    final overlay = OverlayEntry(
      builder: (_) => Positioned(
        left: -2000,
        top: 0,
        child: RepaintBoundary(
          key: key,
          child: ResultShareCard(
            entry: entry,
            eventName: eventName,
            category: category,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlay);
    await Future.delayed(const Duration(milliseconds: 120));

    try {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/result_${entry.uciId ?? entry.lastName}_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: '${entry.fullName} — $eventName',
      );
    } finally {
      overlay.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = entry.place;
    final isTop3 = place >= 1 && place <= 3;
    final placeEmoji = switch (place) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '$place.',
    };
    final placeColor = switch (place) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => AppColors.primary,
    };

    return Container(
      width: 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: placeColor.withValues(alpha: isTop3 ? 0.5 : 0.2),
          width: isTop3 ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo + brand
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/Logo_kruh.png', width: 24, height: 24),
              const SizedBox(width: 8),
              const Text(
                'Czech BMX',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Místo
          Text(
            placeEmoji,
            style: TextStyle(
              fontSize: isTop3 ? 64 : 48,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),

          // Jméno
          Text(
            entry.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          if (entry.club.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.club,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Kategorie
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: placeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: placeColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              category,
              style: TextStyle(
                color: placeColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Název závodu
          Text(
            eventName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Body
          if (entry.points > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${entry.points} b.',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],

          const SizedBox(height: 16),
          Text(
            'czechbmx.cz',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
