import '../../domain/entities/comment.dart';

/// Single comment from GET /api/v1/mobile/posts/{id}/comments or
/// POST /api/v1/mobile/posts/{id}/comments responses.
class CommentModel extends Comment {
  const CommentModel({
    required super.id,
    required super.author,
    required super.text,
    required super.timeAgo,
    super.avatar,
    super.parentId,
    super.replyCount,
  });

  /// List item shape: {id, comment, user:{name, avatar}, user_name,
  /// time, created_at, ...}. Post shape: {id, comment, created_at, ...}
  /// (author filled by caller from the logged-in user).
  ///
  /// Botble serializes a missing/deleted comment user as `[]` (an empty
  /// model withDefault()), not `null`, so accept either shape.
  factory CommentModel.fromJson(Map<String, dynamic> json, {String? fallbackAuthor}) {
    final rawUser = json['user'];
    final user = rawUser is Map ? Map<String, dynamic>.from(rawUser) : null;
    final fullName = [
      user?['first_name'] as String?,
      user?['last_name'] as String?,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' ');
    final author = fullName.isNotEmpty
        ? fullName
        : (user?['name'] as String?) ??
            (json['user_name'] as String?) ??
            fallbackAuthor ??
            'User';
    return CommentModel(
      id: '${json['id'] ?? ''}',
      author: author,
      text: json['comment'] as String? ?? '',
      timeAgo: (json['time'] as String?) ?? (json['created_at'] as String?) ?? '',
      avatar: user?['avatar'] as String?,
      parentId: json['parent_id'] != null ? '${json['parent_id']}' : null,
      replyCount: (json['reply_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Laravel paginator nested under `data`:
/// {error:false, data:{current_page, data:[...], last_page, per_page, total}}
/// Cursor response: {error:false, data:[...], additional:{meta:{...}}}.
class CommentListResponse {
  final List<CommentModel> comments;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const CommentListResponse({
    required this.comments,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory CommentListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];

    if (data is List) {
      final comments = _parseComments(data);
      return CommentListResponse(
        comments: comments,
        currentPage: 1,
        lastPage: 1,
        perPage: comments.length,
        total: _asInt(json['total']) ?? comments.length,
      );
    }

    final page = data is Map ? Map<String, dynamic>.from(data) : const <String, dynamic>{};
    final comments = _parseComments(page['data']);

    return CommentListResponse(
      comments: comments,
      currentPage: _asInt(page['current_page']) ?? 1,
      lastPage: _asInt(page['last_page']) ?? 1,
      perPage: _asInt(page['per_page']) ?? comments.length,
      total: _asInt(page['total']) ?? comments.length,
    );
  }

  static List<CommentModel> _parseComments(dynamic value) {
    if (value is! List) return const <CommentModel>[];
    return value
        .whereType<Map>()
        .map((item) => CommentModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}
