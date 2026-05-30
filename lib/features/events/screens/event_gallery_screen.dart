// Fullscreen grid galerie fotek jednoho závodu.
// Otevírá se z tlačítka "Fotky (N)" v EventDetailScreen.
// Klikem na thumbnail se otevře GalleryViewer (fullscreen + swipe + zoom).
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../models/event_model.dart';
import '../widgets/gallery_viewer.dart';

class EventGalleryScreen extends StatelessWidget {
  final String eventName;
  final List<EventPhoto> photos;

  const EventGalleryScreen({
    super.key,
    required this.eventName,
    required this.photos,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.gallery),
            if (eventName.isNotEmpty)
              Text(
                eventName,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: context.colors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => openGalleryViewer(
              context,
              photos: photos,
              initialIndex: index,
            ),
            child: Hero(
              tag: 'gallery_photo_${photos[index].id}',
              child: CachedNetworkImage(
                imageUrl: photos[index].photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: context.colors.surfaceVariant,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: context.colors.surfaceVariant,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: context.colors.textMuted.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
