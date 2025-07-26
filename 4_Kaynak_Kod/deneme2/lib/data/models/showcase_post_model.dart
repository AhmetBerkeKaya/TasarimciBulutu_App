// lib/data/models/showcase_post_model.dart

import 'comment_model.dart';
import 'user_summary_model.dart';

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
  final String? modelUrl;
  final String? modelFormat;
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
    this.modelUrl,
    this.modelFormat,
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
      modelUrl: json['model_url'],
      modelFormat: json['model_format'],
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