import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/news_model.dart';
import '../news_repository.dart';

class NewsPageState {
  final List<NewsModel> articles;
  final bool hasMore;
  final bool isLoadingMore;
  final int nextPage;
  final String? searchQuery;

  const NewsPageState({
    required this.articles,
    required this.hasMore,
    this.isLoadingMore = false,
    this.nextPage = 2,
    this.searchQuery,
  });

  NewsPageState copyWith({
    List<NewsModel>? articles,
    bool? hasMore,
    bool? isLoadingMore,
    int? nextPage,
    String? searchQuery,
    bool clearSearch = false,
  }) =>
      NewsPageState(
        articles: articles ?? this.articles,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        nextPage: nextPage ?? this.nextPage,
        searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      );
}

final newsListProvider = AsyncNotifierProvider<NewsListNotifier, NewsPageState>(
  NewsListNotifier.new,
);

class NewsListNotifier extends AsyncNotifier<NewsPageState> {
  @override
  Future<NewsPageState> build() async {
    final page = await ref.read(newsRepositoryProvider).fetchNews(page: 1);
    return NewsPageState(articles: page.items, hasMore: page.hasMore);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final page = await ref
          .read(newsRepositoryProvider)
          .fetchNews(page: current.nextPage, search: current.searchQuery);
      final existingIds = current.articles.map((e) => e.id).toSet();
      final fresh =
          page.items.where((e) => !existingIds.contains(e.id)).toList();
      state = AsyncData(
        current.copyWith(
          articles: [...current.articles, ...fresh],
          hasMore: page.hasMore,
          isLoadingMore: false,
          nextPage: current.nextPage + 1,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refresh() async {
    final q = state.valueOrNull?.searchQuery;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final page = await ref
          .read(newsRepositoryProvider)
          .fetchNews(page: 1, search: q, forceRefresh: true);
      return NewsPageState(
        articles: page.items,
        hasMore: page.hasMore,
        searchQuery: q,
      );
    });
  }

  Future<void> search(String query) async {
    final q = query.trim().isEmpty ? null : query.trim();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final page =
          await ref.read(newsRepositoryProvider).fetchNews(page: 1, search: q);
      return NewsPageState(
        articles: page.items,
        hasMore: page.hasMore,
        searchQuery: q,
      );
    });
  }
}

final newsDetailProvider =
    AsyncNotifierProviderFamily<NewsDetailNotifier, NewsModel, String>(
  NewsDetailNotifier.new,
);

class NewsDetailNotifier extends FamilyAsyncNotifier<NewsModel, String> {
  @override
  Future<NewsModel> build(String slugOrId) async {
    final cached = ref
        .read(newsListProvider)
        .valueOrNull
        ?.articles
        .where((n) => n.slug == slugOrId || n.id.toString() == slugOrId)
        .firstOrNull;
    if (cached != null) return cached;
    return ref.read(newsRepositoryProvider).fetchNewsDetail(slugOrId);
  }
}
