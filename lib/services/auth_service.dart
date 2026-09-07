import 'dart:io';

import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/user.dart';

class AuthService {
  AuthService(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<User> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String provinceCode,
    required String cityCode,
    required String districtCode,
    required String villageCode,
  }) async {
    final response = await _apiClient.dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'terms_agreed': true,
      'device_name': 'flutter-app',
      'province_code': provinceCode,
      'city_code': cityCode,
      'district_code': districtCode,
      'village_code': villageCode,
    });

    final data = response.data['data'] as Map<String, dynamic>;
    await _tokenStorage.saveToken(data['token'] as String);
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<User> login({required String email, required String password}) async {
    final response = await _apiClient.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
      'device_name': 'flutter-app',
    });

    final data = response.data['data'] as Map<String, dynamic>;
    await _tokenStorage.saveToken(data['token'] as String);
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<User> loginWithGoogle(String idToken) async {
    final response = await _apiClient.dio.post('/auth/google', data: {
      'id_token': idToken,
      'device_name': 'flutter-app',
    });

    final data = response.data['data'] as Map<String, dynamic>;
    await _tokenStorage.saveToken(data['token'] as String);
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } finally {
      await _tokenStorage.clearToken();
    }
  }

  Future<User?> currentUser() async {
    final token = await _tokenStorage.readToken();
    if (token == null) return null;

    final response = await _apiClient.dio.get('/auth/user');
    final data = response.data['data'] as Map<String, dynamic>;
    return User.fromJson(data);
  }

  Future<void> forgotPassword(String email) async {
    await _apiClient.dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<User> updateProfile({required String name, required String phone, File? avatar}) async {
    final formData = FormData.fromMap({
      'name': name,
      'phone': phone,
      if (avatar != null) 'avatar': await MultipartFile.fromFile(avatar.path),
    });

    final response = await _apiClient.dio.post('/auth/user', data: formData);
    return User.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<User> updateAddress({
    required String provinceCode,
    required String cityCode,
    required String districtCode,
    required String villageCode,
  }) async {
    final response = await _apiClient.dio.put('/auth/user/address', data: {
      'province_code': provinceCode,
      'city_code': cityCode,
      'district_code': districtCode,
      'village_code': villageCode,
    });
    return User.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
