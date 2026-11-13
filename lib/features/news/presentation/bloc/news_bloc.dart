import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/viewed_store.dart';
import '../../domain/repositories/news_repository.dart';
import '../../domain/usecases/get_news_articles.dart';
import 'news_event.dart';
import 'news_state.dart';

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  final GetNewsArticles getNewsArticles;
  final NewsRepository newsRepository;
  final ViewedStore viewedStore;
  final TokenStorage tokenStorage;

  String _currentFeed = 'latest';
  String? _currentCategoryName;
  int? _currentCategoryId;

  NewsBloc({
    required this.getNewsArticles,
    required this.newsRepository,
    ViewedStore? viewedStore,
    TokenStorage? tokenStorage,
  })  : viewedStore = viewedStore ?? ViewedStore.instance,
        tokenStorage = tokenStorage ?? TokenStorage(),
        super(const NewsInitial()) {
    on<FetchNews>(_onFetchNews);
    on<FetchMoreNews>(_onFetchMore);
    on<SwitchFeed>(_onSwitchFeed);
    on<FilterCategory>(_onFilterCategory);
  }

  /// Best-effort flush of viewed POSTs queued while offline.
  Future<void> _flushPendingViewed() async {
    final pending = viewedStore.takePending();
    for (final postId in pending) {
      try {
        await newsRepository.markViewed(postId);
      } catch (_) {
        await viewedStore.enqueuePending(postId);
      }
    }
  }

  Future<GetNewsParams> _paramsFor({required int page, required int perPage, String? cursor, String? feed, int? categoryId, String? categoryName}) async {
    await viewedStore.ensureLoaded();
    // Flush generic event queue in background; feed fetch must not wait.
    // ignore: discarded_futures
    _flushPendingViewed();
    final loggedIn = await tokenStorage.hasToken();
    return GetNewsParams(
      page: page,
      perPage: perPage,
      excludeViewed: loggedIn,
      // Authed: server filters via user_post_views WHERE NOT IN (?exclude_viewed=1) -> MobileNewsController.php:130
      // Guest: no server history, send local ?exclude=1,2,3 fallback -> MobileNewsController.php:122 + ViewedStore.dart:134
      excludeIds: loggedIn ? null : viewedStore.excludeParam,
      cursor: cursor,
      feed: feed ?? _currentFeed,
      categoryId: categoryId ?? _currentCategoryId,
    );
  }

  Future<void> _onSwitchFeed(SwitchFeed event, Emitter<NewsState> emit) async {
    _currentFeed = event.feed;
    add(FetchNews(page: 1, perPage: 10, feed: _currentFeed, categoryId: _currentCategoryId, categoryName: _currentCategoryName));
  }

  Future<void> _onFilterCategory(FilterCategory event, Emitter<NewsState> emit) async {
    _currentCategoryName = event.categoryName;
    _currentCategoryId = event.categoryId;
    // If categoryName is "All" or null, clear filter
    if (_currentCategoryName == null || _currentCategoryName == 'All') {
      _currentCategoryName = null;
      _currentCategoryId = null;
    }
    add(FetchNews(page: 1, perPage: 10, feed: _currentFeed, categoryId: _currentCategoryId, categoryName: _currentCategoryName));
  }

  Future<void> _onFetchNews(FetchNews event, Emitter<NewsState> emit) async {
    if (event.feed != null) _currentFeed = event.feed!;
    if (event.categoryName != null || event.categoryId != null) {
      _currentCategoryName = event.categoryName;
      _currentCategoryId = event.categoryId;
      if (_currentCategoryName == 'All') {
        _currentCategoryName = null;
        _currentCategoryId = null;
      }
    }
    emit(const NewsLoading());
    try {
      final res = await getNewsArticles(
        await _paramsFor(page: event.page, perPage: event.perPage, feed: _currentFeed, categoryId: _currentCategoryId, categoryName: _currentCategoryName),
      );
      if (res.data.isEmpty) {
        emit(const NewsEmpty());
        return;
      }
      emit(NewsLoaded(
        res.data,
        currentPage: res.currentPage,
        hasReachedMax: !res.hasNextPage,
        nextCursor: res.nextCursor,
      ));
    } catch (e) {
      emit(NewsError(e.toString()));
    }
  }

  Future<void> _onFetchMore(FetchMoreNews event, Emitter<NewsState> emit) async {
    final current = state;
    if (current is! NewsLoaded || current.hasReachedMax || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    try {
      // Prefer cursor if available (Phase1: backward compat with page)
      final nextCursor = current.nextCursor;
      final params = nextCursor != null
          ? await _paramsFor(page: current.currentPage + 1, perPage: 10, cursor: nextCursor)
          : await _paramsFor(page: current.currentPage + 1, perPage: 10);
      final res = await getNewsArticles(params);
      // Dedup by post.id
      final existingIds = current.articles.map((a) => a.id).toSet();
      final newItems = [for (final a in res.data) if (!existingIds.contains(a.id)) a];
      final merged = List.of(current.articles)..addAll(newItems);
      emit(NewsLoaded(
        merged,
        currentPage: res.currentPage,
        hasReachedMax: !res.hasNextPage,
        isLoadingMore: false,
        nextCursor: res.nextCursor ?? current.nextCursor,
      ));
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
      // keep error as snackbar in UI; don't override loaded state
    }
  }
}
