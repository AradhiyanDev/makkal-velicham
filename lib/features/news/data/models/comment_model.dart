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
  factory CommentModel.fromJson(Map<String, dynamic> json, {String? fallbackAuthor}) {
    final user = json['user'] as Map<String, dynamic>?;
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
/// Empty case: {error:false, data:[], total:0}.
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
      final comments = data
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return CommentListResponse(
        comments: comments,
        currentPage: 1,
        lastPage: 1,
        perPage: comments.length,
        total: (json['total'] as int?) ?? comments.length,
      );
    }
    final page = (data as Map<String, dynamic>?) ?? {};
    final items = (page['data'] as List? ?? [])
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return CommentListResponse(
      comments: items,
      currentPage: (page['current_page'] as int?) ?? 1,
      lastPage: (page['last_page'] as int?) ?? 1,
      perPage: (page['per_page'] as int?) ?? items.length,
      total: (page['total'] as int?) ?? items.length,
    );
  }
}
