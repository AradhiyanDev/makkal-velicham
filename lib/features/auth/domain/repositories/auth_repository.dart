import '../entities/user.dart';
import '../../data/models/auth_response.dart';

abstract class AuthRepository {
  Future<AuthResponse> register({required String name, required String email, required String phone, required String password, required String passwordConfirmation});
  Future<AuthResponse> sendRegistrationOtp({required String name, required String email, required String phone, required String password, required String passwordConfirmation});
  Future<AuthResponse> verifyRegistrationOtp({required String email, required String otp});
  Future<AuthResponse> resendRegistrationOtp({required String email});
  Future<AuthResponse> login({required String email, required String password});
  Future<AuthResponse> checkEmail(String email);
  Future<AuthResponse> forgotPassword(String email);
  Future<AuthResponse> resendVerify(String email);
  Future<User> getMe();
  Future<User> updateProfile({String? name, String? firstName, String? lastName, String? email, String? phone, String? dob, String? gender, String? description});
  Future<AuthResponse> updatePassword({required String oldPassword, required String password});
  Future<User> updateAvatar(String filePath);
  Future<Map<String, dynamic>> getSettings();
  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings);
  Future<void> logout();
  Future<AuthResponse> socialLogin(String provider, String accessToken);

  // Token helpers
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<void> clearAuth();
  Future<bool> isLoggedIn();
}
