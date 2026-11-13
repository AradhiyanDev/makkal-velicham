import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for the view/viewed plan:
/// - [viewedIds]: posts marked viewed, persisted for `?exclude=1,2,3`
///   guest fallback (server dedups authed users via `?exclude_viewed=1`).
/// - [viewTimestamps]: postId -> first-seen epoch ms, for 24h dedup so we
///   don't re-POST view/viewed for the same post within a day.
/// - [pendingIds]: viewed POSTs that failed offline, retried opportunistically.
class ViewedStore {
  static const _viewedKey = 'viewed_post_ids';
  static const _timestampsKey = 'view_timestamps_json';
  static const _pendingKey = 'pending_viewed_ids';

  /// Keep the exclude list bounded so feed URLs stay short.
  static const maxExcludeIds = 200;

  /// Window in which a post counts as already seen (no re-POST, dimmed UI).
  static const dedupWindow = Duration(hours: 24);

  static final ViewedStore instance = ViewedStore._();

  ViewedStore._();

  final Set<int> _viewedIds = {};
  final Map<int, int> _timestamps = {};
  final Set<int> _pendingIds = {};
  bool _loaded = false;
  Future<void>? _loading;

  /// Safe to call from anywhere; loads once, no-ops when already loaded.
  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final raw in prefs.getStringList(_viewedKey) ?? const <String>[]) {
        final id = int.tryParse(raw);
        if (id != null) _viewedIds.add(id);
      }
      final stampsRaw = prefs.getString(_timestampsKey);
      if (stampsRaw != null && stampsRaw.isNotEmpty) {
        final decoded = jsonDecode(stampsRaw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final id = int.tryParse(entry.key);
          final ts = (entry.value as num?)?.toInt();
          if (id != null && ts != null) _timestamps[id] = ts;
        }
      }
      for (final raw in prefs.getStringList(_pendingKey) ?? const <String>[]) {
        final id = int.tryParse(raw);
        if (id != null) _pendingIds.add(id);
      }
      _pruneTimestamps();
    } catch (_) {
      // Corrupt prefs must never break the feed; start empty.
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = _viewedIds.toList()..sort();
      final trimmed = ids.length > maxExcludeIds
          ? ids.sublist(ids.length - maxExcludeIds)
          : ids;
      if (trimmed.length != ids.length) {
        _viewedIds
          ..clear()
          ..addAll(trimmed);
      }
      await prefs.setStringList(
        _viewedKey,
        [for (final id in _viewedIds) '$id'],
      );
      await prefs.setString(
        _timestampsKey,
        jsonEncode({for (final e in _timestamps.entries) '${e.key}': e.value}),
      );
      await prefs.setStringList(
        _pendingKey,
        [for (final id in _pendingIds) '$id'],
      );
    } catch (_) {
      // Persistence is best-effort; in-memory state still applies this session.
    }
  }

  void _pruneTimestamps() {
    final cutoff = DateTime.now().subtract(dedupWindow).millisecondsSinceEpoch;
    _timestamps.removeWhere((_, ts) => ts < cutoff);
  }

  /// True when [postId] was seen within the 24h dedup window.
  bool isFresh(int postId) {
    final ts = _timestamps[postId];
    if (ts == null) return false;
    return DateTime.now().millisecondsSinceEpoch - ts < dedupWindow.inMilliseconds;
  }

  /// Record a local view: adds to exclude set + stamps first-seen time.
  Future<void> markLocal(int postId) async {
    _viewedIds.add(postId);
    _timestamps.putIfAbsent(postId, () => DateTime.now().millisecondsSinceEpoch);
    await _persist();
  }

  /// Queue a failed viewed POST for retry; also recorded locally.
  Future<void> enqueuePending(int postId) async {
    await markLocal(postId);
    _pendingIds.add(postId);
    await _persist();
  }

  /// Take pending ids for a flush attempt; failures should re-enqueue.
  Set<int> takePending() {
    final pending = Set<int>.of(_pendingIds);
    _pendingIds.clear();
    unawaitedPersist();
    return pending;
  }

  void unawaitedPersist() {
    // ignore: discarded_futures
    _persist();
  }

  /// Comma-joined ids for `?exclude=1,2,3` (guest fallback). Null when empty.
  String? get excludeParam {
    if (_viewedIds.isEmpty) return null;
    final ids = _viewedIds.toList()..sort();
    final trimmed = ids.length > maxExcludeIds
        ? ids.sublist(ids.length - maxExcludeIds)
        : ids;
    return trimmed.join(',');
  }

  /// Clears all viewed history — call on logout so next user starts fresh.
  Future<void> clear() async {
    _viewedIds.clear();
    _timestamps.clear();
    _pendingIds.clear();
    _loaded = false;
    _loading = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_viewedKey);
      await prefs.remove(_timestampsKey);
      await prefs.remove(_pendingKey);
    } catch (_) {}
  }
}
