import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String author;
  final String text;
  final String timeAgo;
  final String? avatar;
  final String? parentId;
  final int replyCount;

  const Comment({
    required this.id,
    required this.author,
    required this.text,
    required this.timeAgo,
    this.avatar,
    this.parentId,
    this.replyCount = 0,
  });

  @override
  List<Object?> get props => [id, author, text, timeAgo, avatar, parentId, replyCount];
}
