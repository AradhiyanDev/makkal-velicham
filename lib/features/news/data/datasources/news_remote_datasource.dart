import 'package:dio/dio.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/comment_model.dart';
import '../models/news_api_response.dart';
import '../models/news_article_model.dart';

abstract class NewsRemoteDataSource {
  Future<NewsApiResponse> getNews(
      {int page = 1, int perPage = 10, bool excludeViewed = false, String? excludeIds, String? cursor, String? feed, int? categoryId});

  /// Trending view: increments posts.views + marks user_post_views.
  Future<void> markView(int postId);
  // Legacy compat — fetches first page
  Future<List<NewsArticleModel>> getNewsArticles();

  /// Mark post as viewed (swipe away, no count increment) — auth only
  Future<void> markViewed(int postId);

  /// Like / Unlike post — auth required
  Future<Map<String, dynamic>> likePost(int postId);

  /// Fetch comments for a post — optional auth, optional pagination (cursor), optional parent for replies
  Future<CommentListResponse> getComments(int postId, {int perPage = 20, String? cursor, int? parentId});

  /// Post a comment — auth required
  Future<CommentModel> postComment(int postId, String comment, {int? parentId});

  Future<Map<String, dynamic>> syncEvents(List<Map<String, dynamic>> events);
}

class NewsRemoteDataSourceImpl implements NewsRemoteDataSource {
  final DioClient dioClient;

  NewsRemoteDataSourceImpl({DioClient? dioClient}) : dioClient = dioClient ?? DioClient();

  @override
  Future<NewsApiResponse> getNews(
      {int page = 1, int perPage = 10, bool excludeViewed = false, String? excludeIds, String? cursor, String? feed, int? categoryId}) async {
    try {
      final queryParameters = <String, dynamic>{'per_page': perPage};
      if (cursor != null && cursor.isNotEmpty) {
        queryParameters['cursor'] = cursor;
      } else {
        queryParameters['page'] = page;
      }
      if (excludeViewed) queryParameters['exclude_viewed'] = 1;
      if (excludeIds != null && excludeIds.isNotEmpty) queryParameters['exclude'] = excludeIds;
      if (feed != null) queryParameters['feed'] = feed;
      if (categoryId != null) queryParameters['category'] = categoryId;
      final response = await dioClient.get<Map<String, dynamic>>(
        ApiConstants.newsPath,
        queryParameters: queryParameters,
      );

      final data = response.data;
      if (data == null) throw DioException(requestOptions: response.requestOptions, error: 'Empty response');
      if (data['error'] == true) {
        throw DioException(requestOptions: response.requestOptions, error: data['message'] ?? 'API error');
      }
      return NewsApiResponse.fromJson(data);
    } on DioException catch (e) {
      // Surface friendly message via error field from interceptor
      final friendly = e.error?.toString() ?? e.message ?? 'Network error';
      throw Exception(friendly);
    }
  }

  @override
  Future<List<NewsArticleModel>> getNewsArticles() async {
    final res = await getNews(page: 1, perPage: 10);
    return res.data;
  }

  @override
  Future<void> markViewed(int postId) async {
    await dioClient.post<Map<String, dynamic>>('/api/v1/mobile/posts/$postId/viewed', data: {});
  }

  @override
  Future<void> markView(int postId) async {
    await dioClient.post<Map<String, dynamic>>('/api/v1/mobile/posts/$postId/view', data: {});
  }

  @override
  Future<Map<String, dynamic>> likePost(int postId) async {
    final res = await dioClient.post<Map<String, dynamic>>('/api/v1/mobile/posts/$postId/like', data: {});
    return res.data ?? {};
  }

  @override
  Future<CommentListResponse> getComments(int postId, {int perPage = 20, String? cursor, int? parentId}) async {
    try {
      final queryParams = <String, dynamic>{'per_page': perPage};
      if (cursor != null) queryParams['cursor'] = cursor;
      if (parentId != null) queryParams['parent_id'] = parentId;
      final response = await dioClient.get<Map<String, dynamic>>(
        '/api/v1/mobile/posts/$postId/comments',
        queryParameters: queryParams,
      );
      final data = response.data;
      if (data == null) throw DioException(requestOptions: response.requestOptions, error: 'Empty response');
      if (data['error'] == true) {
        throw DioException(requestOptions: response.requestOptions, error: data['message'] ?? 'API error');
      }
      return CommentListResponse.fromJson(data);
    } on DioException catch (e) {
      final friendly = e.error?.toString() ?? e.message ?? 'Network error';
      throw Exception(friendly);
    }
  }

  @override
  Future<Map<String, dynamic>> syncEvents(List<Map<String, dynamic>> events) async {
    final res = await dioClient.post<Map<String, dynamic>>('/api/v1/mobile/events/batch', data: {'events': events});
    return res.data ?? {};
  }

  @override
  Future<CommentModel> postComment(int postId, String comment, {int? parentId}) async {
    try {
      final body = {'comment': comment, 'parent_id': parentId ?? 0};
      final res = await dioClient.post<Map<String, dynamic>>('/api/v1/mobile/posts/$postId/comments', data: body);
      final data = res.data ?? {};
      if (data['error'] == true) {
        throw DioException(requestOptions: res.requestOptions, error: data['message'] ?? 'Failed to post comment');
      }
      final payload = data['data'];
      if (payload is Map<String, dynamic>) {
        return CommentModel.fromJson(payload, fallbackAuthor: 'You');
      }
      throw DioException(requestOptions: res.requestOptions, error: 'Invalid comment response');
    } on DioException catch (e) {
      final friendly = e.error?.toString() ?? e.message ?? 'Network error';
      throw Exception(friendly);
    }
  }
}
