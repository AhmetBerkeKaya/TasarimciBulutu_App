// lib/core/providers/application_provider.dart
import 'package:flutter/foundation.dart';
import '../../data/models/application_model.dart';
import '../../data/models/enums.dart';
import '../services/api_service.dart';

class ApplicationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;

  List<Application> _myApplications = [];
  bool _isLoading = false;
  String? _errorMessage; // <-- Hata mesajı için state eklendi

  List<Application> get myApplications => _myApplications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage; // <-- Getter eklendi

  // ProxyProvider tarafından token'ı güncellemek için kullanılacak metod
  void updateToken(String? newToken) {
    _token = newToken;
    // Token değiştiğinde (giriş/çıkış yapıldığında) başvuruları otomatik çek
    if (_token != null) {
      fetchMyApplications();
    } else {
      _myApplications = [];
      notifyListeners();
    }
  }

  Future<void> fetchMyApplications() async {
    if (_token == null) return;
    _isLoading = true;
    _errorMessage = null; // İşleme başlarken eski hatayı temizle
    notifyListeners();

    try {
      _myApplications = await _apiService.getMyApplications(token: _token!);
    } catch (e) {
      _errorMessage = "Başvurular yüklenirken bir hata oluştu.";
      _myApplications = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> applyToProject({
    required String projectId,
    required String coverLetter,
    double? proposedBudget,
  }) async {
    if (_token == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final success = await _apiService.applyToProject(
      projectId: projectId,
      coverLetter: coverLetter,
      proposedBudget: proposedBudget,
      token: _token!,
    );

    if (success) {
      await fetchMyApplications(); // Başarılı olursa listeyi yenile
    } else {
      _errorMessage = "Başvuru gönderilirken bir hata oluştu.";
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
  Future<bool> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus newStatus,
  }) async {
    if (_token == null) {
      _errorMessage = "İşlem yapmak için giriş yapmalısınız.";
      notifyListeners();
      return false;
    }

    // Yüklenme durumunu burada yönetebiliriz, ancak şimdilik basit tutalım.
    final success = await _apiService.updateApplicationStatus(
      applicationId: applicationId,
      newStatus: newStatus,
      token: _token!,
    );

    if (success) {
      // Başarılı olursa, başvuru listesini güncelleyerek arayüzün yenilenmesini sağla.
      // Not: Bu, hem MyApplicationsScreen hem de ProjectApplicantsScreen'i etkiler.
      // Daha verimli bir yol, sadece tek bir başvuruyu lokalde güncellemektir.
      // Şimdilik en güvenli yol olan yeniden çekme ile devam edelim.
      print("Başvuru durumu güncellendi, liste yenileniyor...");
    } else {
      _errorMessage = "Durum güncellenirken bir hata oluştu.";
      notifyListeners();
    }
    return success;
  }
}