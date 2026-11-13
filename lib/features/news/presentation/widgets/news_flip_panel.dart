import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:makkal_velicham/features/news/data/datasources/news_remote_datasource.dart';
import 'package:makkal_velicham/features/news/data/repositories/news_repository_impl.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/storage/viewed_store.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/widgets/login_prompt_bottom_sheet.dart';
import '../../domain/entities/news_article.dart';
import 'comment_bottom_sheet.dart';

class NewsFlipPanel extends StatefulWidget {
  final List<dynamic> items; // Can be NewsArticle or Ad
  final VoidCallback? onDone;
  final VoidCallback? onNearEnd;
  final bool hasMore;
  final bool isLoadingMore;
  final int adInterval; // Show ad every N items

  const NewsFlipPanel({
    super.key,
    required this.items,
    this.onDone,
    this.onNearEnd,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.adInterval = 5,
  });

  @override
  State<NewsFlipPanel> createState() => _NewsFlipPanelState();
}

class _NewsFlipPanelState extends State<NewsFlipPanel>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;
  int _currentIndex = 0;

  double _dragAngle = 0.0;
  bool _isDragging = false;
  bool _done = false;

  static const double _perspective = 0.002;

  final Set<String> _likedIds = {};
  // Server now returns likes_count in feed; keep all ids as known so count is always visible.
  final Set<String> _knownLikeCounts = {};
  late List<dynamic> _itemsCopy;
  final AnalyticsService _analytics = AnalyticsService();
  Timer? _engagedTimer;
  Timer? _deepReadTimer;
  Timer? _viewTimer;
  DateTime? _cardShownAt;
  final Set<String> _viewCountedIds = {};

  @override
  void initState() {
    super.initState();
    _itemsCopy = List.of(widget.items);
    _likedIds.clear();
    for (final a in _itemsCopy) {
      if (a is NewsArticle) {
        if ((a as NewsArticle).isLiked) _likedIds.add((a as NewsArticle).id);
      }
    }
    _knownLikeCounts.clear();
    for (final a in _itemsCopy) {
      if (a is NewsArticle) _knownLikeCounts.add((a as NewsArticle).id);
    }
    _animController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        )..addListener(() {
          setState(() {
            _dragAngle = _animController.value * math.pi;
          });
        });

    // Always-animating pulse for like button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.65,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    _pulseOpacity = Tween<double>(
      begin: 0.45,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    // Mark first card as seen immediately (no delay) — POST /viewed
    // And count /view after dwell so it fires on "current news user has see"
    // instead of waiting for next swipe.
    if (_itemsCopy.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // ignore: discarded_futures
        _markSeen(_itemsCopy[_currentIndex].id);
        _trackImpression(_itemsCopy[_currentIndex].id);
        _scheduleAnalyticsTimers(_itemsCopy[_currentIndex].id);
        _scheduleViewTimer(_itemsCopy[_currentIndex].id);
      });
    }
    _analytics.startPeriodicFlush();
  }

  @override
  void dispose() {
    _engagedTimer?.cancel();
    _deepReadTimer?.cancel();
    _viewTimer?.cancel();
    _analytics.stop();
    _analytics.flush();
    _animController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NewsFlipPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // First load was empty (NewsInitial -> NewsLoaded) — trigger viewed for index 0
    if (oldWidget.items.isEmpty &&
        widget.items.isNotEmpty &&
        _itemsCopy.isEmpty) {
      _itemsCopy = List.of(widget.items);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_itemsCopy.isNotEmpty && _currentIndex < _itemsCopy.length) {
          final firstItem = _itemsCopy[_currentIndex];
          // ignore: discarded_futures
          if (firstItem is NewsArticle) {
            _markSeen(firstItem.id);
            _trackImpression(firstItem.id);
            _scheduleAnalyticsTimers(firstItem.id);
            _scheduleViewTimer(firstItem.id);
          }
        }
      });
    }
    if (oldWidget.items != widget.items) {
      // Merge newly fetched pages, preserve local like/comment state.
      final existingIds = _itemsCopy
          .whereType<NewsArticle>()
          .map((a) => a.id)
          .toSet();
      for (final a in widget.items) {
        if (a is NewsArticle && !existingIds.contains(a.id)) {
          _itemsCopy.add(a);
        }
      }
      // Full refresh (e.g. pull-to-refresh shrinks list) → reset.
      if (widget.items.length < oldWidget.items.length) {
        _itemsCopy = List.of(widget.items);
        _currentIndex = _currentIndex.clamp(0, _itemsCopy.length - 1);
        _likedIds.clear();
        for (final a in _itemsCopy) {
          if (a is NewsArticle) {
            if ((a as NewsArticle).isLiked)
              _likedIds.add((a as NewsArticle).id);
          }
        }
        _knownLikeCounts.clear();
        for (final a in _itemsCopy) {
          if (a is NewsArticle) _knownLikeCounts.add((a as NewsArticle).id);
        }
      } else {
        // Seed server liked state for newly appended pages.
        for (final a in widget.items) {
          if (a is NewsArticle) {
            if (a.isLiked) _likedIds.add(a.id);
            _knownLikeCounts.add(a.id);
          }
        }
        if (widget.hasMore &&
            !widget.isLoadingMore &&
            _currentIndex >= widget.items.length - 3) {
          widget.onNearEnd?.call();
        }
      }
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details, double screenH) {
    if (_done ||
        _animController.isAnimating ||
        _currentIndex >= widget.items.length - 1) {
      return;
    }
    setState(() {
      _isDragging = true;
      _dragAngle -= (details.primaryDelta! / (screenH * 0.4)) * math.pi;
      _dragAngle = _dragAngle.clamp(0.0, math.pi);
    });
  }

  NewsRepositoryImpl _repo() =>
      NewsRepositoryImpl(remoteDataSource: NewsRemoteDataSourceImpl());

  /// Swipe-away: POST /view (MobileNewsController:367 incrementView — counts + status='view')
  /// Auth: counts + server exclude; Guest: local ViewedStore only + still counts via IP
  Future<void> _markViewOnSwipe(String articleId) async {
    final postId = int.tryParse(articleId);
    if (postId == null) {
      dev.log('view skip: parse fail $articleId', name: 'FLIP');
      return;
    }
    final store = ViewedStore.instance;
    await store.ensureLoaded();
    dev.log(
      'view attempt old=$postId hasToken=${await TokenStorage().hasToken()}',
      name: 'FLIP',
    );
    try {
      await _repo().markView(postId);
      dev.log('view done old=$postId', name: 'FLIP');
      await store.markLocal(postId);
    } catch (e) {
      dev.log('view fail old=$postId err=$e', name: 'FLIP');
      await store.enqueuePending(postId);
    }
  }

  /// Immediately marks news as seen — POST /viewed (MobileNewsController:409 markViewed, auth:sanctum, no count)
  /// Called when card becomes visible on swipe-up. Server dedups via user_post_views unique.
  Future<void> _markSeen(String articleId) async {
    final postId = int.tryParse(articleId);
    if (postId == null) {
      dev.log('viewed skip: parse fail $articleId', name: 'FLIP');
      return;
    }
    final store = ViewedStore.instance;
    await store.ensureLoaded();
    final hasToken = await TokenStorage().hasToken();
    final fresh = store.isFresh(postId);
    dev.log(
      'viewed attempt new=$postId hasToken=$hasToken isFresh=$fresh',
      name: 'FLIP',
    );
    // Keep local for ?exclude fallback even if fresh — but don't skip API for authed (server is source of truth)
    await store.markLocal(postId);
    if (!hasToken) {
      dev.log('viewed skip guest new=$postId (local only)', name: 'FLIP');
      return; // /viewed is auth:sanctum only — local already marked for guest ?exclude
    }
    try {
      await _repo().markViewed(postId);
      dev.log('viewed done new=$postId', name: 'FLIP');
    } catch (e) {
      dev.log('viewed fail new=$postId err=$e', name: 'FLIP');
      await store.enqueuePending(postId);
    }
  }

  void _trackImpression(String articleId) {
    final postId = int.tryParse(articleId);
    if (postId == null) return;
    // Fire-and-forget analytics, batched every 30s via EventQueueStore
    // ignore: discarded_futures
    _analytics.trackImpression(postId);
  }

  void _scheduleAnalyticsTimers(String articleId) {
    final postId = int.tryParse(articleId);
    if (postId == null) return;
    _engagedTimer?.cancel();
    _deepReadTimer?.cancel();
    _cardShownAt = DateTime.now();
    _engagedTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      // ignore: discarded_futures
      _analytics.trackEngagedView(postId);
    });
    _deepReadTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      // ignore: discarded_futures
      _analytics.trackDeepRead(postId);
    });
  }

  void _scheduleViewTimer(String articleId) {
    _viewTimer?.cancel();
    if (_viewCountedIds.contains(articleId)) return;
    // Fire /view after short dwell so current card is counted without waiting for swipe.
    _viewTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_currentIndex < _itemsCopy.length &&
          _itemsCopy[_currentIndex].id == articleId) {
        _viewCountedIds.add(articleId);
        // ignore: discarded_futures
        _markViewOnSwipe(articleId);
      }
    });
  }

  void _cancelAnalyticsTimers() {
    _engagedTimer?.cancel();
    _deepReadTimer?.cancel();
  }

  void _cancelViewTimer() {
    _viewTimer?.cancel();
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0.0;
    final shouldComplete = _dragAngle > (math.pi / 2) || velocity < -200;

    if (shouldComplete) {
      // Analytics: quick swipe = skip, else already tracked via dwell timers
      final prevId = _currentIndex >= 0 && _currentIndex < _itemsCopy.length
          ? _itemsCopy[_currentIndex].id
          : null;
      if (prevId != null && _cardShownAt != null) {
        final dwell = DateTime.now().difference(_cardShownAt!);
        if (dwell.inSeconds < 3) {
          final pid = int.tryParse(prevId);
          if (pid != null) {
            // ignore: discarded_futures
            _analytics.trackSkip(pid);
          }
        }
      }
      _cancelAnalyticsTimers();
      // Count /view for current card BEFORE leaving it.
      // If dwell timer hasn't fired yet (quick swipe), fire view now so it
      // is associated with the current post, not deferred until after next
      // card appears. If already counted via _scheduleViewTimer, skip duplicate.
      if (_currentIndex >= 0 && _currentIndex < _itemsCopy.length) {
        final curId = _itemsCopy[_currentIndex].id;
        if (!_viewCountedIds.contains(curId)) {
          _viewTimer?.cancel();
          _viewCountedIds.add(curId);
          // ignore: discarded_futures
          _markViewOnSwipe(curId);
        } else {
          _cancelViewTimer();
        }
      }
      _animController.forward(from: _dragAngle / math.pi).then((_) {
        if (!mounted) return;
        setState(() {
          _currentIndex++;
          _dragAngle = 0.0;
          _animController.value = 0.0;
        });
        // Mark newly visible card as seen immediately — POST /viewed (no delay)
        // and schedule /view after dwell for the new current card.
        if (_currentIndex >= 0 && _currentIndex < _itemsCopy.length) {
          // ignore: discarded_futures
          _markSeen(_itemsCopy[_currentIndex].id);
          _trackImpression(_itemsCopy[_currentIndex].id);
          _scheduleAnalyticsTimers(_itemsCopy[_currentIndex].id);
          _scheduleViewTimer(_itemsCopy[_currentIndex].id);
        }
        // Prefetch next page when 2 cards left
        if (widget.hasMore &&
            !widget.isLoadingMore &&
            _currentIndex >= widget.items.length - 2) {
          widget.onNearEnd?.call();
        }
        if (_currentIndex >= widget.items.length - 1) {
          if (widget.hasMore && !widget.isLoadingMore) {
            widget.onNearEnd?.call();
          } else {
            _done = true;
            widget.onDone?.call();
          }
        }
      });
    } else {
      _animController.reverse(from: _dragAngle / math.pi).then((_) {
        if (!mounted) return;
        setState(() {
          _dragAngle = 0.0;
          _animController.value = 0.0;
        });
      });
    }
  }

  Widget _buildTopImagePanel(BuildContext context, NewsArticle article) {
    final theme = Theme.of(context);
    final cardColors = theme.extension<AppCardColors>()!;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: cardColors.cardBackground,
      child: CachedNetworkImage(
        imageUrl: article.imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, _) => Center(
          child: CircularProgressIndicator(
            color: isDark
                ? Colors.white24
                : theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        errorWidget: (_, _, _) => Container(
          color: cardColors.errorIconBg,
          child: Icon(
            Icons.image_not_supported,
            color: isDark ? Colors.white24 : Colors.black26,
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomTextPanel(BuildContext context, NewsArticle article) {
    final cardColors = Theme.of(context).extension<AppCardColors>()!;
    final isLiked = _likedIds.contains(article.id);
    final likes = _itemsCopy
        .firstWhere((a) => a.id == article.id, orElse: () => article)
        .likes;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      color: cardColors.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // ── Engagement row ABOVE title: views | comments | like at end ──
          Row(
            children: [
              // Views
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 22,
                    color: cardColors.descriptionColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatCount(
                      _itemsCopy
                          .firstWhere(
                            (a) => a.id == article.id,
                            orElse: () => article,
                          )
                          .views,
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cardColors.descriptionColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Comments (tappable -> bottom sheet)
              InkWell(
                onTap: () => _showCommentSheet(context, article),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 22,
                        color: cardColors.descriptionColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatCount(
                          _itemsCopy
                              .firstWhere(
                                (a) => a.id == article.id,
                                orElse: () => article,
                              )
                              .comments,
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cardColors.descriptionColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Like at end — rounded circular icon with always-animating ripple + count
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stack with always-pulsing halo behind the button
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Expanding halo (always animating) — larger + thick border
                          ScaleTransition(
                            scale: _pulseScale,
                            child: FadeTransition(
                              opacity: _pulseOpacity,
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                  border: Border.all(
                                    width: 2.8,
                                    color:
                                        (isLiked
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : cardColors.descriptionColor)
                                            .withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          child!,
                        ],
                      );
                    },
                    child: Material(
                      color: isLiked
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.14)
                          : cardColors.descriptionColor.withValues(alpha: 0.08),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _toggleLike(context, article),
                        customBorder: const CircleBorder(),
                        splashColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.20),
                        highlightColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.10),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 22,
                            color: isLiked
                                ? Theme.of(context).colorScheme.primary
                                : cardColors.descriptionColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatCount(likes),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isLiked
                          ? Theme.of(context).colorScheme.primary
                          : cardColors.descriptionColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Divider(
            height: 1,
            color: cardColors.descriptionColor.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 6),
          Text(
            article.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: cardColors.titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            article.description,
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: cardColors.descriptionColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final nextIndex = math.min(_currentIndex + 1, widget.items.length - 1);

        final currentArticle = widget.items[_currentIndex];
        final nextArticle = widget.items[nextIndex];

        final currentTop = _buildTopImagePanel(context, currentArticle);
        final currentBottom = _buildBottomTextPanel(context, currentArticle);

        final nextTop = _buildTopImagePanel(context, nextArticle);
        final nextBottom = _buildBottomTextPanel(context, nextArticle);

        final isFirstHalf = _dragAngle <= math.pi / 2;

        return GestureDetector(
          onVerticalDragUpdate: (d) =>
              _onVerticalDragUpdate(d, constraints.maxHeight),
          onVerticalDragEnd: _onVerticalDragEnd,
          behavior: HitTestBehavior.opaque,
          child: SizedBox.expand(
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      nextTop,
                      if (!isFirstHalf)
                        Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, _perspective)
                            ..rotateX(math.pi - _dragAngle),
                          child: nextTop,
                        )
                      else
                        currentTop,
                    ],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      currentBottom,
                      if (isFirstHalf)
                        Transform(
                          alignment: Alignment.topCenter,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, _perspective)
                            ..rotateX(-_dragAngle),
                          child: currentBottom,
                        )
                      else
                        nextBottom,
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatCount(int n) {
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  Future<void> _toggleLike(BuildContext context, NewsArticle article) async {
    final hasToken = await TokenStorage().hasToken();
    if (!hasToken) {
      if (context.mounted) {
        LoginPromptBottomSheet.show(context);
      }
      return;
    }

    final id = article.id;
    final postId = int.tryParse(id);
    if (postId == null) return;
    final wasLiked = _likedIds.contains(id);
    final wasKnown = _knownLikeCounts.contains(id);
    final prevIdx = _itemsCopy.indexWhere((a) => a.id == id);
    final prevCount = prevIdx != -1 ? _itemsCopy[prevIdx].likes : 0;

    // Optimistic update for instant feedback: icon flips and the count
    // moves ±1 immediately; the server response reconciles it below.
    setState(() {
      if (wasLiked) {
        _likedIds.remove(id);
      } else {
        _likedIds.add(id);
      }
      if (wasKnown && prevIdx != -1) {
        final current = _itemsCopy[prevIdx];
        final next = wasLiked
            ? (current.likes > 0 ? current.likes - 1 : 0)
            : current.likes + 1;
        _itemsCopy[prevIdx] = current.copyWith(likes: next);
      } else if (!wasLiked && prevIdx != -1) {
        // No server count yet: show the +1 immediately, truth arrives below.
        _knownLikeCounts.add(id);
        _itemsCopy[prevIdx] = _itemsCopy[prevIdx].copyWith(
          likes: prevCount + 1,
        );
      }
    });
    // Analytics (batched, idempotent)
    // ignore: discarded_futures
    wasLiked ? _analytics.trackUnlike(postId) : _analytics.trackLike(postId);

    try {
      // POST /api/v1/mobile/posts/{id}/like → {data:{is_liked, likes_count}}
      final res = await NewsRepositoryImpl(
        remoteDataSource: NewsRemoteDataSourceImpl(),
      ).likePost(postId);
      final data = res['data'] is Map
          ? Map<String, dynamic>.from(res['data'] as Map)
          : res;
      final serverLiked = data['is_liked'] as bool?;
      final serverCount = data['likes_count'] as int?;
      if (!context.mounted) return;
      setState(() {
        if (serverLiked != null) {
          if (serverLiked) {
            _likedIds.add(id);
          } else {
            _likedIds.remove(id);
          }
        }
        if (serverCount != null) {
          _knownLikeCounts.add(id);
          final idx = _itemsCopy.indexWhere((a) => a.id == id);
          if (idx != -1) {
            final current = _itemsCopy[idx];
            _itemsCopy[idx] = current.copyWith(
              likes: serverCount,
              isLiked: serverLiked ?? current.isLiked,
            );
          }
        }
      });
    } catch (e) {
      if (!context.mounted) return;
      // Revert optimistic update so UI stays truthful.
      setState(() {
        if (wasLiked) {
          _likedIds.add(id);
        } else {
          _likedIds.remove(id);
        }
        if (!wasKnown) {
          _knownLikeCounts.remove(id);
        }
        final idx = _itemsCopy.indexWhere((a) => a.id == id);
        if (idx != -1) {
          _itemsCopy[idx] = _itemsCopy[idx].copyWith(likes: prevCount);
        }
      });
      final msg = e.toString().toLowerCase();
      final needsLogin =
          msg.contains('401') ||
          msg.contains('unauthor') ||
          msg.contains('login');
      if (needsLogin) {
        LoginPromptBottomSheet.show(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update like. Try again.')),
        );
      }
    }
  }

  Future<void> _showCommentSheet(
    BuildContext context,
    NewsArticle article,
  ) async {
    final hasToken = await TokenStorage().hasToken();
    if (!hasToken) {
      if (context.mounted) {
        LoginPromptBottomSheet.show(context);
      }
      return;
    }

    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentBottomSheet(
        articleId: article.id,
        articleTitle: article.title,
        onCommentPosted: (_) {
          // Server is source of truth for the list; just bump the count badge.
          setState(() {
            final idx = _itemsCopy.indexWhere((a) => a.id == article.id);
            if (idx != -1) {
              _itemsCopy[idx] = _itemsCopy[idx].copyWith(
                comments: _itemsCopy[idx].comments + 1,
              );
            }
          });
        },
      ),
    );
  }
}
