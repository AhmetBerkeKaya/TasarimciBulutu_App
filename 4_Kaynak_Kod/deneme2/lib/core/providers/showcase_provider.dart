// lib/core/providers/showcase_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/showcase_post_model.dart';
import '../services/api_service.dart';

enum ShowcaseState { initial, loading, loaded, loadingMore, error }

class ShowcaseProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // --- YENİ: Sayfa başına gönderi sayısı için bir sabit tanımlıyoruz ---
  static const int _pageSize = 20;

  // State variables
  List<ShowcasePost> _posts = [];
  ShowcaseState _state = ShowcaseState.initial;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMorePosts = true;
  bool _isCreatingPost = false;

  // Getters
  List<ShowcasePost> get posts => _posts;
  ShowcaseState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get hasMorePosts => _hasMorePosts;
  bool get isCreatingPost => _isCreatingPost;

  void updateToken(String? token) {
    if (token != null && _state == ShowcaseState.initial) {
      fetchPosts();
    }
  }

  /// İlk gönderi grubunu çeker.
  Future<void> fetchPosts() async {
    if (_state == ShowcaseState.loading) return;
    _state = ShowcaseState.loading;
    notifyListeners();

    try {
      _currentPage = 0;
      // --- GÜNCELLENEN MANTIK ---
      final newPosts = await _apiService.getShowcasePosts(page: _currentPage, limit: _pageSize);
      _posts = newPosts;
      // Eğer backend'den gelen gönderi sayısı, istediğimiz sayıya eşitse, devamı olabilir.
      // Eğer daha azsa, bu son sayfa demektir.
      _hasMorePosts = newPosts.length == _pageSize;
      _state = ShowcaseState.loaded;
    } catch (e) {
      _errorMessage = "Gönderiler yüklenirken bir hata oluştu: $e";
      _state = ShowcaseState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Daha fazla gönderi çeker (sonsuz kaydırma için).
  Future<void> fetchMorePosts() async {
    if (_state == ShowcaseState.loadingMore || !_hasMorePosts) return;
    _state = ShowcaseState.loadingMore;
    notifyListeners();

    try {
      _currentPage++;
      // --- GÜNCELLENEN MANTIK ---
      final newPosts = await _apiService.getShowcasePosts(page: _currentPage, limit: _pageSize);

      if (newPosts.length < _pageSize) {
        // Eğer gelen gönderi sayısı istediğimizden azsa, bu kesinlikle son sayfadır.
        _hasMorePosts = false;
      }

      _posts.addAll(newPosts);
      _state = ShowcaseState.loaded;
    } catch (e) {
      _errorMessage = "Daha fazla gönderi yüklenemedi: $e";
      _state = ShowcaseState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Yeni bir vitrin gönderisi oluşturur. Dosya varsa önce onu S3'e yükler.
  Future<bool> createPost({
    required String title,
    String? description,
    File? fileToUpload,
  }) async {
    _isCreatingPost = true;
    _errorMessage = null;
    notifyListeners();

    String? finalFileUrl;

    try {
      if (fileToUpload != null) {
        final presignedData = await _apiService.getPresignedUploadUrl(fileToUpload);
        if (presignedData == null) throw Exception("Yükleme adresi alınamadı.");

        final uploadSuccess = await _apiService.uploadFileToS3(
          presignedData: presignedData,
          file: fileToUpload,
        );
        if (!uploadSuccess) throw Exception("Dosya yüklenemedi.");

        finalFileUrl = '${presignedData.url}${presignedData.fields['key']}';
      }

      final newPost = await _apiService.createShowcasePost(
        title: title,
        description: description,
        fileUrl: finalFileUrl,
      );

      if (newPost != null) {
        _posts.insert(0, newPost);
        _isCreatingPost = false;
        notifyListeners();
        return true;
      } else {
        throw Exception("Gönderi veritabanına kaydedilemedi.");
      }
    } catch (e) {
      _errorMessage = "Gönderi oluşturulurken bir hata oluştu: $e";
      _isCreatingPost = false;
      notifyListeners();
      return false;
    }
  }

  /// Bir gönderiyi beğenir veya beğeniyi geri alır.
  Future<void> toggleLike(String postId, String currentUserId) async {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final isLiked = post.likes.any((like) => like.userId == currentUserId);

    if (isLiked) {
      post.likes.removeWhere((like) => like.userId == currentUserId);
    } else {
      post.likes.add(PostLike(userId: currentUserId, postId: postId));
    }
    notifyListeners();

    try {
      if (isLiked) {
        await _apiService.unlikePost(postId: postId);
      } else {
        await _apiService.likePost(postId: postId);
      }
    } catch (e) {
      print("Beğenme işlemi başarısız: $e");
      if (isLiked) {
        post.likes.add(PostLike(userId: currentUserId, postId: postId));
      } else {
        post.likes.removeWhere((like) => like.userId == currentUserId);
      }
      notifyListeners();
    }
  }

  /// Bir gönderiye yorum ekler.
  Future<bool> addComment(String postId, String content) async {
    try {
      final newComment = await _apiService.addComment(postId: postId, content: content);
      if (newComment != null) {
        final postIndex = _posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          _posts[postIndex].comments.insert(0, newComment);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print("Yorum eklenemedi: $e");
      return false;
    }
  }
}
