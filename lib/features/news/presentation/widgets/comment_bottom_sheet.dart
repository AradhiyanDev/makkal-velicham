import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/news_remote_datasource.dart';
import '../../data/repositories/news_repository_impl.dart';
import '../../domain/entities/comment.dart';

class CommentBottomSheet extends StatefulWidget {
  final String articleId;
  final String articleTitle;
  final ValueChanged<Comment> onCommentPosted;

  const CommentBottomSheet({
    super.key,
    required this.articleId,
    required this.articleTitle,
    required this.onCommentPosted,
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final List<Comment> _comments = [];
  final Map<String, List<Comment>> _replies = {};
  final Set<String> _expanded = {};
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _loading = true;
  String? _error;
  bool _posting = false;
  String? _replyToId;
  String? _replyToAuthor;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    final postId = int.tryParse(widget.articleId);
    if (postId == null) {
      setState(() {
        _loading = false;
        _error = 'Invalid article';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await NewsRepositoryImpl(
        remoteDataSource: NewsRemoteDataSourceImpl(),
      ).getComments(postId, perPage: 20);
      if (!mounted) return;
      setState(() {
        _comments
          ..clear()
          ..addAll(res.comments);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _fetchReplies(String parentId) async {
    final postId = int.tryParse(widget.articleId);
    if (postId == null) return;
    try {
      final res = await NewsRepositoryImpl(
        remoteDataSource: NewsRemoteDataSourceImpl(),
      ).getComments(postId, perPage: 20, parentId: int.tryParse(parentId));
      if (!mounted) return;
      setState(() {
        _replies[parentId] = res.comments;
        _expanded.add(parentId);
      });
    } catch (_) {}
  }

  void _startReply(Comment c) {
    setState(() {
      _replyToId = c.id;
      _replyToAuthor = c.author;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyToId = null;
      _replyToAuthor = null;
    });
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _posting) return;
    if (text.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment must be 1-1000 characters')),
      );
      return;
    }
    final postId = int.tryParse(widget.articleId);
    if (postId == null) return;
    setState(() => _posting = true);
    try {
      final parentId = _replyToId != null ? int.tryParse(_replyToId!) : null;
      final created = await NewsRepositoryImpl(
        remoteDataSource: NewsRemoteDataSourceImpl(),
      ).postComment(postId, text, parentId: parentId);
      if (!mounted) return;
      setState(() {
        if (_replyToId != null) {
          // Add to replies list if expanded
          final list = _replies[_replyToId!] ?? [];
          list.insert(0, created);
          _replies[_replyToId!] = list;
          _expanded.add(_replyToId!);
        } else {
          _comments.insert(0, created);
        }
        _posting = false;
      });
      widget.onCommentPosted(created);
      _controller.clear();
      _cancelReply();
      _focusNode.requestFocus();
    } catch (e) {
      if (!mounted) return;
      setState(() => _posting = false);
      final msg = e.toString().replaceAll('Exception: ', '');
      final lower = msg.toLowerCase();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lower.contains('401') || lower.contains('unauthor') || lower.contains('login')
                ? 'Please login to comment'
                : msg,
          ),
        ),
      );
    }
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  Widget _avatar(Comment c, ThemeData theme, AppCardColors cardColors) {
    final isYou = c.author == 'You';
    if (c.avatar != null && c.avatar!.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: CachedNetworkImageProvider(c.avatar!),
        backgroundColor: cardColors.descriptionColor.withValues(alpha: 0.12),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: isYou
          ? theme.colorScheme.primary.withValues(alpha: 0.15)
          : cardColors.descriptionColor.withValues(alpha: 0.12),
      child: Text(
        c.author.isEmpty ? '?' : c.author[0].toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isYou ? theme.colorScheme.primary : cardColors.descriptionColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColors = theme.extension<AppCardColors>()!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cardColors.descriptionColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: cardColors.titleColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatCount(_comments.length),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: cardColors.descriptionColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: cardColors.descriptionColor.withValues(alpha: 0.10)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Text(
                    widget.articleTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cardColors.descriptionColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_error!,
                                        style: TextStyle(color: cardColors.descriptionColor),
                                        textAlign: TextAlign.center),
                                    const SizedBox(height: 12),
                                    FilledButton(
                                      onPressed: _fetch,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _comments.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.chat_bubble_outline_rounded,
                                          size: 40, color: cardColors.descriptionColor.withValues(alpha: 0.4)),
                                      const SizedBox(height: 10),
                                      Text('No comments yet',
                                          style: TextStyle(color: cardColors.descriptionColor)),
                                      const SizedBox(height: 4),
                                      Text('Be the first to comment',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: cardColors.descriptionColor.withValues(alpha: 0.7))),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                                  itemCount: _comments.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                                  itemBuilder: (context, i) {
                                    final c = _comments[i];
                                    final replies = _replies[c.id] ?? [];
                                    final isExpanded = _expanded.contains(c.id);
                                    return Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _avatar(c, theme, cardColors),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.surface,
                                                  borderRadius: BorderRadius.circular(14),
                                                  border: Border.all(
                                                      color: cardColors.descriptionColor.withValues(alpha: 0.08)),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(c.author,
                                                            style: TextStyle(
                                                                fontSize: 13,
                                                                fontWeight: FontWeight.w700,
                                                                color: cardColors.titleColor)),
                                                        const SizedBox(width: 6),
                                                        Text(c.timeAgo,
                                                            style: TextStyle(
                                                                fontSize: 11,
                                                                color: cardColors.descriptionColor
                                                                    .withValues(alpha: 0.7))),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(c.text,
                                                        style: TextStyle(
                                                            fontSize: 13,
                                                            height: 1.45,
                                                            color: cardColors.titleColor.withValues(alpha: 0.9))),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        InkWell(
                                                          onTap: () => _startReply(c),
                                                          child: Text('Reply',
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: theme.colorScheme.primary)),
                                                        ),
                                                        if (c.replyCount > 0) ...[
                                                          const SizedBox(width: 12),
                                                          InkWell(
                                                            onTap: () {
                                                              if (isExpanded) {
                                                                setState(() => _expanded.remove(c.id));
                                                              } else {
                                                                _fetchReplies(c.id);
                                                              }
                                                            },
                                                            child: Text(
                                                              isExpanded
                                                                  ? 'Hide replies'
                                                                  : 'View ${c.replyCount} replies',
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: cardColors.descriptionColor
                                                                      .withValues(alpha: 0.8)),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (isExpanded && replies.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 26, top: 8),
                                            child: Column(
                                              children: [
                                                for (final r in replies)
                                                  Padding(
                                                    padding: const EdgeInsets.only(bottom: 8),
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        _avatar(r, theme, cardColors),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(
                                                                horizontal: 12, vertical: 8),
                                                            decoration: BoxDecoration(
                                                              color: theme.colorScheme.surface
                                                                  .withValues(alpha: 0.7),
                                                              borderRadius: BorderRadius.circular(12),
                                                              border: Border.all(
                                                                  color: cardColors.descriptionColor
                                                                      .withValues(alpha: 0.06)),
                                                            ),
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(r.author,
                                                                    style: TextStyle(
                                                                        fontSize: 12,
                                                                        fontWeight: FontWeight.w700,
                                                                        color: cardColors.titleColor)),
                                                                const SizedBox(height: 2),
                                                                Text(r.text,
                                                                    style: TextStyle(
                                                                        fontSize: 12,
                                                                        color: cardColors.titleColor
                                                                            .withValues(alpha: 0.9))),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                ),
                if (_replyToAuthor != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    child: Row(
                      children: [
                        Text('Replying to @$_replyToAuthor',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
                        const Spacer(),
                        InkWell(
                          onTap: _cancelReply,
                          child: Icon(Icons.close_rounded, size: 16, color: cardColors.descriptionColor),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(top: BorderSide(color: cardColors.descriptionColor.withValues(alpha: 0.10))),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 1,
                            maxLines: 4,
                            style: TextStyle(color: cardColors.titleColor, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: _replyToAuthor != null ? 'Reply to @$_replyToAuthor...' : 'Add a comment...',
                              hintStyle: TextStyle(color: cardColors.descriptionColor.withValues(alpha: 0.6)),
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: cardColors.descriptionColor.withValues(alpha: 0.12)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: cardColors.descriptionColor.withValues(alpha: 0.12)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                              ),
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: theme.colorScheme.primary,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _posting ? null : _submit,
                            customBorder: const CircleBorder(),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: _posting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
