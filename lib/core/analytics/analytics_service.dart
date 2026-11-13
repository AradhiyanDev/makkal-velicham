import 'dart:async';
import '../storage/event_queue_store.dart';
import '../../features/news/data/datasources/news_remote_datasource.dart';
import '../../features/news/data/repositories/news_repository_impl.dart';

class AnalyticsService {
  final EventQueueStore _queue;
  final NewsRemoteDataSource _remote;
  Timer? _timer;
  bool _flushing = false;

  AnalyticsService({EventQueueStore? queue, NewsRemoteDataSource? remote})
      : _queue = queue ?? EventQueueStore(),
        _remote = remote ?? NewsRemoteDataSourceImpl();

  void startPeriodicFlush() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => flush());
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> trackImpression(int postId) async {
    await _queue.enqueue(postId: postId, eventType: 'impression');
  }

  Future<void> trackEngagedView(int postId) async {
    await _queue.enqueue(postId: postId, eventType: 'engaged_view');
  }

  Future<void> trackDeepRead(int postId) async {
    await _queue.enqueue(postId: postId, eventType: 'deep_read');
  }

  Future<void> trackSkip(int postId) async {
    await _queue.enqueue(postId: postId, eventType: 'skip');
  }

  Future<void> trackView(int postId) async {
    await _queue.enqueue(postId: postId, eventType: 'view');
  }

  Future<void> trackViewed(int postId) async {
    await _queue.enqueue(postId: postId, eventType: 'viewed');
  }

  Future<void> trackLike(int postId) async {
    await _queue.enqueue(postId: postId, eventType: 'like');
  }

  Future<void> trackUnlike(int postId) async {
    await _queue.enqueue(postId: postId, eventType: 'unlike');
  }

  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final batch = await _queue.peekBatch();
      if (batch.isEmpty) return;
      final payload = [for (final e in batch) e.toApiJson()];
      // Use repository batch endpoint (auth required, will fail for guests - keep locally)
      try {
        await NewsRepositoryImpl(remoteDataSource: _remote).syncEvents(payload);
        await _queue.removeBatch([for (final e in batch) e.id]);
      } catch (_) {
        // On auth error or network, keep queue for retry, increment retries
        await _queue.incrementRetries([for (final e in batch) e.id]);
      }
    } finally {
      _flushing = false;
    }
  }
}
