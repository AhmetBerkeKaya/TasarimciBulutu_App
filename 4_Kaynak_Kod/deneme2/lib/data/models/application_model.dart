// lib/data/models/application_model.dart

import 'enums.dart';

class Application {
  final String id;
  final String projectId;
  final String freelancerId;
  final String? coverLetter;
  final double? proposedBudget;
  final int? proposedDuration;
  final ApplicationStatus status;
  final DateTime createdAt;

  Application({
    required this.id,
    required this.projectId,
    required this.freelancerId,
    this.coverLetter,
    this.proposedBudget,
    this.proposedDuration,
    required this.status,
    required this.createdAt,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'],
      projectId: json['project_id'],
      freelancerId: json['freelancer_id'],
      coverLetter: json['cover_letter'],
      proposedBudget: (json['proposed_budget'] as num?)?.toDouble(),
      proposedDuration: json['proposed_duration'],
      status: ApplicationStatus.values.byName(json['status']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}