import '../../domain/entities/news_article.dart';
import '../../domain/repositories/news_repository.dart';
import '../datasources/news_remote_datasource.dart';
import '../models/comment_model.dart';
import '../models/news_api_response.dart';

class _CachedComments {
  final CommentListResponse response;
  final DateTime fetchedAt;
  const _CachedComments(this.response, this.fetchedAt);
}

class NewsRepositoryImpl implements NewsRepository {
  static const commentsCacheTtl = Duration(seconds: 30);

  final NewsRemoteDataSource remoteDataSource;
  final Map<int, _CachedComments> _commentsCache = {};

  NewsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<NewsArticle>> getNewsArticles() async {
    try {
      final models = await remoteDataSource.getNewsArticles();
      return models;
    } catch (e) {
      throw Exception('Failed to fetch news: $e');
    }
  }

  @override
  Future<NewsApiResponse> getNews(
      {int page = 1, int perPage = 10, bool excludeViewed = false, String? excludeIds, String? cursor, String? feed, int? categoryId}) async {
    try {
      return await remoteDataSource.getNews(
        page: page,
        perPage: perPage,
        excludeViewed: excludeViewed,
        excludeIds: excludeIds,
        cursor: cursor,
        feed: feed,
        categoryId: categoryId,
      );
    } catch (e) {
      throw Exception('Failed to fetch news: $e');
    }
  }

  @override
  Future<void> markViewed(int postId) async {
    try {
      await remoteDataSource.markViewed(postId);
    } catch (e) {
      throw Exception('Failed to mark viewed: $e');
    }
  }

  @override
  Future<void> markView(int postId) async {
    try {
      await remoteDataSource.markView(postId);
    } catch (e) {
      throw Exception('Failed to mark view: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> likePost(int postId) async {
    try {
      return await remoteDataSource.likePost(postId);
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  @override
  Future<CommentListResponse> getComments(int postId, {int perPage = 20, String? cursor, int? parentId}) async {
    // Replies or cursor paginated comments should not use stale cache
    if (cursor != null || parentId != null) {
      try {
        return await remoteDataSource.getComments(postId, perPage: perPage, cursor: cursor, parentId: parentId);
      } catch (e) {
        throw Exception('Failed to fetch comments: $e');
      }
    }
    final cached = _commentsCache[postId];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < commentsCacheTtl) {
      return cached.response;
    }
    try {
      final res = await remoteDataSource.getComments(postId, perPage: perPage);
      _commentsCache[postId] = _CachedComments(res, DateTime.now());
      return res;
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> syncEvents(List<Map<String, dynamic>> events) async {
    try {
      return await remoteDataSource.syncEvents(events);
    } catch (e) {
      throw Exception('Failed to sync events: $e');
    }
  }

  @override
  Future<CommentModel> postComment(int postId, String comment, {int? parentId}) async {
    try {
      final created =
          await remoteDataSource.postComment(postId, comment, parentId: parentId);
      // Posting invalidates the cached list so the next open refetches.
      _commentsCache.remove(postId);
      return created;
    } catch (e) {
      throw Exception('Failed to post comment: $e');
    }
  }
}
