import 'package:flutter_test/flutter_test.dart';
import 'package:makkal_velicham/features/news/data/models/comment_model.dart';

void main() {
  group('CommentListResponse.fromJson', () {
    test('parses paginator where a deleted user is serialized as []', () {
      final json = <String, dynamic>{
        'error': false,
        'data': {
          'current_page': 1,
          'last_page': 1,
          'per_page': 20,
          'total': 1,
          'data': [
            {
              'id': 49,
              'comment': 'Yes',
              'user_id': 8,
              'parent_id': 0,
              'reply_count': 2,
              'time': '2 months ago',
              'created_at': '2026-09-05T16:40:14.000000Z',
              'user': [],
            },
          ],
        },
      };

      final response = CommentListResponse.fromJson(json);

      expect(response.comments, hasLength(1));
      expect(response.comments.first.id, '49');
      expect(response.comments.first.text, 'Yes');
      expect(response.comments.first.author, 'User');
      expect(response.comments.first.replyCount, 2);
      expect(response.total, 1);
    });

    test('parses a normal user object', () {
      final json = <String, dynamic>{
        'error': false,
        'data': {
          'current_page': 1,
          'last_page': 1,
          'per_page': 20,
          'total': 1,
          'data': [
            {
              'id': 51,
              'comment': 'Reply test',
              'time': '2 months ago',
              'user': {
                'first_name': 'ARUNKUMAR',
                'last_name': 'kumar',
                'avatar': 'https://example.com/a.jpg',
              },
            },
          ],
        },
      };

      final response = CommentListResponse.fromJson(json);

      expect(response.comments.single.author, 'ARUNKUMAR kumar');
      expect(response.comments.single.avatar, 'https://example.com/a.jpg');
    });

    test('parses cursor/list response', () {
      final json = <String, dynamic>{
        'error': false,
        'data': [
          {
            'id': 52,
            'comment': 'Cursor comment',
            'time': 'now',
            'user': null,
          },
        ],
        'additional': {
          'meta': {'next_cursor': 'abc', 'has_more': true},
        },
      };

      final response = CommentListResponse.fromJson(json);

      expect(response.comments.single.id, '52');
      expect(response.comments.single.author, 'User');
      expect(response.currentPage, 1);
      expect(response.lastPage, 1);
    });

    test('handles empty comment list', () {
      final response = CommentListResponse.fromJson(<String, dynamic>{
        'error': false,
        'data': <dynamic>[],
        'total': 0,
      });

      expect(response.comments, isEmpty);
      expect(response.total, 0);
    });
  });
}
