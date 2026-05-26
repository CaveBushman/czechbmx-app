import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/in_app_browser.dart';
import '../../../core/widgets/splash_screen.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../models/news_model.dart';
import '../providers/news_provider.dart';
import '../widgets/audio_player_widget.dart';

class NewsDetailScreen extends HookConsumerWidget {
  final String slug;

  const NewsDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsDetailProvider(slug));

    return newsAsync.when(
      loading: () => const SplashScreen(),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded,
                    size: 64, color: context.colors.textMuted),
                const SizedBox(height: 16),
                Text(
                  context.l10n.newsLoadFailed,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.invalidate(newsDetailProvider(slug)),
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (news) => _NewsDetailBody(news: news),
    );
  }
}

class _NewsDetailBody extends HookConsumerWidget {
  final NewsModel news;

  const _NewsDetailBody({required this.news});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = ref.watch(currentLocaleCodeProvider);
    final scrollController = useScrollController();
    final showTitle = useState(false);
    final colors = context.colors;

    useEffect(() {
      void listener() => showTitle.value = scrollController.offset > 200;
      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    }, [scrollController]);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(newsDetailProvider(news.slug ?? news.id.toString())),
        child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            title: AnimatedOpacity(
              opacity: showTitle.value ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                news.localizedTitle(localeCode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: context.l10n.share,
                onPressed: () {
                  final identifier = news.slug ?? news.id.toString();
                  Share.share('https://czechbmx.cz/news/$identifier');
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (news.photo01Url != null)
                    Hero(
                      tag: 'news_${news.id}',
                      child: CachedNetworkImage(
                        imageUrl: news.photo01Url!,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(color: colors.surfaceVariant),
                  DecoratedBox(
                    decoration: BoxDecoration(gradient: colors.cardOverlay),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetaRow(news: news),
                  const SizedBox(height: 16),
                  Text(
                    news.localizedTitle(localeCode),
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  if (news.publishedAudio) ...[
                    Builder(builder: (ctx) {
                      final url = news.audioUrlForLocale(localeCode);
                      if (url == null) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          NewsAudioPlayer(url: url),
                        ],
                      );
                    }),
                  ],
                  Builder(builder: (ctx) {
                    final lp = news.localizedPrefix(localeCode);
                    if (lp == null || lp.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _HtmlContent(html: lp, isLead: true),
                    );
                  }),
                  Builder(builder: (ctx) {
                    final lc = news.localizedContent(localeCode);
                    if (lc == null || lc.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Divider(color: colors.divider),
                        const SizedBox(height: 20),
                        _HtmlContent(html: lc),
                      ],
                    );
                  }),
                  if (news.photo02Url != null || news.photo03Url != null) ...[
                    const SizedBox(height: 24),
                    _AdditionalPhotos(news: news),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      ),  // RefreshIndicator
    );
  }
}

class _MetaRow extends StatelessWidget {
  final NewsModel news;
  const _MetaRow({required this.news});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final iconColor = context.colors.textMuted;
    final date =
        news.publishDate != null ? _fmt(context, news.publishDate!) : null;

    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        if (date != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: iconColor),
              const SizedBox(width: 5),
              Text(date, style: style),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 14, color: iconColor),
            const SizedBox(width: 5),
            Text('${news.timeToRead} ${context.l10n.minutesReadSuffix}',
                style: style),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_outlined, size: 14, color: iconColor),
            const SizedBox(width: 5),
            Text('${news.viewCount} ${context.l10n.viewsSuffix}', style: style),
          ],
        ),
      ],
    );
  }

  String _fmt(BuildContext context, String dateStr) {
    try {
      return DateFormat('d. MMMM yyyy', context.l10n.languageCode)
          .format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }
}

class _HtmlContent extends StatelessWidget {
  final String html;
  final bool isLead;
  const _HtmlContent({required this.html, this.isLead = false});

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.brightness == Brightness.dark;
    final blockquoteColor = isDark ? '#94A3B8' : '#475569';

    final textStyle = isLead
        ? Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: context.colors.textSecondary,
              fontStyle: FontStyle.italic,
            )
        : Theme.of(context).textTheme.bodyLarge;

    return HtmlWidget(
      html,
      textStyle: textStyle,
      onTapUrl: (url) async {
        final uri = Uri.tryParse(url);
        final isWebUrl = uri?.scheme == 'http' || uri?.scheme == 'https';
        if (uri == null || !isWebUrl) return false;
        final isYt = uri.host.contains('youtube.com') || uri.host.contains('youtu.be');
        if (isYt) {
          // YouTube links are opened in the external player/application.
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else if (context.mounted) {
          // Other web content is displayed inside our in-app browser.
          openInApp(context, url);
        }
        return true;
      },
      customStylesBuilder: (element) {
        switch (element.localName) {
          case 'a':
            return {'color': '#E84000', 'text-decoration': 'none'};
          case 'blockquote':
            return {
              'border-left': '3px solid #E84000',
              'padding-left': '12px',
              'margin-left': '0',
              'color': blockquoteColor,
            };
          case 'p':
          case 'div':
            return {'margin-top': '0', 'margin-bottom': '8px'};
          case 'h1':
          case 'h2':
          case 'h3':
          case 'h4':
            return {'margin-top': '14px', 'margin-bottom': '4px'};
          case 'ul':
          case 'ol':
            return {'margin-top': '0', 'margin-bottom': '8px', 'padding-left': '20px'};
          case 'li':
            return {'margin-bottom': '2px'};
        }
        return null;
      },
    );
  }
}

class _AdditionalPhotos extends StatelessWidget {
  final NewsModel news;
  const _AdditionalPhotos({required this.news});

  @override
  Widget build(BuildContext context) {
    final photos = [
      news.photo02Url,
      news.photo03Url,
    ].whereType<String>().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.gallery,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...photos.map(
          (url) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: url,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
