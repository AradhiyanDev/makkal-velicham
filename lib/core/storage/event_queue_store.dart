import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PendingEvent {
  final String id; // local uuid
  final int postId;
  final String eventType; // viewed,view,like,unlike,share,bookmark,impression,comment
  final DateTime occurredAt;
  final String idempotencyKey;
  final int retryCount;
  final DateTime createdAt;

  PendingEvent({
    required this.id,
    required this.postId,
    required this.eventType,
    required this.occurredAt,
    required this.idempotencyKey,
    this.retryCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'post_id': postId,
        'event_type': eventType,
        'occurred_at': occurredAt.toIso8601String(),
        'idempotency_key': idempotencyKey,
        'retry_count': retryCount,
        'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toApiJson() => {
        'post_id': postId,
        'event_type': eventType,
        'occurred_at': occurredAt.toIso8601String(),
        'idempotency_key': idempotencyKey,
      };

  factory PendingEvent.fromJson(Map<String, dynamic> j) => PendingEvent(
        id: j['id'] as String,
        postId: j['post_id'] as int,
        eventType: j['event_type'] as String,
        occurredAt: DateTime.parse(j['occurred_at'] as String),
        idempotencyKey: j['idempotency_key'] as String,
        retryCount: (j['retry_count'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  PendingEvent withRetry() => PendingEvent(
        id: id,
        postId: postId,
        eventType: eventType,
        occurredAt: occurredAt,
        idempotencyKey: idempotencyKey,
        retryCount: retryCount + 1,
        createdAt: createdAt,
      );
}

class EventQueueStore {
  static const _key = 'event_queue_v1';
  static const maxBatch = 50;
  static const maxRetries = 5;

  final Uuid _uuid = const Uuid();

  Future<List<PendingEvent>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => PendingEvent.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<PendingEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final e in events) e.toJson()]));
  }

  Future<void> enqueue({required int postId, required String eventType}) async {
    final events = await _load();
    events.add(PendingEvent(
      id: _uuid.v4(),
      postId: postId,
      eventType: eventType,
      occurredAt: DateTime.now(),
      idempotencyKey: _uuid.v4(),
      createdAt: DateTime.now(),
    ));
    // cap queue to avoid unbounded growth
    final trimmed = events.length > 200 ? events.sublist(events.length - 200) : events;
    await _save(trimmed);
  }

  Future<List<PendingEvent>> peekBatch() async {
    final events = await _load();
    return events.take(maxBatch).toList();
  }

  Future<void> removeBatch(List<String> ids) async {
    final events = await _load();
    events.removeWhere((e) => ids.contains(e.id));
    await _save(events);
  }

  Future<void> incrementRetries(List<String> ids) async {
    final events = await _load();
    for (var i = 0; i < events.length; i++) {
      if (ids.contains(events[i].id)) {
        events[i] = events[i].withRetry();
      }
    }
    events.removeWhere((e) => e.retryCount >= maxRetries);
    await _save(events);
  }

  Future<bool> hasPending() async => (await _load()).isNotEmpty;

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
