// lib/data/models/showcase_post_model.dart

// Bu dosyada, 'user_summary_model.dart' dosyasındaki UserSummary modelini
// kullandığımızı varsayıyoruz. Eğer o dosya yoksa, bu dosyanın en altına
// geçici olarak eklediğim UserSummary sınıfını kullanabilirsin.
import 'user_summary_model.dart';

class ShowcasePost {
  final String id;
  final String title;
  final String? description;
  final String originalFilename;
  final String? fileFormat;
  final String? apsUrn;
  final String apsTranslationStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final UserSummary owner;

  ShowcasePost({
    required this.id,
    required this.title,
    this.description,
    required this.originalFilename,
    this.fileFormat,
    this.apsUrn,
    required this.apsTranslationStatus,
    required this.createdAt,
    this.updatedAt,
    required this.owner,
  });

  // Bu factory constructor, API'den gelen JSON'ı ShowcasePost nesnesine çevirir.
  factory ShowcasePost.fromJson(Map<String, dynamic> json) {
    return ShowcasePost(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      // Backend'deki snake_case isimlendirmeyi Dart'taki camelCase'e çeviriyoruz.
      originalFilename: json['original_filename'],
      fileFormat: json['file_format'],
      apsUrn: json['aps_urn'],
      apsTranslationStatus: json['aps_translation_status'],
      // JSON'daki string formatındaki tarihi DateTime nesnesine çeviriyoruz.
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      // İç içe geçmiş JSON nesnesini UserSummary modeline çeviriyoruz.
      owner: UserSummary.fromJson(json['owner']),
    );
  }
}