import '../../domain/entities/news_article.dart';

class NewsArticleModel extends NewsArticle {
  const NewsArticleModel({
    required super.id,
    required super.title,
    required super.description,
    required super.imageUrl,
    super.likes,
    super.views,
    super.comments,
    super.isLiked,
  });

  factory NewsArticleModel.fromMap(Map<String, dynamic> map, String id) {
    return NewsArticleModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['image'] as String? ?? '',
      likes: map['likes'] as int? ?? 0,
      views: map['views'] as int? ?? 0,
      comments: map['comments'] as int? ?? 0,
    );
  }

  /// Live API: https://www.makkalvelicham.com/api/v1/mobile/news
  /// Maps: title, excerpt->description, image, views, likes/comments default 0
  factory NewsArticleModel.fromApiJson(Map<String, dynamic> json) {
    return NewsArticleModel(
      id: '${json['id'] ?? ''}',
      title: json['title'] as String? ?? '',
      description: json['excerpt'] as String? ?? '',
      imageUrl: json['image'] as String? ?? '',
      likes: (json['likes_count'] as int?) ?? (json['likes'] as int?) ?? 0,
      views: (json['views'] as int?) ?? 0,
      comments: (json['comments_count'] as int?) ?? (json['comments'] as int?) ?? 0,
      isLiked: (json['is_liked'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'image': imageUrl,
      'likes': likes,
      'views': views,
      'comments': comments,
    };
  }
}
