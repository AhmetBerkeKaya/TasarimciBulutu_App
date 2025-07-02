// lib/core/providers/auth_provider.dart
import 'package:flutter/material.dart';

import '../../data/models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  String? _token; // Bu alan private (gizli)
  bool _isLoggedIn = false;
  bool _isLoading = true;

  // --- Public (Herkese Açık) Getter'lar ---
  User? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  // --- EKLENECEK SATIR BURASI ---
  String? get token => _token; // _token'a dışarıdan erişim için public getter

  AuthProvider() {
    print('[AuthProvider] Başlatıldı, otomatik giriş deneniyor...');
    tryAutoLogin();
  }

  // ... (login, tryAutoLogin, logout fonksiyonları aynı kalır) ...
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    print('[AuthProvider] Login fonksiyonu çağrıldı.');

    final token = await _authService.login(email, password);
    if (token != null) {
      _token = token;
      print('[AuthProvider] Token alındı, profil bilgisi çekiliyor...');
      final userProfile = await _authService.getMe(token);
      if (userProfile != null) {
        _user = userProfile;
        _isLoggedIn = true;
        _isLoading = false;
        print('[AuthProvider] GİRİŞ BAŞARILI! Kullanıcı: ${_user?.name}');
        notifyListeners();
        return true;
      } else {
        print('[AuthProvider] HATA: Profil bilgisi alınamadı.');
      }
    } else {
      print('[AuthProvider] HATA: Token alınamadı.');
    }

    _isLoading = false;
    _isLoggedIn = false;
    notifyListeners();
    print('[AuthProvider] GİRİŞ BAŞARISIZ!');
    return false;
  }

  Future<void> tryAutoLogin() async {
    final token = await _authService.getToken();
    if (token == null) {
      print('[AuthProvider] Cihazda kayıtlı token bulunamadı.');
      _isLoading = false;
      notifyListeners();
      return;
    }
    print('[AuthProvider] Kayıtlı token bulundu, profil bilgisi çekiliyor...');
    final userProfile = await _authService.getMe(token);
    if (userProfile != null) {
      _user = userProfile;
      _token = token;
      _isLoggedIn = true;
      print('[AuthProvider] Otomatik giriş başarılı: ${_user?.name}');
    } else {
      print('[AuthProvider] Otomatik giriş başarısız: Kayıtlı token ile profil alınamadı.');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _isLoggedIn = false;
    await _authService.logout();
    print('[AuthProvider] Çıkış yapıldı.');
    notifyListeners();
  }
}