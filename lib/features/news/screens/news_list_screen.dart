import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../models/news_model.dart';
import '../providers/news_provider.dart';
import '../widgets/news_card.dart';
import '../widgets/news_shimmer.dart';

class NewsListScreen extends HookConsumerWidget {
  const NewsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsListProvider);
    final scrollController = useScrollController();
    final isSearching = useState(false);
    final searchCtrl = useTextEditingController();
    final searchDebounce = useRef<Timer?>(null);

    // Infinite scroll trigger
    useEffect(() {
      void onScroll() {
        final pos = scrollController.position;
        if (pos.pixels >= pos.maxScrollExtent - 300) {
          ref.read(newsListProvider.notifier).loadMore();
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    // Close search on back
    useEffect(() {
      return () {
        searchDebounce.value?.cancel();
      };
    }, const []);

    void closeSearch() {
      isSearching.value = false;
      searchCtrl.clear();
      searchDebounce.value?.cancel();
      ref.read(newsListProvider.notifier).search('');
    }

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(newsListProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 60,
              floating: true,
              snap: true,
              title: isSearching.value
                  ? TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: context.l10n.searchArticles,
                        hintStyle: TextStyle(color: context.colors.textMuted),
                        border: InputBorder.none,
                      ),
                      onChanged: (q) {
                        searchDebounce.value?.cancel();
                        searchDebounce.value = Timer(
                          const Duration(milliseconds: 400),
                          () => ref
                              .read(newsListProvider.notifier)
                              .search(q),
                        );
                      },
                    )
                  : Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'B',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(context.l10n.appTitle),
                      ],
                    ),
              actions: [
                if (isSearching.value)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: closeSearch,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => isSearching.value = true,
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  context.l10n.news,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
            ),
            newsAsync.when(
              loading: () =>
                  const SliverFillRemaining(child: NewsListShimmer()),
              error: (err, _) => SliverFillRemaining(
                child: _ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.read(newsListProvider.notifier).refresh(),
                ),
              ),
              data: (pageState) {
                if (pageState.articles.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyView(
                      isSearch: pageState.searchQuery != null,
                    ),
                  );
                }
                return _NewsList(
                  articles: pageState.articles,
                  isLoadingMore: pageState.isLoadingMore,
                  hasMore: pageState.hasMore,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── List with staggered entrance ─────────────────────────────────────────────

class _NewsList extends StatelessWidget {
  final List<NewsModel> articles;
  final bool isLoadingMore;
  final bool hasMore;

  const _NewsList({
    required this.articles,
    required this.isLoadingMore,
    required this.hasMore,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          // Footer slot
          if (index == articles.length) {
            return _ListFooter(isLoadingMore: isLoadingMore, hasMore: hasMore);
          }

          final news = articles[index];
          final isFeatured = index == 0;
          return _AnimatedNewsItem(
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NewsCard(news: news, featured: isFeatured),
            ),
          );
        }, childCount: articles.length + 1),
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  final bool isLoadingMore;
  final bool hasMore;

  const _ListFooter({required this.isLoadingMore, required this.hasMore});

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.only(top: 4, bottom: 24),
        child: NewsCardSkeleton(),
      );
    }
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            '— ${context.l10n.news} —',
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(color: context.colors.textMuted),
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
  }
}

// ── Staggered fade + slide entrance ─────────────────────────────────────────

class _AnimatedNewsItem extends HookWidget {
  final Widget child;
  final int index;

  const _AnimatedNewsItem({required this.child, required this.index});

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 480),
    );

    useEffect(() {
      var alive = true;
      final delayMs = (index * 65).clamp(0, 390);
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (alive) controller.forward();
      });
      return () => alive = false;
    }, const []);

    final opacity = CurvedAnimation(parent: controller, curve: Curves.easeOut);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

// ── Error / empty states ──────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              context.l10n.newsLoadFailed,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool isSearch;
  const _EmptyView({this.isSearch = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.newspaper_outlined,
            size: 64,
            color: context.colors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? context.l10n.noNews : context.l10n.noNews,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }
}
