// lib/core/providers/auth_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../data/models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  String? _lastError;
  String? get lastError => _lastError;

  User? _user;
  String? _token;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isUpdatingPicture = false;

  User? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isUpdatingPicture => _isUpdatingPicture;
  String? get token => _token;

  AuthProvider() {
    print('[AuthProvider] Başlatıldı, otomatik giriş deneniyor...');
    tryAutoLogin();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final token = await _authService.login(email, password);
    if (token != null) {
      _token = token;
      final userProfile = await _authService.getMe(token);
      if (userProfile != null) {
        _user = userProfile;
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    }

    _isLoading = false;
    _isLoggedIn = false;
    notifyListeners();
    return false;
  }

  Future<void> tryAutoLogin() async {
    final token = await _authService.getToken();
    if (token == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    final userProfile = await _authService.getMe(token);
    if (userProfile != null) {
      _user = userProfile;
      _token = token;
      _isLoggedIn = true;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _isLoggedIn = false;
    await _authService.logout();
    notifyListeners();
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String phoneNumber,
  }) async {
    _isLoading = true;
    notifyListeners();

    final user = await _authService.signup(
      email: email,
      password: password,
      name: name,
      role: role,
      phoneNumber: phoneNumber,
    );

    _isLoading = false;
    if (user != null) {
      notifyListeners();
      return true;
    } else {
      _lastError = "Kayıt başarısız oldu. E-posta veya telefon numarası kullanımda olabilir.";
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_token == null) return false;
    final updatedUser = await _apiService.updateMyProfile(data: data, token: _token!);
    if (updatedUser != null) {
      _user = updatedUser;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> addSkillToUser(String skillId) async {
    if (_token == null) return false;
    final updatedUser = await _apiService.addSkillToUser(skillId: skillId, token: _token!);
    if (updatedUser != null) {
      _user = updatedUser;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> removeSkill(String skillId) async {
    if (_token == null) return false;
    final updatedUser = await _apiService.removeSkillFromUser(skillId: skillId, token: _token!);
    if (updatedUser != null) {
      _user = updatedUser;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateUserPicture(File imageFile) async {
    if (_token == null) return false;
    _isUpdatingPicture = true;
    notifyListeners();

    final updatedUserFromPut = await _apiService.updateUserPicture(
      imageFile: imageFile,
      token: _token!,
    );

    if (updatedUserFromPut != null) {
      final finalUpdatedUser = await _authService.getMe(_token!);
      if (finalUpdatedUser != null) {
        _user = finalUpdatedUser;
      }
    }

    _isUpdatingPicture = false;
    notifyListeners();
    return updatedUserFromPut != null;
  }

  Future<bool> addWorkExperience(Map<String, dynamic> data) async {
    if (_token == null) return false;
    final newExperience = await _apiService.addWorkExperience(data: data, token: _token!);
    if (newExperience != null) {
      final updatedUser = await _authService.getMe(_token!);
      if (updatedUser != null) {
        _user = updatedUser;
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> updateWorkExperience({
    required String experienceId,
    required Map<String, dynamic> data,
  }) async {
    if (_token == null) return false;
    final updatedExperience = await _apiService.updateWorkExperience(
      experienceId: experienceId,
      data: data,
      token: _token!,
    );

    if (updatedExperience != null) {
      final index = _user?.workExperiences.indexWhere((exp) => exp.id == experienceId);
      if (index != null && index != -1) {
        _user?.workExperiences[index] = updatedExperience;
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> deleteWorkExperience(String experienceId) async {
    if (_token == null) return false;
    final success = await _apiService.deleteWorkExperience(experienceId: experienceId, token: _token!);
    if (success) {
      _user?.workExperiences.removeWhere((exp) => exp.id == experienceId);
      notifyListeners();
    }
    return success;
  }

  Future<bool> addPortfolioItem({
    required String title,
    String? description,
    required File file,
  }) async {
    if (_token == null) return false;
    final newItem = await _apiService.addPortfolioItem(
      title: title,
      description: description,
      imageFile: file,
      token: _token!,
    );
    if (newItem != null && _user != null) {
      _user!.portfolioItems.add(newItem);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updatePortfolioItem({
    required String itemId,
    required String title,
    String? description,
    File? newFile,
  }) async {
    if (_token == null) return false;
    final updatedItem = await _apiService.updatePortfolioItem(
      itemId: itemId,
      title: title,
      description: description,
      newFile: newFile,
      token: _token!,
    );
    if (updatedItem != null) {
      final index = _user?.portfolioItems.indexWhere((item) => item.id == itemId);
      if (index != null && index != -1) {
        _user?.portfolioItems[index] = updatedItem;
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> deletePortfolioItem(String itemId) async {
    if (_token == null) return false;
    final success = await _apiService.deletePortfolioItem(itemId: itemId, token: _token!);
    if (success) {
      _user?.portfolioItems.removeWhere((item) => item.id == itemId);
      notifyListeners();
    }
    return success;
  }
}