// lib/core/services/auth_service.dart (YENİ HALİ)

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/enums.dart';
import '../../data/models/user_model.dart';
import 'dio_client.dart';

class AuthService {
  final Dio _dio = DioClient.instance.dio;
  final _storage = const FlutterSecureStorage();

  Future<User?> signup({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String phoneNumber,
  }) async {
    try {
      final response = await _dio.post(
        '/users/', // Base URL zaten Dio'da tanımlı
        data: {
          'email': email,
          'name': name,
          'password': password,
          'role': role.name,
          'phone_number': phoneNumber,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      print('Signup DioException: ${e.response?.data}');
      return null;
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      // Dio, form-urlencoded veriyi otomatik anlar.
      final response = await _dio.post(
        '/token',
        data: {'username': email, 'password': password},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        await _storage.write(key: 'access_token', value: token);
        return token;
      }
      return null;
    } on DioException catch (e) {
      print('Login DioException: ${e.response?.data}');
      return null;
    }
  }

  Future<User?> getMe() async {
    // Token parametresine gerek kalmadı, Interceptor hallediyor!
    try {
      final response = await _dio.get('/users/me');
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      print('getMe DioException: ${e.response?.data}');
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