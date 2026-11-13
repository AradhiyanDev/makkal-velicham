import 'package:equatable/equatable.dart';
import '../../domain/entities/news_article.dart';

abstract class NewsState extends Equatable {
  const NewsState();
  @override
  List<Object?> get props => [];
}

class NewsInitial extends NewsState {
  const NewsInitial();
}

class NewsLoading extends NewsState {
  const NewsLoading();
}

class NewsEmpty extends NewsState {
  const NewsEmpty();
}

class NewsRefreshing extends NewsState {
  final List<NewsArticle> articles;
  const NewsRefreshing(this.articles);
  @override
  List<Object?> get props => [articles];
}

class NewsLoaded extends NewsState {
  final List<NewsArticle> articles;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final String? nextCursor;

  const NewsLoaded(
    this.articles, {
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.nextCursor,
  });

  NewsLoaded copyWith({
    List<NewsArticle>? articles,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
    String? nextCursor,
  }) {
    return NewsLoaded(
      articles ?? this.articles,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      nextCursor: nextCursor ?? this.nextCursor,
    );
  }

  @override
  List<Object?> get props => [articles, currentPage, hasReachedMax, isLoadingMore, nextCursor];
}

class NewsError extends NewsState {
  final String message;
  final List<NewsArticle>? cachedArticles;
  const NewsError(this.message, {this.cachedArticles});

  @override
  List<Object?> get props => [message, cachedArticles];
}
