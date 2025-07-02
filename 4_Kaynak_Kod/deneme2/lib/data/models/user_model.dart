// lib/data/models/user_model.dart

import 'enums.dart';

class User {
  final String id;
  final String email;
  final UserRole role;
  final String name;
  final String? bio;
  final String? profilePicture;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.bio,
    this.profilePicture,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      role: UserRole.values.byName(json['role']),
      name: json['name'],
      bio: json['bio'],
      profilePicture: json['profile_picture'],
      isVerified: json['is_verified'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}