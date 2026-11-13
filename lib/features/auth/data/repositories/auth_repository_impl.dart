import 'dart:convert';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/storage/event_queue_store.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/viewed_store.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final TokenStorage storage;

  AuthRepositoryImpl({required this.remote, TokenStorage? storage}) : storage = storage ?? TokenStorage();

  String _extractMessage(DioException e) {
    final friendly = e.error?.toString();
    if (friendly != null && friendly.isNotEmpty && friendly != 'null') return friendly;
    final data = e.response?.data;
    if (data is Map) {
      if (data['message'] is String) return data['message'] as String;
      if (data['errors'] is Map) {
        final errs = data['errors'] as Map;
        final first = errs.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
    }
    return e.message ?? 'Something went wrong';
  }

  @override
  Future<AuthResponse> register({required String name, required String email, required String phone, required String password, required String passwordConfirmation}) async {
    try {
      final res = await remote.register(name: name, email: email, phone: phone, password: password, passwordConfirmation: passwordConfirmation);
      if (res.error) throw Exception(res.message ?? 'Registration failed');
      return res;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  @override
  Future<AuthResponse> sendRegistrationOtp({required String name, required String email, required String phone, required String password, required String passwordConfirmation}) async {
    try {
      final res = await remote.sendRegistrationOtp(name: name, email: email, phone: phone, password: password, passwordConfirmation: passwordConfirmation);
      if (res.error) throw Exception(res.message ?? 'Could not send verification code');
      return res;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  @override
  Future<AuthResponse> verifyRegistrationOtp({required String email, required String otp}) async {
    try {
      final res = await remote.verifyRegistrationOtp(email: email, otp: otp);
      if (res.error) throw Exception(res.message ?? 'Verification failed');
      if (res.token != null) await storage.saveToken(res.token!);
      return res;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  @override
  Future<AuthResponse> resendRegistrationOtp({required String email}) async {
    try {
      final res = await remote.resendRegistrationOtp(email: email);
      if (res.error) throw Exception(res.message ?? 'Could not resend verification code');
      return res;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  @override
  Future<AuthResponse> login({required String email, required String password}) async {
    try {
      final res = await remote.login(email: email, password: password);
      if (res.error) throw Exception(res.message ?? 'Login failed');
      if (res.token != null) await storage.saveToken(res.token!);
      return res;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  @override
  Future<AuthResponse> checkEmail(String email) async {
    try {
      return await remote.checkEmail(email);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  @override
  Future<AuthResponse> forgotPassword(String email) async {
    try {
      final res = await remote.forgotPassword(email);
      if (res.error) throw Exception(res.message ?? 'Failed to send reset link');
      return res;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  @override
  Future<AuthResponse> resendVerify(String email) async {
    try {
      final res = await remote.resendVerify(email);
      if (res.error) throw Exception(res.message ?? 'Failed to resend');
      return res;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  @override
  Future<User> getMe() async {
    try {
      final user = await remote.getMe();
      await storage.saveUserJson(jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  @override
  Future<User> updateProfile({String? name, String? firstName, String? lastName, String? email, String? phone, String? dob, String? gender, String? description}) async {
    try {
      return await remote.updateProfile(name: name, firstName: firstName, lastName: lastName, email: email, phone: phone, dob: dob, gender: gender, description: description);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  @override
  Future<AuthResponse> updatePassword({required String oldPassword, required String password}) async {
    try {
      final res = await remote.updatePassword(oldPassword: oldPassword, password: password);
      if (res.error) throw Exception(res.message ?? 'Failed to update password');
      return res;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  @override
  Future<User> updateAvatar(String filePath) async {
    try {
      final formData = FormData.fromMap({'avatar': await MultipartFile.fromFile(filePath)});
      return await remote.updateAvatar(formData);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  @override
  Future<Map<String, dynamic>> getSettings() async {
    try {
      return await remote.getSettings();
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  @override
  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    try {
      return await remote.updateSettings(settings);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remote.logout();
    } catch (_) {}
    await storage.clearAll();
    // Clear local viewed history + event queue so next login / guest starts clean
    try {
      await ViewedStore.instance.clear();
    } catch (_) {}
    try {
      await EventQueueStore().clear();
    } catch (_) {}
    // Sign out from Google to clear cached account
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await GoogleSignIn().disconnect();
    } catch (_) {}
  }

  @override
  Future<AuthResponse> socialLogin(String provider, String accessToken) async {
    final preview = accessToken.length > 24 ? '${accessToken.substring(0, 24)}... (len=${accessToken.length})' : accessToken;
    dev.log('[GoogleLogin][Repo] socialLogin provider=$provider token=$preview', name: 'GoogleLogin');
    try {
      final res = await remote.socialLogin(provider, accessToken);
      dev.log('[GoogleLogin][Repo] success error=${res.error} message=${res.message} hasToken=${res.token != null}', name: 'GoogleLogin');
      if (res.error) throw Exception(res.message ?? 'Social login failed');
      if (res.token != null) await storage.saveToken(res.token!);
      return res;
    } on DioException catch (e, s) {
      final status = e.response?.statusCode;
      final serverMsg = e.response?.data is Map ? (e.response?.data as Map)['message'] : null;
      dev.log(
        '[GoogleLogin][Repo] DioException status=$status type=${e.type} serverMsg=$serverMsg friendly=${e.error} rawData=${e.response?.data}',
        name: 'GoogleLogin',
        error: e,
        stackTrace: s,
      );
      throw Exception(_extractMessage(e) + (status != null ? ' (HTTP $status)' : ''));
    } catch (e, s) {
      dev.log('[GoogleLogin][Repo] error throw: $e', name: 'GoogleLogin', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> clearAuth() => storage.clearAll();

  @override
  Future<String?> getToken() => storage.readToken();

  @override
  Future<bool> isLoggedIn() => storage.hasToken();

  @override
  Future<void> saveToken(String token) => storage.saveToken(token);
}
