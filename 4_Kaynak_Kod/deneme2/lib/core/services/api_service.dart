// lib/core/services/api_service.dart (YEPYENİ HALİ)

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import '../../data/models/application_model.dart';
import '../../data/models/comment_model.dart';
import '../../data/models/enums.dart';
import '../../data/models/message_model.dart';
import '../../data/models/portfolio_item_model.dart';
import '../../data/models/project_model.dart';
import '../../data/models/review_model.dart';
import '../../data/models/showcase_post_model.dart';
import '../../data/models/skill_model.dart';
import '../../data/models/skill_test.dart';
import '../../data/models/test_result_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/work_experience_model.dart';
import 'dio_client.dart';
import 'package:http_parser/http_parser.dart'; // YENİ IMPORT: MediaType için


class PresignedUrlResponse {
  final String url;
  final Map<String, dynamic> fields;
  final String finalFileUrl;

  PresignedUrlResponse({required this.url, required this.fields, required this.finalFileUrl});

  factory PresignedUrlResponse.fromJson(Map<String, dynamic> json) {
    return PresignedUrlResponse(
      url: json['url'],
      fields: Map<String, dynamic>.from(json['fields']),
      finalFileUrl: json['final_file_url'],
    );
  }
}


class ApiService {
  final Dio _dio = DioClient.instance.dio;

  // Fonksiyonlardan 'token' parametrelerinin kalktığına dikkat et!
  // Interceptor'lar sayesinde artık onlara ihtiyacımız yok.

  Future<List<ShowcasePost>> getShowcasePosts({int page = 0, int limit = 20}) async {
    try {
      final response = await _dio.get(
        '/showcase/posts',
        queryParameters: {'skip': page * limit, 'limit': limit},
      );
      return (response.data as List)
          .map((json) => ShowcasePost.fromJson(json))
          .toList();
    } on DioException catch (e) {
      print('getShowcasePosts DioException: ${e.response?.data}');
      return [];
    }
  }

  Future<PresignedUrlResponse?> getPresignedUploadUrl(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final contentType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final response = await _dio.post(
        '/showcase/upload-url',
        data: {'filename': fileName, 'content_type': contentType},
      );
      return PresignedUrlResponse.fromJson(response.data);
    } on DioException catch (e) {
      print('getPresignedUploadUrl DioException: ${e.response?.data}');
      return null;
    }
  }

  Future<bool> uploadFileToS3({
    required PresignedUrlResponse presignedData,
    required File file,
  }) async {
    try {
      final contentType = lookupMimeType(file.path) ?? 'application/octet-stream';

      // FormData'yı S3'ün beklediği SÖZLEŞMEYE %100 UYGUN şekilde oluşturuyoruz.
      final formData = FormData.fromMap({
        ...presignedData.fields,
        // S3'ün hata mesajında istediği eksik alan tam olarak buydu:
        'Content-Type': contentType,
        'file': await MultipartFile.fromFile(file.path),
      });

      final s3Dio = Dio();
      final response = await s3Dio.post(presignedData.url, data: formData);

      // Başarılı yükleme durumunda S3 204 No Content döner.
      return response.statusCode == 204;
    } catch (e) {
      print('❌ S3 yükleme hatası: $e');
      if (e is DioException) {
        print('🔴 DioException Detayları:');
        print('  - Hata Tipi: ${e.type}');
        print('  - İstek Adresi: ${e.requestOptions.uri}');
        print('  - Sunucu Cevabı (Response Body): ${e.response?.data}');
      }
      return false;
    }
  }


  Future<ShowcasePost?> createShowcasePost({ required String title, String? description, String? fileUrl }) async {
    try {
      final response = await _dio.post('/showcase/posts', data: { 'title': title, 'description': description, 'file_url': fileUrl, });
      return ShowcasePost.fromJson(response.data);
    } on DioException catch (e) {
      print('createShowcasePost DioException: ${e.response?.data}');
      return null;
    }
  }

  Future<bool> deleteShowcasePost({required String postId}) async {
    try {
      final response = await _dio.delete('/showcase/posts/$postId');
      // Başarılı silme işleminde backend 204 No Content döner.
      return response.statusCode == 204;
    } on DioException {
      return false;
    }
  }


  Future<bool> likePost({required String postId}) async {
    try {
      final response = await _dio.post('/showcase/posts/$postId/like');
      return response.statusCode == 201; // Created
    } on DioException {
      return false;
    }
  }

  Future<bool> unlikePost({required String postId}) async {
    try {
      final response = await _dio.delete('/showcase/posts/$postId/like');
      return response.statusCode == 204; // No Content
    } on DioException {
      return false;
    }
  }

  // --- GÜNCELLENEN YORUM FONKSİYONU ---
  Future<Comment?> addComment({
    required String postId,
    required String content,
    String? parentCommentId, // Yanıt için yeni parametre
  }) async {
    try {
      final response = await _dio.post(
        '/showcase/posts/$postId/comments',
        data: {
          'content': content,
          'parent_comment_id': parentCommentId, // Yeni alan
        },
      );
      return Comment.fromJson(response.data);
    } on DioException catch (e) {
      print('addComment DioException: ${e.response?.data}');
      return null;
    }
  }

  // --- YENİ YORUM ETKİLEŞİM FONKSİYONLARI ---
  Future<bool> likeComment({required String commentId}) async {
    try {
      final response = await _dio.post('/showcase/comments/$commentId/like');
      return response.statusCode == 201;
    } on DioException {
      return false;
    }
  }

  Future<bool> unlikeComment({required String commentId}) async {
    try {
      final response = await _dio.delete('/showcase/comments/$commentId/like');
      return response.statusCode == 204;
    } on DioException {
      return false;
    }
  }

  Future<bool> deleteComment({required String commentId}) async {
    try {
      final response = await _dio.delete('/showcase/comments/$commentId');
      return response.statusCode == 204;
    } on DioException {
      return false;
    }
  }

  Future<bool> createProject({required String title, required String description, required String category, int? budgetMin, int? budgetMax, DateTime? deadline}) async {
    try {
      await _dio.post('/projects/', data: {
        'title': title, 'description': description, 'category': category,
        'budget_min': budgetMin, 'budget_max': budgetMax,
        'deadline': deadline?.toIso8601String(),
      });
      return true;
    } on DioException { return false; }
  }

  Future<List<Project>> getProjects({String? searchQuery, String? category, int? minBudget, int? maxBudget, String? sortBy}) async {
    try {
      final queryParameters = {
        if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
        if (category != null && category.isNotEmpty) 'category': category,
        if (minBudget != null) 'min_budget': minBudget,
        if (maxBudget != null) 'max_budget': maxBudget,
        if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
      };
      final response = await _dio.get('/projects/', queryParameters: queryParameters);
      return (response.data as List).map((json) => Project.fromJson(json)).toList();
    } on DioException { return []; }
  }

  Future<Project?> getProjectById({required String projectId}) async {
    try {
      final response = await _dio.get('/projects/$projectId');
      return Project.fromJson(response.data);
    } on DioException { return null; }
  }

  Future<List<Project>> getMyProjects() async {
    try {
      final response = await _dio.get('/projects/me');
      return (response.data as List).map((json) => Project.fromJson(json)).toList();
    } on DioException { return []; }
  }

  Future<Project?> deliverProject({required String projectId}) async {
    try {
      final response = await _dio.put('/projects/$projectId/deliver');
      return Project.fromJson(response.data);
    } on DioException { return null; }
  }

  Future<Project?> acceptDelivery({required String projectId}) async {
    try {
      final response = await _dio.put('/projects/$projectId/accept');
      return Project.fromJson(response.data);
    } on DioException { return null; }
  }

  Future<Project?> requestRevision({required String projectId}) async {
    try {
      final response = await _dio.put('/projects/$projectId/request-revision');
      return Project.fromJson(response.data);
    } on DioException { return null; }
  }

  Future<Project?> completeProject({required String projectId}) async {
    try {
      final response = await _dio.put('/projects/$projectId/complete');
      return Project.fromJson(response.data);
    } on DioException { return null; }
  }

  // --- Application ---
  Future<bool> applyToProject({required String projectId, String? coverLetter, double? proposedBudget}) async {
    try {
      await _dio.post('/applications/', data: {
        'project_id': projectId,
        'cover_letter': coverLetter,
        'proposed_budget': proposedBudget,
      });
      return true;
    } on DioException { return false; }
  }

  Future<List<Application>> getMyApplications() async {
    try {
      final response = await _dio.get('/applications/me');
      return (response.data as List).map((json) => Application.fromJson(json)).toList();
    } on DioException { return []; }
  }

  Future<List<Application>> getApplicationsForProject({required String projectId}) async {
    try {
      final response = await _dio.get('/projects/$projectId/applications');
      return (response.data as List).map((json) => Application.fromJson(json)).toList();
    } on DioException { return []; }
  }

  Future<bool> updateApplicationStatus({required String applicationId, required ApplicationStatus newStatus}) async {
    try {
      await _dio.put('/applications/$applicationId/status', data: {'status': newStatus.name});
      return true;
    } on DioException { return false; }
  }

  // --- User & Profile ---
  Future<User?> updateMyProfile({required Map<String, dynamic> data}) async {
    try {
      final response = await _dio.put('/users/me', data: data);
      return User.fromJson(response.data);
    } on DioException { return null; }
  }

  Future<User?> updateUserPicture({required File imageFile}) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });
      final response = await _dio.put('/users/me/picture', data: formData);
      return User.fromJson(response.data);
    } on DioException { return null; }
  }

  Future<User?> getUserProfileById({required String userId}) async {
    try {
      final response = await _dio.get('/users/$userId');
      return User.fromJson(response.data);
    } on DioException { return null; }
  }

  Future<bool> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      await _dio.put('/users/me/password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      return true;
    } on DioException { return false; }
  }

  // --- Skills ---
  Future<List<Skill>> getAvailableSkills() async {
    try {
      final response = await _dio.get('/skills/');
      return (response.data as List).map((json) => Skill.fromJson(json)).toList();
    } on DioException { return []; }
  }

  Future<User?> addSkillToUser({required String skillId}) async {
    try {
      final response = await _dio.post('/users/me/skills/$skillId');
      return User.fromJson(response.data);
    } on DioException { return null; }
  }

  Future<User?> removeSkillFromUser({required String skillId}) async {
    try {
      final response = await _dio.delete('/users/me/skills/$skillId');
      return User.fromJson(response.data);
    } on DioException { return null; }
  }

  // --- Portfolio ---
  Future<PortfolioItem?> addPortfolioItem({required String title, String? description, required File imageFile}) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'title': title,
        if (description != null) 'description': description,
        'file': await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });
      final response = await _dio.post('/portfolio/items', data: formData);
      return PortfolioItem.fromJson(response.data);
    } on DioException { return null; }
  }

  Future<PortfolioItem?> updatePortfolioItem({required String itemId, required String title, String? description, File? newFile}) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        if (description != null) 'description': description,
        if (newFile != null) 'file': await MultipartFile.fromFile(newFile.path, filename: newFile.path.split('/').last),
      });
      final response = await _dio.put('/portfolio/items/$itemId', data: formData);
      return PortfolioItem.fromJson(response.data);
    } on DioException { return null; }
  }

  Future<bool> deletePortfolioItem({required String itemId}) async {
    try {
      await _dio.delete('/portfolio/items/$itemId');
      return true;
    } on DioException { return false; }
  }

  // --- Work Experience ---
  Future<WorkExperience?> addWorkExperience({required Map<String, dynamic> data}) async {
    try {
      final response = await _dio.post('/work-experiences/me', data: data);
      return WorkExperience.fromJson(response.data);
    } on DioException { return null; }
  }

  Future<WorkExperience?> updateWorkExperience({required String experienceId, required Map<String, dynamic> data}) async {
    try {
      final response = await _dio.put('/work-experiences/$experienceId', data: data);
      return WorkExperience.fromJson(response.data);
    } on DioException { return null; }
  }

  Future<bool> deleteWorkExperience({required String experienceId}) async {
    try {
      await _dio.delete('/work-experiences/$experienceId');
      return true;
    } on DioException { return false; }
  }

  // --- Messages ---
  Future<List<Message>> getConversations() async {
    try {
      final response = await _dio.get('/messages/conversations/me');
      return (response.data as List).map((json) => Message.fromJson(json)).toList();
    } on DioException { return []; }
  }

  Future<List<Message>> getChatHistory({required String otherUserId}) async {
    try {
      final response = await _dio.get('/messages/$otherUserId');
      return (response.data as List).map((json) => Message.fromJson(json)).toList();
    } on DioException { return []; }
  }

  Future<Message?> sendMessage({required String receiverId, required String content}) async {
    try {
      final response = await _dio.post('/messages/', data: {'receiver_id': receiverId, 'content': content});
      return Message.fromJson(response.data);
    } on DioException { return null; }
  }

  Future<void> markAsRead({required String otherUserId}) async {
    try {
      await _dio.post('/messages/read/$otherUserId');
    } on DioException {}
  }

  Future<bool> deleteMessage({required String messageId}) async {
    try {
      await _dio.delete('/messages/$messageId');
      return true;
    } on DioException { return false; }
  }

  Future<bool> deleteConversation({required String otherUserId}) async {
    try {
      await _dio.delete('/messages/conversation/$otherUserId');
      return true;
    } on DioException { return false; }
  }

  // --- Reviews ---
  Future<Review?> submitReview({required ReviewCreate reviewData}) async {
    try {
      final response = await _dio.post('/reviews/', data: reviewData.toJson());
      return Review.fromJson(response.data);
    } on DioException { return null; }
  }

  Future<List<Review>> getReviewsForUser({required String userId}) async {
    try {
      final response = await _dio.get('/users/$userId/reviews');
      return (response.data as List).map((json) => Review.fromJson(json)).toList();
    } on DioException { return []; }
  }

  // --- Skill Tests ---
  Future<List<SkillTest>> getSkillTests() async {
    try {
      final response = await _dio.get('/skill-tests/');
      return (response.data as List).map((json) => SkillTest.fromJson(json)).toList();
    } on DioException { return []; }
  }

  Future<SkillTest?> getSkillTestDetails({required String testId}) async {
    try {
      final response = await _dio.get('/skill-tests/$testId');
      return SkillTest.fromJson(response.data);
    } on DioException { return null; }
  }

  Future<TestResult?> startTest({required String testId}) async {
    try {
      final response = await _dio.post('/skill-tests/$testId/start');
      return TestResult.fromJson(response.data);
    } on DioException { return null; }
  }

  Future<TestResult?> submitTest({required String resultId, required Map<String, dynamic> submission}) async {
    try {
      final response = await _dio.post('/skill-tests/results/$resultId/submit', data: submission);
      return TestResult.fromJson(response.data);
    } on DioException { return null; }
  }
}