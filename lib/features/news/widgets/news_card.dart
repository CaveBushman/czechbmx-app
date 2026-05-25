import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:html/parser.dart' show parse;
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../models/news_model.dart';

// Strips HTML tags and decodes entities from an HTML string.
String _stripHtml(String html) {
  final doc = parse(html);
  return doc.body?.text.trim() ?? '';
}

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
        onTap: () {
          HapticFeedback.lightImpact();
          context.go('/news/${news.identifier}');
        },
        child: TweenAnimationBuilder<Offset>(
          tween: Tween(begin: Offset.zero, end: tilt.value),
          duration: tilt.value == Offset.zero
              ? const Duration(milliseconds: 450)
              : const Duration(milliseconds: 80),
          curve:
              tilt.value == Offset.zero ? Curves.easeOutBack : Curves.easeOut,
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
              ), // Transform
            ); // AnimatedScale
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
                placeholder: (_, __) =>
                    Container(color: context.colors.surfaceVariant),
                errorWidget: (_, __, ___) =>
                    Container(color: context.colors.surfaceVariant),
              ),
            )
          else
            Container(color: context.colors.surfaceVariant),

          // Full-card contrast layer. The left and bottom scrims keep text readable
          // even on bright posters or logos.
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.35, -0.25),
                radius: 1.25,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.28),
                ],
                stops: const [0.35, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.82),
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.12),
                ],
                stops: const [0.0, 0.48, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.92),
                  Colors.black.withValues(alpha: 0.56),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.36, 0.78],
              ),
            ),
          ),

          // Top badges
          Positioned(
            top: 12,
            left: 12,
            child: _Badge(
              label: context.l10n.featuredArticle,
              color: AppColors.primary,
            ),
          ),
          if (news.publishedAudio)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.headphones, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'AUDIO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                    color: Colors.white,
                    height: 1.05,
                    shadows: [
                      const Shadow(
                        blurRadius: 16,
                        color: Colors.black87,
                        offset: Offset(0, 2),
                      ),
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

// ── Standard card — vertical editorial layout ─────────────────────────────────

class _StandardCard extends HookWidget {
  final NewsModel news;
  const _StandardCard({required this.news});

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final colors = context.colors;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go('/news/${news.identifier}');
      },
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
            color: colors.card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: pressed.value
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full-width image
              Stack(
                children: [
                  if (news.photo01Url != null)
                    Hero(
                      tag: 'news_${news.id}',
                      child: CachedNetworkImage(
                        imageUrl: news.photo01Url!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 160,
                          color: colors.surfaceVariant,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 160,
                          color: colors.surfaceVariant,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 100,
                      color: colors.surfaceVariant,
                      child: Center(
                        child: Icon(
                          Icons.newspaper_outlined,
                          size: 36,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  // Audio badge on image
                  if (news.publishedAudio)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.headphones,
                                size: 13, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'AUDIO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              // Text block
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            height: 1.3,
                          ),
                    ),
                    if (news.prefix != null && news.prefix!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        _stripHtml(news.prefix!),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: colors.textSecondary,
                              height: 1.4,
                            ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _MetaRow(news: news),
                  ],
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
    final date = news.publishDate != null
        ? _formatDate(context, news.publishDate!)
        : null;

    return Wrap(
      spacing: 12,
      children: [
        if (date != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined, size: 12, color: iconColor),
              const SizedBox(width: 4),
              Text(date, style: style),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 12, color: iconColor),
            const SizedBox(width: 4),
            Text('${news.timeToRead} ${context.l10n.minutesShort}',
                style: style),
          ],
        ),
      ],
    );
  }

  String _formatDate(BuildContext context, String dateStr) {
    try {
      return DateFormat('d. M. yyyy', context.l10n.languageCode)
          .format(DateTime.parse(dateStr));
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
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
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
