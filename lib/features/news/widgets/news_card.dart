import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../models/news_model.dart';

class NewsCard extends StatelessWidget {
  final NewsModel news;
  final bool featured;

  const NewsCard({super.key, required this.news, this.featured = false});

  @override
  Widget build(BuildContext context) {
    return featured ? _FeaturedCard(news: news) : _StandardCard(news: news);
  }
}

// ── Featured (hero) card with 3D tilt ────────────────────────────────────────

class _FeaturedCard extends HookWidget {
  final NewsModel news;
  const _FeaturedCard({required this.news});

  @override
  Widget build(BuildContext context) {
    final tilt = useState(Offset.zero);
    final pressed = useState(false);

    void onPointerMove(PointerEvent event) {
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;
      final local = box.globalToLocal(event.position);
      tilt.value = Offset(
        ((local.dx / box.size.width) - 0.5).clamp(-1.0, 1.0),
        ((local.dy / box.size.height) - 0.5).clamp(-1.0, 1.0),
      );
      pressed.value = true;
    }

    void onPointerEnd(PointerEvent _) {
      tilt.value = Offset.zero;
      pressed.value = false;
    }

    return Listener(
      onPointerMove: onPointerMove,
      onPointerUp: onPointerEnd,
      onPointerCancel: onPointerEnd,
      child: GestureDetector(
        onTap: () => context.go('/news/${news.identifier}'),
        child: TweenAnimationBuilder<Offset>(
          tween: Tween(begin: Offset.zero, end: tilt.value),
          duration: tilt.value == Offset.zero
              ? const Duration(milliseconds: 450)
              : const Duration(milliseconds: 80),
          curve: tilt.value == Offset.zero ? Curves.easeOutBack : Curves.easeOut,
          builder: (context, value, child) {
            final intensity = value.distance;
            return AnimatedScale(
              scale: pressed.value ? 0.975 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateX(-value.dy * 0.28)
                ..rotateY(value.dx * 0.28),
              alignment: Alignment.center,
              child: Stack(
                children: [
                  child!,
                  // Specular shine that moves with tilt
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(
                                (-value.dx * 1.8).clamp(-1.5, 1.5),
                                (-value.dy * 1.8).clamp(-1.5, 1.5),
                              ),
                              radius: 1.2,
                              colors: [
                                Colors.white.withValues(
                                  alpha: (0.35 * intensity).clamp(0, 0.28),
                                ),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.65],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),  // Transform
            );  // AnimatedScale
          },
          child: _FeaturedCardContent(news: news),
        ),
      ),
    );
  }
}

class _FeaturedCardContent extends StatelessWidget {
  final NewsModel news;
  const _FeaturedCardContent({required this.news});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Hero image
          if (news.photo01Url != null)
            Hero(
              tag: 'news_${news.id}',
              child: CachedNetworkImage(
                imageUrl: news.photo01Url!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: context.colors.surfaceVariant),
                errorWidget: (_, __, ___) => Container(color: context.colors.surfaceVariant),
              ),
            )
          else
            Container(color: context.colors.surfaceVariant),

          // Gradient overlay
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.75),
                ],
                stops: const [0.3, 0.55, 1.0],
              ),
            ),
          ),

          // Top badge
          const Positioned(
            top: 12,
            left: 12,
            child: _Badge(label: 'Hlavní článek', color: AppColors.primary),
          ),

          // Bottom: title + meta
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                    color: Colors.white,
                    shadows: [
                      const Shadow(blurRadius: 12, color: Colors.black54),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _MetaRow(news: news),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Standard card with press animation ───────────────────────────────────────

class _StandardCard extends HookWidget {
  final NewsModel news;
  const _StandardCard({required this.news});

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);

    return GestureDetector(
      onTap: () => context.go('/news/${news.identifier}'),
      onTapDown: (_) => pressed.value = true,
      onTapUp: (_) => pressed.value = false,
      onTapCancel: () => pressed.value = false,
      child: AnimatedScale(
        scale: pressed.value ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(12),
            boxShadow: pressed.value
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              if (news.photo01Url != null)
                Hero(
                  tag: 'news_${news.id}',
                  child: CachedNetworkImage(
                    imageUrl: news.photo01Url!,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(width: 110, height: 110, color: context.colors.surfaceVariant),
                    errorWidget: (_, __, ___) =>
                        Container(width: 110, height: 110, color: context.colors.surfaceVariant),
                  ),
                )
              else
                Container(
                  width: 110,
                  height: 110,
                  color: context.colors.surfaceVariant,
                  child: Icon(Icons.image_not_supported_outlined,
                      color: context.colors.textMuted),
                ),

              // Text
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      _MetaRow(news: news),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable pieces ───────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final NewsModel news;
  const _MetaRow({required this.news});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final iconColor = context.colors.textMuted;
    final date = news.publishDate != null ? _formatDate(news.publishDate!) : null;

    return Wrap(
      spacing: 12,
      children: [
        if (date != null)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.calendar_today_outlined, size: 12, color: iconColor),
            const SizedBox(width: 4),
            Text(date, style: style),
          ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.timer_outlined, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text('${news.timeToRead} min', style: style),
        ]),
        if (news.publishedAudio)
          const Icon(Icons.headphones, size: 14, color: AppColors.primary),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      return DateFormat('d. M. yyyy', 'cs').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
