// lib/core/services/api_service.dart
import 'dart:convert';
import 'dart:io'; // File için
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../data/models/application_model.dart';
import '../../data/models/enums.dart';
import '../../data/models/message_model.dart';
import '../../data/models/portfolio_item_model.dart';
import '../../data/models/project_model.dart';
import '../../data/models/review_model.dart';
import '../../data/models/skill_model.dart';
import '../../data/models/skill_test.dart';
import '../../data/models/test_result_model.dart';
import '../../data/models/user_model.dart';
import 'package:http_parser/http_parser.dart';

import '../../data/models/work_experience_model.dart';

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
  Future<List<Project>> getProjects({
    String? searchQuery,
    String? category,
    int? minBudget, // <-- YENİ PARAMETRE
    int? maxBudget, // <-- YENİ PARAMETRE
    String? sortBy,    // <-- YENİ PARAMETRE
  }) async {
    // URL'ye filtre parametrelerini dinamik olarak ekle
    final queryParameters = {
      if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
      if (category != null && category.isNotEmpty) 'category': category,
      if (minBudget != null) 'min_budget': minBudget.toString(),
      if (maxBudget != null) 'max_budget': maxBudget.toString(),
      if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
    };

    final url = Uri.parse('$_baseUrl/projects/').replace(queryParameters: queryParameters);

    print('[ApiService] Projeler çekiliyor: $url');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> projectsJson = json.decode(utf8.decode(response.bodyBytes));
        return projectsJson.map((json) => Project.fromJson(json)).toList();
      } else {
        print('[ApiService] Projeleri çekerken HATA: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[ApiService] Genel Proje Çekme EXCEPTION: $e');
      return [];
    }
  }
  Future<Project?> getProjectById({required String projectId, required String token}) async {
    final url = Uri.parse('$_baseUrl/projects/$projectId');
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        return Project.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  Future<List<Project>> getMyProjects({required String token}) async {
    final url = Uri.parse('$_baseUrl/projects/me');
    print('[DEBUG] Firma projeleri çekiliyor: $url');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[DEBUG] Gelen yanıt kodu: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> projectsJson = json.decode(utf8.decode(response.bodyBytes));
        final List<Project> projects = [];

        // Projeleri tek tek, hata kontrolü yaparak parse et
        for (var projectData in projectsJson) {
          try {
            // Eğer gelen veri bir Map (JSON nesnesi) ise parse etmeyi dene
            if (projectData is Map<String, dynamic>) {
              projects.add(Project.fromJson(projectData));
            }
          } catch (e, s) { // Hata ve stack trace'i yakala
            // Bir proje parse edilemezse hatayı yazdır ama çökmek yerine devam et
            print('--- HATA: BU PROJE PARSE EDİLEMEDİ ---');
            print('Sorunlu JSON: $projectData');
            print('Alınan Hata: $e');
            print('Stack Trace: $s'); // Hatanın tam olarak nerede olduğunu gösterir
            print('------------------------------------');
          }
        }

        print('[DEBUG] Başarıyla parse edilen proje sayısı: ${projects.length}');
        return projects;
      } else {
        print('[ApiService] getMyProjects HATA: Sunucudan ${response.statusCode} kodu döndü.');
        return [];
      }
    } catch (e) {
      print('[ApiService] getMyProjects GENEL EXCEPTION: $e');
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
  Future<bool> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus newStatus,
    required String token,
  }) async {
    // DÜZELTME: /status endpoint'ini ekleyin
    final url = Uri.parse('$_baseUrl/applications/$applicationId/status');
    print('[ApiService] Başvuru durumu güncelleniyor: $applicationId -> ${newStatus.name}');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': newStatus.name, // "accepted" veya "rejected"
        }),
      );

      print('[ApiService] Durum güncelleme yanıtı: ${response.statusCode}');
      print('[ApiService] Durum güncelleme yanıtı body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('[ApiService] Durum güncelleme EXCEPTION: $e');
      return false;
    }
  }
  Future<User?> updateMyProfile({
    required Map<String, dynamic> data,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/users/me');
    print('[ApiService] Profil güncelleniyor...');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        print('[ApiService] Profil başarıyla güncellendi.');
        return User.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        print('[ApiService] Profil güncellerken HATA: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[ApiService] Profil güncelleme EXCEPTION: $e');
      return null;
    }
  }
  Future<List<Skill>> getAvailableSkills({required String token}) async {
    final url = Uri.parse('$_baseUrl/skills/');
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final List<dynamic> skillsJson = json.decode(utf8.decode(response.bodyBytes));
        return skillsJson.map((json) => Skill.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('getAvailableSkills EXCEPTION: $e');
      return [];
    }
  }

  Future<User?> addSkillToUser({required String skillId, required String token}) async {
    final url = Uri.parse('$_baseUrl/users/me/skills/$skillId');
    try {
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return User.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (e) {
      print('addSkillToUser EXCEPTION: $e');
      return null;
    }
  }
  Future<List<Message>> getConversations({required String token}) async {
    final url = Uri.parse('$_baseUrl/messages/conversations/me');
    print('[ApiService] Konuşmalar çekiliyor: $url');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> messagesJson = json.decode(utf8.decode(response.bodyBytes));
        return messagesJson.map((json) => Message.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('getConversations EXCEPTION: $e');
      return [];
    }
  }
  // İki kullanıcı arasındaki mesaj geçmişini getiren fonksiyon
  Future<List<Message>> getChatHistory({
    required String otherUserId,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/messages/$otherUserId');
    print('[ApiService] Mesaj geçmişi çekiliyor: $url');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> messagesJson = json.decode(utf8.decode(response.bodyBytes));
        return messagesJson.map((json) => Message.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('getChatHistory EXCEPTION: $e');
      return [];
    }
  }

// Yeni bir mesaj gönderen fonksiyon
  Future<Message?> sendMessage({
    required String receiverId,
    required String content,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/messages/');
    print('[ApiService] Mesaj gönderiliyor...');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'receiver_id': receiverId,
          'content': content,
        }),
      );
      if (response.statusCode == 201) {
        return Message.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (e) {
      print('sendMessage EXCEPTION: $e');
      return null;
    }
  }
  Future<void> markAsRead({
    required String otherUserId,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/messages/read/$otherUserId');
    print('[ApiService] Mesajlar okundu olarak işaretleniyor: $url');
    try {
      // Yanıt gövdesi beklemediğimiz için sadece isteği atıyoruz.
      await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      print('markAsRead EXCEPTION: $e');
    }
  }
  Future<PortfolioItem?> addPortfolioItem({
    required String title,
    String? description,
    required File imageFile,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/portfolio/items');
    print('[ApiService] Portfolyo öğesi yükleniyor: $url'); // Logda doğru URL'yi görelim
    try {
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Form alanlarını ekle
      request.fields['title'] = title;
      if (description != null) {
        request.fields['description'] = description;
      }

      // Dosyayı ekle
      request.files.add(await http.MultipartFile.fromPath(
        'file', // Backend'deki beklenen alan adı
        imageFile.path,
        contentType: MediaType('image', 'jpeg'), // Dosya tipini belirt
      ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        print('[ApiService] Portfolyo yükleme başarılı.');
        return PortfolioItem.fromJson(json.decode(responseBody));
      } else {
        print('[ApiService] Portfolyo yükleme HATA: ${response.statusCode} - $responseBody');
        return null;
      }
    } catch (e) {
      print('[ApiService] Portfolyo yükleme EXCEPTION: $e');
      return null;
    }
  }
  Future<User?> updateUserPicture({
    required File imageFile,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/users/me/picture');
    print('[ApiService] Profil fotoğrafı güncelleniyor...');
    try {
      var request = http.MultipartRequest('PUT', url); // Metodun PUT olduğuna dikkat et
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print('[ApiService] Profil fotoğrafı güncelleme başarılı.');
        return User.fromJson(json.decode(responseBody));
      } else {
        print('[ApiService] Profil fotoğrafı HATA: ${response.statusCode} - $responseBody');
        return null;
      }
    } catch (e) {
      print('[ApiService] Profil fotoğrafı EXCEPTION: $e');
      return null;
    }
  }
  Future<Uint8List?> getImageBytes(String imageUrl) async {
    // Tam URL'yi oluşturuyoruz
    final url = Uri.parse('$_baseUrl/$imageUrl');
    print('[ApiService] Resim byte\'ları çekiliyor: $url');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Başarılı olursa, yanıtın gövdesindeki byte'ları döndür
        return response.bodyBytes;
      } else {
        print('[ApiService] Resim byte HATA: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[ApiService] Resim byte EXCEPTION: $e');
      return null;
    }
  }
  Future<WorkExperience?> addWorkExperience({
    required Map<String, dynamic> data,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/work-experiences/me');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );
      if (response.statusCode == 201) {
        return WorkExperience.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (e) {
      print('addWorkExperience EXCEPTION: $e');
      return null;
    }
  }
  Future<User?> getUserProfileById({
    required String userId,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/users/$userId');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return User.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (e) {
      print('getUserProfileById EXCEPTION: $e');
      return null;
    }
  }
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/users/me/password');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );
      // 204 No Content başarılı demektir
      return response.statusCode == 204;
    } catch (e) {
      print('changePassword EXCEPTION: $e');
      return false;
    }
  }
  Future<User?> removeSkillFromUser({ // <-- Dönüş tipini User? yap
    required String skillId,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/users/me/skills/$skillId');
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      // Backend zaten güncel kullanıcıyı döndürüyor, bunu parse edelim
      if (response.statusCode == 200) {
        return User.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
      return null; // Başarısız olursa null dön
    } catch (e) {
      print('removeSkillFromUser EXCEPTION: $e');
      return null;
    }
  }
  Future<bool> deleteWorkExperience({
    required String experienceId,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/work-experiences/$experienceId');
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('deleteWorkExperience EXCEPTION: $e');
      return false;
    }
  }
  Future<bool> deletePortfolioItem({
    required String itemId,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/portfolio/items/$itemId');
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('deletePortfolioItem EXCEPTION: $e');
      return false;
    }
  }
  Future<bool> deleteMessage({
    required String messageId,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/messages/$messageId');
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 204;
    } catch (e) {
      print('deleteMessage EXCEPTION: $e');
      return false;
    }
  }
  Future<bool> deleteConversation({
    required String otherUserId,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/messages/conversation/$otherUserId');
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 204;
    } catch (e) {
      print('deleteConversation EXCEPTION: $e');
      return false;
    }
  }
  Future<Project?> completeProject({
    required String projectId,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/projects/$projectId/complete');
    print('[ApiService] Proje tamamlanıyor: $url');
    try {
      final response = await http.put(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return Project.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        print('[ApiService] Proje tamamlarken HATA: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[ApiService] Proje tamamlarken EXCEPTION: $e');
      return null;
    }
  }

  // lib/core/services/api_service.dart içine eklenecek metod

  Future<Review?> submitReview({
    required ReviewCreate reviewData,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reviews/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(reviewData.toJson()),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Review.fromJson(data);
      } else {
        print('Error submitting review: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception while submitting review: $e');
      return null;
    }
  }
  Future<List<SkillTest>> getSkillTests() async {
    final url = Uri.parse('$_baseUrl/skill-tests/');
    print('[ApiService] Yetkinlik testleri çekiliyor: $url');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> testsJson = json.decode(utf8.decode(response.bodyBytes));
        final tests = testsJson.map((json) => SkillTest.fromJson(json)).toList();
        print('[ApiService] ${tests.length} adet yetkinlik testi başarıyla çekildi.');
        return tests;
      } else {
        print('[ApiService] Yetkinlik testlerini çekerken HATA: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[ApiService] Yetkinlik testlerini çekerken EXCEPTION: $e');
      return [];
    }
  }

  /// Belirli bir testin tüm detaylarını (sorularıyla birlikte) getirir.
  Future<SkillTest?> getSkillTestDetails({required String testId}) async {
    final url = Uri.parse('$_baseUrl/skill-tests/$testId');
    print('[ApiService] Test detayı çekiliyor: $url');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return SkillTest.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (e) {
      print('[ApiService] Test detayı çekerken EXCEPTION: $e');
      return null;
    }
  }

  /// Giriş yapmış kullanıcı için bir testi başlatır ve test sonucu kaydını döndürür.
  Future<TestResult?> startTest({required String testId, required String token}) async {
    final url = Uri.parse('$_baseUrl/skill-tests/$testId/start');
    print('[ApiService] Test başlatılıyor: $url');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      // Backend router'da 201 (Created) dönecek şekilde ayarladığımızı varsayıyoruz.
      // Eğer 200 dönerse burayı ona göre güncelleyebilirsiniz.
      if (response.statusCode == 201) {
        return TestResult.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        print('[ApiService] Test başlatırken HATA: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[ApiService] Test başlatırken EXCEPTION: $e');
      return null;
    }
  }

  /// Kullanıcının cevaplarını sunucuya gönderir ve puanlanmış nihai sonucu alır.
  Future<TestResult?> submitTest({
    required String resultId,
    required Map<String, dynamic> submission,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/skill-tests/results/$resultId/submit');
    print('[ApiService] Test cevapları gönderiliyor: $url');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(submission),
      );

      if (response.statusCode == 200) {
        return TestResult.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        print('[ApiService] Test gönderirken HATA: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[ApiService] Test gönderirken EXCEPTION: $e');
      return null;
    }
  }
  // --- YENİ FONKSİYON: Freelancer işi teslim eder ---
  Future<Project?> deliverProject({required String projectId, required String token}) async {
    final url = Uri.parse('$_baseUrl/projects/$projectId/deliver');
    try {
      final response = await http.put(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return Project.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (e) {
      print('[ApiService] deliverProject EXCEPTION: $e');
      return null;
    }
  }

// --- YENİ FONKSİYON: Firma teslimatı onaylar ---
  Future<Project?> acceptDelivery({required String projectId, required String token}) async {
    final url = Uri.parse('$_baseUrl/projects/$projectId/accept');
    try {
      final response = await http.put(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return Project.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (e) {
      print('[ApiService] acceptDelivery EXCEPTION: $e');
      return null;
    }
  }
  Future<Project?> requestRevision({required String projectId, required String token}) async {
    final url = Uri.parse('$_baseUrl/projects/$projectId/request-revision');
    try {
      final response = await http.put(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return Project.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (e) {
      print('[ApiService] requestRevision EXCEPTION: $e');
      return null;
    }
  }
  Future<WorkExperience?> updateWorkExperience({
    required String experienceId,
    required Map<String, dynamic> data,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/work-experiences/$experienceId');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        return WorkExperience.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (e) {
      print('updateWorkExperience EXCEPTION: $e');
      return null;
    }
  }
  Future<PortfolioItem?> updatePortfolioItem({
    required String itemId,
    required String title,
    String? description,
    File? newFile, // Dosya opsiyonel
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/portfolio/items/$itemId');
    try {
      var request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Metin verilerini her zaman gönder
      request.fields['title'] = title;
      if (description != null) {
        request.fields['description'] = description;
      }

      // Sadece yeni bir dosya seçildiyse, isteğe ekle
      if (newFile != null) {
        request.files.add(await http.MultipartFile.fromPath('file', newFile.path));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return PortfolioItem.fromJson(json.decode(responseBody));
      } else {
        print('[ApiService] Portfolyo güncelleme HATA: ${response.statusCode} - $responseBody');
        return null;
      }
    } catch (e) {
      print('[ApiService] updatePortfolioItem EXCEPTION: $e');
      return null;
    }
  }
  Future<List<Review>> getReviewsForUser({required String userId}) async {
    final url = Uri.parse('$_baseUrl/users/$userId/reviews');
    print('[ApiService] Kullanıcı yorumları çekiliyor: $url');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> reviewsJson = json.decode(utf8.decode(response.bodyBytes));
        return reviewsJson.map((json) => Review.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('[ApiService] getReviewsForUser EXCEPTION: $e');
      return [];
    }
  }
}