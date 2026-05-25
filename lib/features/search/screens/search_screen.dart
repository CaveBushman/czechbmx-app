import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../news/models/news_model.dart';
import '../../news/news_repository.dart';
import '../../riders/models/rider_model.dart';
import '../../riders/rider_repository.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _newsSearchProvider =
    FutureProvider.family<List<NewsModel>, String>((ref, query) async {
  if (query.length < 2) return [];
  final page = await ref.read(newsRepositoryProvider).fetchNews(search: query);
  return page.items.take(8).toList();
});

final _ridersSearchProvider =
    FutureProvider.family<List<RiderModel>, String>((ref, query) async {
  if (query.length < 2) return [];
  final results = await ref
      .read(riderRepositoryProvider)
      .fetchRiders(filter: RidersFilter(search: query));
  return results.take(8).toList();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class SearchScreen extends HookConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final query = useState('');
    final debounce = useRef<Timer?>(null);

    useEffect(() {
      void listener() {
        debounce.value?.cancel();
        debounce.value = Timer(const Duration(milliseconds: 400), () {
          query.value = controller.text.trim();
        });
      }

      controller.addListener(listener);
      return () {
        debounce.value?.cancel();
        controller.removeListener(listener);
      };
    }, [controller]);

    final newsAsync = ref.watch(_newsSearchProvider(query.value));
    final ridersAsync = ref.watch(_ridersSearchProvider(query.value));

    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: controller,
          autofocus: true,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            hintStyle: TextStyle(color: colors.textMuted),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          ),
        ),
        actions: [
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                controller.clear();
                query.value = '';
              },
            ),
        ],
      ),
      body: query.value.length < 2
          ? _EmptyHint(text: l10n.searchMinChars)
          : _Results(
              query: query.value,
              newsAsync: newsAsync,
              ridersAsync: ridersAsync,
            ),
    );
  }
}

// ── Results ───────────────────────────────────────────────────────────────────

class _Results extends StatelessWidget {
  final String query;
  final AsyncValue<List<NewsModel>> newsAsync;
  final AsyncValue<List<RiderModel>> ridersAsync;

  const _Results({
    required this.query,
    required this.newsAsync,
    required this.ridersAsync,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final newsItems = newsAsync.valueOrNull ?? [];
    final riderItems = ridersAsync.valueOrNull ?? [];
    final loading =
        newsAsync is AsyncLoading || ridersAsync is AsyncLoading;

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (newsItems.isEmpty && riderItems.isEmpty) {
      return _EmptyHint(text: l10n.noSearchResults);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (riderItems.isNotEmpty) ...[
          _SectionHeader(title: l10n.searchRidersSection),
          ...riderItems.map((r) => _RiderTile(rider: r)),
        ],
        if (newsItems.isNotEmpty) ...[
          _SectionHeader(title: l10n.searchNewsSection),
          ...newsItems.map((n) => _NewsTile(news: n)),
        ],
      ],
    );
  }
}

// ── Tiles ─────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: context.colors.textMuted,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _NewsTile extends StatelessWidget {
  final NewsModel news;
  const _NewsTile({required this.news});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: news.photo01Url != null
            ? CachedNetworkImage(
                imageUrl: news.photo01Url!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              )
            : Container(
                width: 56,
                height: 56,
                color: context.colors.surfaceVariant,
                child: Icon(Icons.newspaper_outlined,
                    color: context.colors.textMuted),
              ),
      ),
      title: Text(
        news.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: news.publishDate != null
          ? Text(
              news.publishDate!.substring(0, 10),
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      onTap: () => context.push('/news/${news.identifier}'),
    );
  }
}

class _RiderTile extends StatelessWidget {
  final RiderModel rider;
  const _RiderTile({required this.rider});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: context.colors.surfaceVariant,
        backgroundImage: rider.photoUrl != null
            ? CachedNetworkImageProvider(rider.photoUrl!)
            : null,
        child: rider.photoUrl == null
            ? Icon(Icons.person_outline,
                color: context.colors.textMuted)
            : null,
      ),
      title: Text(
        '${rider.firstName} ${rider.lastName}',
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        'UCI ${rider.uciId}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: () => context.push('/riders/${rider.uciId}'),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_outlined,
              size: 64,
              color: context.colors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: context.colors.textMuted,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
