import 'package:equatable/equatable.dart';

class NewsArticle extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final int likes;
  final int views;
  final int comments;
  final bool isLiked;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.likes = 0,
    this.views = 0,
    this.comments = 0,
    this.isLiked = false,
  });

  NewsArticle copyWith({
    int? likes,
    int? views,
    int? comments,
    bool? isLiked,
  }) {
    return NewsArticle(
      id: id,
      title: title,
      description: description,
      imageUrl: imageUrl,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      comments: comments ?? this.comments,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  @override
  List<Object?> get props => [id, title, description, imageUrl, likes, views, comments, isLiked];
}
