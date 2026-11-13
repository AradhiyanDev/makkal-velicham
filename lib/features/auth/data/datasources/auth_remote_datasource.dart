import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> register({required String name, required String email, required String phone, required String password, required String passwordConfirmation});
  Future<AuthResponse> login({required String email, required String password});
  Future<AuthResponse> checkEmail(String email);
  Future<AuthResponse> forgotPassword(String email);
  Future<AuthResponse> resendVerify(String email);
  Future<UserModel> getMe();
  Future<UserModel> updateProfile({String? name, String? firstName, String? lastName, String? email, String? phone, String? dob, String? gender, String? description});
  Future<AuthResponse> updatePassword({required String oldPassword, required String password});
  Future<UserModel> updateAvatar(FormData formData);
  Future<Map<String, dynamic>> getSettings();
  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings);
  Future<AuthResponse> logout();
  Future<AuthResponse> socialLogin(String provider, String accessToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;
  AuthRemoteDataSourceImpl({DioClient? dioClient}) : dioClient = dioClient ?? DioClient();

  /// Splits a full name into first/last for APIs that require first_name NOT NULL.
  /// e.g. "Arun Ashwini" -> ["Arun", "Ashwini"], "Arun" -> ["Arun", "Arun"]
  static List<String> splitFullName(String fullName) {
    final trimmed = fullName.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return ['', ''];
    final parts = trimmed.split(' ');
    if (parts.length == 1) return [parts.first, parts.first];
    return [parts.first, parts.sublist(1).join(' ')];
  }

  @override
  Future<AuthResponse> register({required String name, required String email, required String phone, required String password, required String passwordConfirmation}) async {
    final trimmedName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final nameParts = splitFullName(trimmedName);
    final firstName = nameParts[0];
    final lastName = nameParts[1];

    // Send BOTH styles for compatibility:
    // - first_name/last_name: required by current members table (first_name NOT NULL) -> avoids 500
    // - name: expected by docs / fallback for providers that use single field
    // - phone: optional (alternate docs body omits it) -> only send if non-empty
    final payload = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'name': trimmedName,
      'email': email.trim(),
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
    if (phone.trim().isNotEmpty) {
      payload['phone'] = phone.trim();
    }

    final res = await dioClient.post<Map<String, dynamic>>(
      '/api/v1/register',
      data: payload,
    );
    return AuthResponse.fromJson(res.data ?? {});
  }

  @override
  Future<AuthResponse> login({required String email, required String password}) async {
    final res = await dioClient.post<Map<String, dynamic>>(
      '/api/v1/login',
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(res.data ?? {});
  }

  @override
  Future<AuthResponse> checkEmail(String email) async {
    final res = await dioClient.post<Map<String, dynamic>>('/api/v1/email/check', data: {'email': email});
    return AuthResponse.fromJson(res.data ?? {});
  }

  @override
  Future<AuthResponse> forgotPassword(String email) async {
    final res = await dioClient.post<Map<String, dynamic>>('/api/v1/password/forgot', data: {'email': email});
    return AuthResponse.fromJson(res.data ?? {});
  }

  @override
  Future<AuthResponse> resendVerify(String email) async {
    final res = await dioClient.post<Map<String, dynamic>>('/api/v1/resend-verify-account-email', data: {'email': email});
    return AuthResponse.fromJson(res.data ?? {});
  }

  @override
  Future<UserModel> getMe() async {
    final res = await dioClient.get<Map<String, dynamic>>('/api/v1/me');
    final data = res.data ?? {};
    final error = data['error'] as bool? ?? false;
    if (error) throw DioException(requestOptions: res.requestOptions, error: data['message'] ?? 'Failed to fetch profile');
    final userJson = data['data'] as Map<String, dynamic>?;
    if (userJson == null) throw DioException(requestOptions: res.requestOptions, error: 'Empty user data');
    return UserModel.fromJson(userJson);
  }

  @override
  Future<UserModel> updateProfile({String? name, String? firstName, String? lastName, String? email, String? phone, String? dob, String? gender, String? description}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (dob != null) body['dob'] = dob;
    if (gender != null) body['gender'] = gender;
    if (description != null) body['description'] = description;
    final res = await dioClient.put<Map<String, dynamic>>('/api/v1/me', data: body);
    final data = res.data ?? {};
    if (data['error'] == true) throw DioException(requestOptions: res.requestOptions, error: data['message']);
    return UserModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<AuthResponse> updatePassword({required String oldPassword, required String password}) async {
    final res = await dioClient.put<Map<String, dynamic>>(
      '/api/v1/update/password',
      data: {'old_password': oldPassword, 'password': password, 'password_confirmation': password},
    );
    return AuthResponse.fromJson(res.data ?? {});
  }

  @override
  Future<UserModel> updateAvatar(FormData formData) async {
    final res = await dioClient.postForm<Map<String, dynamic>>('/api/v1/update/avatar', data: formData);
    final data = res.data ?? {};
    if (data['error'] == true) throw DioException(requestOptions: res.requestOptions, error: data['message']);
    final avatarData = data['data'] as Map<String, dynamic>?;
    // API returns {data:{avatar:"https://..."}}
    // We return a minimal user with avatar; caller will merge
    if (avatarData != null && avatarData['avatar'] != null) {
      // Return user with updated avatar only; let repo fetch full user if needed
      return UserModel(id: 0, name: '', email: '', avatar: avatarData['avatar'] as String?);
    }
    throw DioException(requestOptions: res.requestOptions, error: 'Invalid avatar response');
  }

  @override
  Future<Map<String, dynamic>> getSettings() async {
    final res = await dioClient.get<Map<String, dynamic>>('/api/v1/settings');
    return (res.data?['data'] as Map<String, dynamic>?) ?? res.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    final res = await dioClient.put<Map<String, dynamic>>('/api/v1/settings', data: settings);
    // Update shape nests the flat map: {data:{message, settings:{...}}}
    final data = res.data?['data'];
    if (data is Map<String, dynamic> && data['settings'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data['settings'] as Map);
    }
    return (res.data?['data'] as Map<String, dynamic>?) ?? res.data ?? {};
  }

  @override
  Future<AuthResponse> logout() async {
    final res = await dioClient.get<Map<String, dynamic>>('/api/v1/logout');
    return AuthResponse.fromJson(res.data ?? {});
  }

  @override
  Future<AuthResponse> socialLogin(String provider, String identityToken) async {
    final preview = identityToken.length > 24 ? '${identityToken.substring(0, 24)}... (len=${identityToken.length})' : identityToken;
    dev.log('[GoogleLogin] POST /api/v1/auth/$provider guard=member token=$preview', name: 'GoogleLogin');
    try {
      final res = await dioClient.post<Map<String, dynamic>>('/api/v1/auth/$provider', data: {'identityToken': identityToken, 'guard': 'member'});
      dev.log('[GoogleLogin] Response status=${res.statusCode} data=${res.data}', name: 'GoogleLogin');
      return AuthResponse.fromJson(res.data ?? {});
    } on DioException catch (e) {
      dev.log(
        '[GoogleLogin] DioException type=${e.type} status=${e.response?.statusCode} message=${e.message} error=${e.error} data=${e.response?.data}',
        name: 'GoogleLogin',
        error: e,
        stackTrace: e.stackTrace,
      );
      rethrow;
    } catch (e, s) {
      dev.log('[GoogleLogin] Unexpected error: $e', name: 'GoogleLogin', error: e, stackTrace: s);
      rethrow;
    }
  }
}
