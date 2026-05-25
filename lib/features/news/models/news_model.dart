import '../../../core/constants/api_constants.dart';

class NewsModel {
  final int id;
  final String title;
  final String? slug;
  final String? prefix;
  final String? content;
  final List<int> tags;
  final String? photo01;
  final String? photo02;
  final String? photo03;
  final int timeToRead;
  final int viewCount;
  final String? audioFile;
  final bool publishedAudio;
  final bool onHomepage;
  final bool published;
  final bool publishInApp;
  final DateTime? createdDate;
  final String? publishDate;

  const NewsModel({
    required this.id,
    required this.title,
    this.slug,
    this.prefix,
    this.content,
    required this.tags,
    this.photo01,
    this.photo02,
    this.photo03,
    required this.timeToRead,
    required this.viewCount,
    this.audioFile,
    required this.publishedAudio,
    required this.onHomepage,
    required this.published,
    required this.publishInApp,
    this.createdDate,
    this.publishDate,
  });

  String? get photo01Url =>
      photo01 != null ? ApiConstants.mediaPath(photo01!) : null;
  String? get photo02Url =>
      photo02 != null ? ApiConstants.mediaPath(photo02!) : null;
  String? get photo03Url =>
      photo03 != null ? ApiConstants.mediaPath(photo03!) : null;
  String? get audioUrl =>
      audioFile != null ? ApiConstants.mediaPath(audioFile!) : null;

  String get identifier => slug ?? id.toString();

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String?,
      prefix: json['prefix'] as String?,
      content: json['content'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      photo01: json['photo_01'] as String?,
      photo02: json['photo_02'] as String?,
      photo03: json['photo_03'] as String?,
      timeToRead: json['time_to_read'] as int? ?? 1,
      viewCount: json['view_count'] as int? ?? 0,
      audioFile: json['audio_file'] as String?,
      publishedAudio: json['published_audio'] as bool? ?? false,
      onHomepage: json['on_homepage'] as bool? ?? false,
      published: json['published'] as bool? ?? false,
      publishInApp: json['publish_in_app'] as bool? ?? false,
      createdDate: json['created_date'] != null
          ? DateTime.tryParse(json['created_date'] as String)
          : null,
      publishDate: json['publish_date'] as String?,
    );
  }
}

class PaginatedNews {
  final int count;
  final String? next;
  final String? previous;
  final List<NewsModel> results;

  const PaginatedNews({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedNews.fromJson(dynamic json) {
    // Handles both paginated {"count":…,"results":[…]} and flat list […]
    if (json is List) {
      final items = json
          .map((e) => NewsModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return PaginatedNews(count: items.length, results: items);
    }
    final map = json as Map<String, dynamic>;
    final results = (map['results'] as List<dynamic>)
        .map((e) => NewsModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedNews(
      count: map['count'] as int? ?? results.length,
      next: map['next'] as String?,
      previous: map['previous'] as String?,
      results: results,
    );
  }
}
