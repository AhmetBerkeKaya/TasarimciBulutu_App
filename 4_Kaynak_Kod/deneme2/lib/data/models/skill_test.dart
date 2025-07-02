// lib/data/models/skill_test_model.dart
class SkillTest {
  final String id;
  final String title;
  final String description;
  final String software;
  final DateTime createdAt;

  SkillTest({
    required this.id,
    required this.title,
    required this.description,
    required this.software,
    required this.createdAt,
  });

  factory SkillTest.fromJson(Map<String, dynamic> json) {
    return SkillTest(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      software: json['software'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}