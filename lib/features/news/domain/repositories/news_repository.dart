import '../entities/news_article.dart';
import '../../data/models/comment_model.dart';
import '../../data/models/news_api_response.dart';

abstract class NewsRepository {
  // Legacy compat
  Future<List<NewsArticle>> getNewsArticles();
  Future<NewsApiResponse> getNews(
      {int page, int perPage, bool excludeViewed, String? excludeIds, String? cursor, String? feed, int? categoryId});
  Future<void> markViewed(int postId);
  Future<void> markView(int postId);
  Future<Map<String, dynamic>> likePost(int postId);
  Future<CommentListResponse> getComments(int postId, {int perPage = 20, String? cursor, int? parentId});
  Future<CommentModel> postComment(int postId, String comment, {int? parentId});
  Future<Map<String, dynamic>> syncEvents(List<Map<String, dynamic>> events);
}
