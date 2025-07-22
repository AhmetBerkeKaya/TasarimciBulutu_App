// lib/data/models/comment_model.dart

import 'user_summary_model.dart';

class Comment {
  final String id;
  final String content;
  final DateTime createdAt;
  final UserSummary author;

  Comment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.author,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      author: UserSummary.fromJson(json['author']),
    );
  }
}
