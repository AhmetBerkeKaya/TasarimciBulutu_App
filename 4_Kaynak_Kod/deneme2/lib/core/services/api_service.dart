// lib/core/services/api_service.dart

// Bu sınıf, kimlik doğrulama dışındaki tüm genel API işlemlerini yönetir.
// Örneğin: Projeleri listeleme, proje detaylarını getirme, profil bilgilerini güncelleme vb.
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/models/application_model.dart';
import '../../data/models/project_model.dart';

class ApiService {
  final String _baseUrl = "http://10.0.2.2:8000";
  Future<bool> createProject({
    required String title,
    required String description,
    required String category,
    int? budgetMin,
    int? budgetMax,
    DateTime? deadline,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/projects/');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Token'ı header'a ekliyoruz
        },
        body: json.encode({
          'title': title,
          'description': description,
          'category': category,
          'budget_min': budgetMin,
          'budget_max': budgetMax,
          'deadline': deadline?.toIso8601String(),
        }),
      );

      return response.statusCode == 201; // Başarılı oluşturma
    } catch (e) {
      print('createProject Exception: $e');
      return false;
    }
  }
  // Örnek: Tüm projeleri getiren bir fonksiyon
  Future<List<Project>> getProjects() async {
    final url = Uri.parse('$_baseUrl/projects/');
    print('[ApiService] Projeler çekiliyor: $url');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> projectsJson = json.decode(utf8.decode(response.bodyBytes));

        final List<Project> projects = [];
        for (var projectJson in projectsJson) {
          try {
            // Her bir projeyi tek tek parse etmeyi dene
            projects.add(Project.fromJson(projectJson));
          } catch (e) {
            // Eğer bir projede hata olursa, hatayı ve sorunlu JSON'ı yazdır
            print('--- HATA: BU PROJE PARSE EDİLEMEDİ ---');
            print('Sorunlu JSON: $projectJson');
            print('Alınan Hata: $e');
            print('------------------------------------');
          }
        }

        print('[ApiService] ${projects.length} adet proje başarıyla çekildi ve parse edildi.');
        return projects;
      } else {
        print('[ApiService] Projeleri çekerken HATA: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[ApiService] Genel Proje Çekme EXCEPTION: $e');
      return [];
    }
  }
  Future<bool> applyToProject({
    required String projectId,
    String? coverLetter,
    double? proposedBudget,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/applications/');
    print('[ApiService] Projeye başvuru yapılıyor: $projectId');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'project_id': projectId,
          'cover_letter': coverLetter,
          'proposed_budget': proposedBudget,
        }),
      );

      print('[ApiService] Başvuru yanıtı: ${response.statusCode}');
      return response.statusCode == 201;
    } catch (e) {
      print('[ApiService] Başvuru EXCEPTION: $e');
      return false;
    }
  }
  Future<List<Application>> getMyApplications({required String token}) async {
    final url = Uri.parse('$_baseUrl/applications/me');
    print('[ApiService] Başvurularım çekiliyor: $url');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> applicationsJson = json.decode(utf8.decode(response.bodyBytes));
        final List<Application> applications = applicationsJson
            .map((json) => Application.fromJson(json))
            .toList();
        print('[ApiService] ${applications.length} adet başvuru başarıyla çekildi.');
        return applications;
      } else {
        print('[ApiService] Başvuruları çekerken HATA: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[ApiService] Başvuruları çekerken EXCEPTION: $e');
      return [];
    }
  }
  Future<List<Application>> getApplicationsForProject({
    required String projectId,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/projects/$projectId/applications');
    print('[ApiService] Proje başvuruları çekiliyor: $url');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> applicationsJson = json.decode(utf8.decode(response.bodyBytes));
        final List<Application> applications = applicationsJson
            .map((json) => Application.fromJson(json))
            .toList();
        print('[ApiService] Projeye ait ${applications.length} başvuru çekildi.');
        return applications;
      } else {
        print('[ApiService] Proje başvurularını çekerken HATA: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('[ApiService] Proje başvurularını çekerken EXCEPTION: $e');
      return [];
    }
  }
}