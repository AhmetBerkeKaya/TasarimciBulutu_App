// lib/data/models/showcase_post_model.dart

import 'comment_model.dart';
import 'user_summary_model.dart';

// Beğeni verisini temsil etmek için basit bir sınıf.
// Backend'den gelen JSON'a göre bunu daha da detaylandırabiliriz.
class PostLike {
  final String userId;
  final String postId;

  PostLike({required this.userId, required this.postId});

  factory PostLike.fromJson(Map<String, dynamic> json) {
    return PostLike(
      userId: json['user_id'],
      postId: json['post_id'],
    );
  }
}

class ShowcasePost {
  final String id;
  final String title;
  final String? description;
  final String? fileUrl;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserSummary owner;
  final List<PostLike> likes;
  final List<Comment> comments;

  ShowcasePost({
    required this.id,
    required this.title,
    this.description,
    this.fileUrl,
    this.thumbnailUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.owner,
    required this.likes,
    required this.comments,
  });

  factory ShowcasePost.fromJson(Map<String, dynamic> json) {
    return ShowcasePost(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      fileUrl: json['file_url'],
      thumbnailUrl: json['thumbnail_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      owner: UserSummary.fromJson(json['owner']),
      likes: (json['likes'] as List)
          .map((likeJson) => PostLike.fromJson(likeJson))
          .toList(),
      comments: (json['comments'] as List)
          .map((commentJson) => Comment.fromJson(commentJson))
          .toList(),
    );
  }
}
