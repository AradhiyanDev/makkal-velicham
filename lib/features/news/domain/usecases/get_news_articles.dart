import 'package:equatable/equatable.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/news_article.dart';
import '../repositories/news_repository.dart';
import '../../data/models/news_api_response.dart';

class GetNewsParams extends Equatable {
  final int page;
  final int perPage;
  final bool excludeViewed;
  final String? excludeIds;
  final String? cursor;
  final String? feed; // latest | for_you
  final int? categoryId;
  const GetNewsParams(
      {this.page = 1,
      this.perPage = 10,
      this.excludeViewed = false,
      this.excludeIds,
      this.cursor,
      this.feed,
      this.categoryId});
  @override
  List<Object?> get props => [page, perPage, excludeViewed, excludeIds, cursor, feed, categoryId];
}

class GetNewsArticles implements UseCase<NewsApiResponse, GetNewsParams> {
  final NewsRepository repository;

  GetNewsArticles(this.repository);

  @override
  Future<NewsApiResponse> call(GetNewsParams params) {
    return repository.getNews(
      page: params.page,
      perPage: params.perPage,
      excludeViewed: params.excludeViewed,
      excludeIds: params.excludeIds,
      cursor: params.cursor,
      feed: params.feed,
      categoryId: params.categoryId,
    );
  }

  // Legacy compat for old NoParams callers
  Future<List<NewsArticle>> callLegacy(NoParams params) {
    return repository.getNewsArticles();
  }
}
