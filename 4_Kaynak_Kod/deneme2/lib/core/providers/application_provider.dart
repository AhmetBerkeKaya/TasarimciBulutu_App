// lib/core/providers/application_provider.dart
import 'package:flutter/material.dart';
import '../../data/models/application_model.dart';
import '../services/api_service.dart';

class ApplicationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final String? _token;

  List<Application> _myApplications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Application> get myApplications => _myApplications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // AuthProvider'dan alınan token ile başlatılır
  ApplicationProvider(this._token) {
    if (_token != null) {
      fetchMyApplications();
    }
  }

  Future<void> fetchMyApplications() async {
    if (_token == null) {
      _errorMessage = "Lütfen giriş yapın.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myApplications = await _apiService.getMyApplications(token: _token!);
    } catch (e) {
      _errorMessage = "Başvurular yüklenirken bir hata oluştu.";
    }

    _isLoading = false;
    notifyListeners();
  }
}