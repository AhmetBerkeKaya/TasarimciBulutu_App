// lib/core/providers/showcase_provider.dart

import 'package:flutter/foundation.dart';

import '../../data/models/showcase_post_model.dart';
import '../services/api_service.dart';

class ShowcaseProvider with ChangeNotifier {
  final ApiService _apiService;

  ShowcaseProvider(this._apiService);

  // --- State Değişkenleri ---
  // Bu değişkenler, UI'ın o anki durumu hakkında bilgi verir.

  // Vitrin gönderilerinin listesi
  List<ShowcasePost> _posts = [];

  // Veri yükleniyor mu? (Progress indicator göstermek için)
  bool _isLoading = false;

  // Bir hata oluştu mu?
  String? _error;

  // --- Getters ---
  // UI katmanının bu değişkenlere sadece okuma amaçlı erişmesini sağlar.
  List<ShowcasePost> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- Fonksiyonlar ---

  /// Backend'den tüm vitrin gönderilerini çeker.
  Future<void> fetchShowcasePosts() async {
    _isLoading = true;
    _error = null; // Önceki hataları temizle
    notifyListeners(); // Yüklemenin başladığını UI'a bildir

    try {
      _posts = await _apiService.getAllShowcasePosts();
    } catch (e) {
      _error = "Gönderiler yüklenirken bir hata oluştu: $e";
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners(); // Yüklemenin bittiğini ve UI'ın güncellenmesi gerektiğini bildir
    }
  }

  /// Yeni bir vitrin gönderisi oluşturur.
  Future<bool> createShowcasePost({
    required String title,
    String? description,
    required String filePath,
  }) async {
    // Bu fonksiyon için de bir yüklenme durumu yönetilebilir, şimdilik basit tutuyoruz.
    try {
      final newPost = await _apiService.createShowcasePost(
        title: title,
        description: description,
        filePath: filePath,
      );
      // Başarıyla oluşturulduktan sonra listeyi yenilemek yerine,
      // yeni gönderiyi listenin başına ekleyerek daha verimli bir güncelleme yapalım.
      _posts.insert(0, newPost);
      notifyListeners();
      return true; // Başarılı olduğunu belirt
    } catch (e) {
      print("Gönderi oluşturma hatası: $e");
      // UI'da kullanıcıya bir hata mesajı göstermek için state güncellenebilir.
      return false; // Başarısız olduğunu belirt
    }
  }
}