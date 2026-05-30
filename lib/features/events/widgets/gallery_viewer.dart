// Fullscreen prohlížeč fotek s pinch-to-zoom, swipe-to-dismiss a sdílením.
// Používá se z EventGalleryScreen i inline v EventDetailScreen.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../models/event_model.dart';

class GalleryViewer extends StatefulWidget {
  final List<EventPhoto> photos;
  final int initialIndex;

  const GalleryViewer({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  @override
  State<GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<GalleryViewer> {
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

  void _onVerticalDragUpdate(DragUpdateDetails d) =>
      setState(() => _dragOffset += d.delta.dy);

  void _onVerticalDragEnd(DragEndDetails d) {
    if (_dragOffset.abs() > 80 || d.velocity.pixelsPerSecond.dy.abs() > 400) {
      Navigator.pop(context);
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  Future<void> _shareCurrentPhoto() async {
    final photo = widget.photos[_current];
    await Share.share(photo.photoUrl, subject: photo.caption);
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
          duration:
              _dragOffset == 0 ? const Duration(milliseconds: 200) : Duration.zero,
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
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
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
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined,
                            color: Colors.white, size: 22),
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
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
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

// Helper — otevře GalleryViewer jako modální route (fade in/out).
void openGalleryViewer(
  BuildContext context, {
  required List<EventPhoto> photos,
  int initialIndex = 0,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (_, __, ___) =>
          GalleryViewer(photos: photos, initialIndex: initialIndex),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 200),
    ),
  );
}
