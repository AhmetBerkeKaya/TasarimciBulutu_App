// lib/data/models/project_model.dart

import 'enums.dart';

class Project {
  final String id;
  final String usersId;
  final String title;
  final String? description;
  final String? category;
  final int? budgetMin;
  final int? budgetMax;
  final DateTime? deadline;
  final ProjectStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Project({
    required this.id,
    required this.usersId,
    required this.title,
    this.description,
    this.category,
    this.budgetMin,
    this.budgetMax,
    this.deadline,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final budgetMinInt = json['budget_min'] != null ? (json['budget_min'] as num).toInt() : null;
    final budgetMaxInt = json['budget_max'] != null ? (json['budget_max'] as num).toInt() : null;

    return Project(
      // --- GÜVENLİK KATMANI EKLENEN KISIMLAR ---
      // Bu alanların normalde null gelmemesi gerekir, ama her ihtimale karşı kontrol ekliyoruz.
      id: json['id'] as String? ?? 'Bilinmeyen ID',
      usersId: json['users_id'] as String? ?? 'Bilinmeyen Kullanıcı',
      title: json['title'] as String? ?? 'İsimsiz Proje',

      description: json['description'],
      category: json['category'],
      budgetMin: budgetMinInt,
      budgetMax: budgetMaxInt,

      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline']) : null,

      // status null ise, varsayılan olarak 'open' ata
      status: json['status'] != null
          ? ProjectStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => ProjectStatus.open)
          : ProjectStatus.open,

      // createdAt null ise, çok eski bir tarih ata (bu durum olmamalı ama önlem alıyoruz)
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime(1970),

      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}