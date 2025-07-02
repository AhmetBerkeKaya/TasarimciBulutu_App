// lib/data/models/test_result_model.dart
class TestResult {
  final String id;
  final String userId;
  final String testId;
  final int score;
  final DateTime completedAt;

  TestResult({
    required this.id,
    required this.userId,
    required this.testId,
    required this.score,
    required this.completedAt,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['id'],
      userId: json['user_id'],
      testId: json['test_id'],
      score: json['score'],
      completedAt: DateTime.parse(json['completed_at']),
    );
  }
}