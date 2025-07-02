// lib/core/services/auth_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../data/models/enums.dart';
import '../../data/models/user_model.dart';

class AuthService {
  // Android emülatörü için localhost IP'si 10.0.2.2'dir.
  // Fiziksel cihaz veya iOS simülatörü için kendi bilgisayarının IP adresini yazmalısın.
  final String _baseUrl = "http://10.0.2.2:8000";
  final _storage = const FlutterSecureStorage();

  // Kayıt olma fonksiyonu
  Future<User?> signup({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final url = Uri.parse('$_baseUrl/users/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'name': name,
          'password': password,
          'role': role.name, // Enum'ı string'e çeviriyoruz
        }),
      );

      // --- DÜZELTME BURADA ---
      // Hem 200 (OK) hem de 201 (Created) durumları başarıdır.
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = json.decode(utf8.decode(response.bodyBytes));
        return User.fromJson(responseBody);
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        print('Signup Error: ${response.statusCode} - ${errorBody['detail']}');
        return null;
      }
    } catch (e) {
      print('Signup Exception: $e');
      return null;
    }
  }

  Future<String?> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/token');
    print('[AuthService] Login isteği atılıyor: $url');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': email, 'password': password},
      );

      print('[AuthService] Login yanıtı geldi: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['access_token'];
        await _storage.write(key: 'access_token', value: token);
        print('[AuthService] Token başarıyla alındı ve saklandı.');
        return token;
      } else {
        print('[AuthService] Login HATA: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('[AuthService] Login EXCEPTION: $e');
      return null;
    }
  }

  Future<User?> getMe(String token) async {
    final url = Uri.parse('$_baseUrl/users/me');
    print('[AuthService] getMe isteği atılıyor: $url');
    print('[AuthService] Kullanılan Token (ilk 10 karakter): ${token.substring(0, 10)}...');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[AuthService] getMe yanıtı geldi: ${response.statusCode}');
      print('[AuthService] getMe yanıt BODY: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = json.decode(utf8.decode(response.bodyBytes));
        print('[AuthService] getMe JSON parse ediliyor...');
        final user = User.fromJson(responseBody);
        print('[AuthService] getMe başarıyla User modeline dönüştürüldü: ${user.name}');
        return user;
      } else {
        return null;
      }
    } catch (e) {
      print('[AuthService] getMe EXCEPTION: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }
}