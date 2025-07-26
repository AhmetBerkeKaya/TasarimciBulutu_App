// lib/core/providers/showcase_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/comment_model.dart';
import '../../data/models/showcase_post_model.dart';
import '../services/api_service.dart';

enum ShowcaseState { initial, loading, loaded, loadingMore, error }

class ShowcaseProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  static const int _pageSize = 20;

  List<ShowcasePost> _posts = [];
  ShowcaseState _state = ShowcaseState.initial;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMorePosts = true;
  bool _isCreatingPost = false;

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

  Future<void> fetchPosts() async {
    // ... içerik aynı
    if (_state == ShowcaseState.loading) return;
    _state = ShowcaseState.loading;
    notifyListeners();

    try {
      _currentPage = 0;
      final newPosts = await _apiService.getShowcasePosts(page: _currentPage, limit: _pageSize);
      _posts = newPosts;
      _hasMorePosts = newPosts.length == _pageSize;
      _state = ShowcaseState.loaded;
    } catch (e) {
      _errorMessage = "Gönderiler yüklenirken bir hata oluştu: $e";
      _state = ShowcaseState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchMorePosts() async {
    // ... içerik aynı
    if (_state == ShowcaseState.loadingMore || !_hasMorePosts) return;
    _state = ShowcaseState.loadingMore;
    notifyListeners();

    try {
      _currentPage++;
      final newPosts = await _apiService.getShowcasePosts(page: _currentPage, limit: _pageSize);
      if (newPosts.length < _pageSize) {
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

  // --- GÜNCELLENEN FONKSİYON ---
  Future<bool> createPost({
    required String title,
    String? description,
    File? imageFile,
    File? modelFile,
  }) async {
    _isCreatingPost = true;
    _errorMessage = null;
    notifyListeners();

    String? finalImageUrl;
    String? finalModelUrl;
    String? modelFormat;

    try {
      // 1. Adım: Resim dosyasını yükle (varsa)
      if (imageFile != null) {
        print("🔍 Adım 1: Görsel yükleme başlıyor...");
        final presignedData = await _apiService.getPresignedUploadUrl(
          file: imageFile,
          fileCategory: 'image',
        );
        if (presignedData != null) {
          final success = await _apiService.uploadFileToS3(
            presignedData: presignedData,
            file: imageFile,
          );
          if (success) {
            finalImageUrl = presignedData.finalFileUrl;
            print("✅ Adım 1 Başarılı: Görsel yüklendi -> $finalImageUrl");
          } else {
            throw Exception("Görsel S3'e yüklenemedi.");
          }
        } else {
          throw Exception("Görsel için S3 linki alınamadı.");
        }
      }

      // 2. Adım: 3D model dosyasını yükle (varsa)
      if (modelFile != null) {
        print("🔍 Adım 2: 3D Model yükleme başlıyor...");
        final presignedData = await _apiService.getPresignedUploadUrl(
          file: modelFile,
          fileCategory: 'model',
        );

        // --- DETAYLI HATA AYIKLAMA BURADA ---
        if (presignedData == null) {
          // Bu durum, backend'den 400 veya 500 hatası aldığımızda gerçekleşir.
          throw Exception("3D Model için S3 linki alınamadı. Backend'de bir sorun olabilir.");
        }

        print("... 3D Model için S3 linki alındı, şimdi yükleniyor...");
        final success = await _apiService.uploadFileToS3(
          presignedData: presignedData,
          file: modelFile,
        );

        if (success) {
          finalModelUrl = presignedData.finalFileUrl;
          modelFormat = presignedData.fileFormat;
          print("✅ Adım 2 Başarılı: 3D Model yüklendi -> $finalModelUrl");
        } else {
          throw Exception("3D Model S3'e yüklenemedi. S3 izinlerini veya dosya boyutunu kontrol edin.");
        }
      }

      // 3. Adım: Gönderiyi oluştur
      print("🔍 Adım 3: Gönderi veritabanına kaydediliyor...");
      final newPost = await _apiService.createShowcasePost(
        title: title,
        description: description,
        fileUrl: finalImageUrl,
        modelUrl: finalModelUrl,
        modelFormat: modelFormat,
      );

      if (newPost != null) {
        _posts.insert(0, newPost);
        print("✅ Adım 3 Başarılı: Gönderi oluşturuldu.");
        return true;
      } else {
        throw Exception("Gönderi API tarafından oluşturulamadı.");
      }
    } catch (e) {
      print("❌ HATA: createPost sürecinde bir sorun oluştu -> ${e.toString()}");
      _errorMessage = "Gönderi oluşturulurken bir hata oluştu: ${e.toString().replaceAll("Exception: ", "")}";
      return false;
    } finally {
      _isCreatingPost = false;
      notifyListeners();
    }
  }

  // ... (Geri kalan tüm fonksiyonlar aynı)
  Future<bool> deletePost(String postId) async {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return false;

    final postToRemove = _posts.removeAt(postIndex);
    notifyListeners();

    final success = await _apiService.deleteShowcasePost(postId: postId);

    if (!success) {
      _posts.insert(postIndex, postToRemove);
      _errorMessage = "Gönderi silinemedi. Lütfen tekrar deneyin.";
      notifyListeners();
    }

    return success;
  }
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
  Future<bool> addComment(String postId, String content, {String? parentCommentId}) async {
    try {
      final newComment = await _apiService.addComment(
        postId: postId,
        content: content,
        parentCommentId: parentCommentId,
      );
      if (newComment != null) {
        final postIndex = _posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          if (parentCommentId != null) {
            _findAndAddReply(_posts[postIndex].comments, parentCommentId, newComment);
          } else {
            _posts[postIndex].comments.insert(0, newComment);
          }
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
  void _findAndAddReply(List<Comment> comments, String parentId, Comment reply) {
    for (var comment in comments) {
      if (comment.id == parentId) {
        comment.replies.insert(0, reply);
        return;
      }
      if (comment.replies.isNotEmpty) {
        _findAndAddReply(comment.replies, parentId, reply);
      }
    }
  }
  Future<void> toggleCommentLike(String postId, String commentId, String currentUserId) async {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    Comment? targetComment = findComment(_posts[postIndex].comments, commentId);
    if (targetComment == null) return;

    final isLiked = targetComment.likes.any((like) => like.userId == currentUserId);

    if (isLiked) {
      targetComment.likes.removeWhere((like) => like.userId == currentUserId);
    } else {
      targetComment.likes.add(CommentLike(userId: currentUserId, commentId: commentId));
    }
    notifyListeners();

    try {
      if (isLiked) {
        await _apiService.unlikeComment(commentId: commentId);
      } else {
        await _apiService.likeComment(commentId: commentId);
      }
    } catch (e) {
      if (isLiked) {
        targetComment.likes.add(CommentLike(userId: currentUserId, commentId: commentId));
      } else {
        targetComment.likes.removeWhere((like) => like.userId == currentUserId);
      }
      notifyListeners();
    }
  }
  Comment? findComment(List<Comment> comments, String commentId) {
    for (var comment in comments) {
      if (comment.id == commentId) return comment;
      final foundInReply = findComment(comment.replies, commentId);
      if (foundInReply != null) return foundInReply;
    }
    return null;
  }
  Future<bool> deleteComment(String postId, String commentId) async {
    final success = await _apiService.deleteComment(commentId: commentId);
    if (success) {
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final removed = _findAndRemoveComment(_posts[postIndex].comments, commentId);
        if (removed) {
          notifyListeners();
        }
      }
    }
    return success;
  }
  bool _findAndRemoveComment(List<Comment> comments, String commentId) {
    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == commentId) {
        comments.removeAt(i);
        return true;
      }
      if (comments[i].replies.isNotEmpty) {
        if (_findAndRemoveComment(comments[i].replies, commentId)) {
          return true;
        }
      }
    }
    return false;
  }
}