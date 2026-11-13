import 'news_article_model.dart';

class NewsApiResponse {
  final List<NewsArticleModel> data;
  final String? nextPageUrl;
  final String? prevPageUrl;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final String? nextCursor;
  final bool hasMore;

  const NewsApiResponse({
    required this.data,
    required this.nextPageUrl,
    required this.prevPageUrl,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.nextCursor,
    this.hasMore = false,
  });

  factory NewsApiResponse.fromJson(Map<String, dynamic> json) {
    final dataList = (json['data'] as List? ?? [])
        .map((e) => NewsArticleModel.fromApiJson(e as Map<String, dynamic>))
        .toList();

    final links = json['links'] as Map<String, dynamic>?;
    final meta = json['meta'] as Map<String, dynamic>? ?? json['additional'] as Map<String, dynamic>?;

    // Cursor fields (new) - fallback to page fields
    final nextCursor = meta?['next_cursor'] as String?;
    final hasMore = (meta?['has_more'] as bool?) ?? (meta?['hasMore'] as bool?) ?? false;

    return NewsApiResponse(
      data: dataList,
      nextPageUrl: links?['next'] as String?,
      prevPageUrl: links?['prev'] as String?,
      currentPage: (meta?['current_page'] as int?) ?? 1,
      lastPage: (meta?['last_page'] as int?) ?? 1,
      perPage: (meta?['per_page'] as int?) ?? 10,
      total: (meta?['total'] as int?) ?? dataList.length,
      nextCursor: nextCursor,
      hasMore: hasMore || nextCursor != null,
    );
  }

  bool get hasNextPage => hasMore || (nextPageUrl != null && currentPage < lastPage);
}
