// ignore_for_file: unnecessary_cast
import 'user_model.dart';

class AuthResponse {
  final bool error;
  final String? message;
  final String? token;
  final UserModel? user;
  final Map<String, dynamic>? errors;

  const AuthResponse({required this.error, this.message, this.token, this.user, this.errors});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Login: {error:false, data:{token:...}, message:null}
    // Register: {error:false, data:null, message:"Registered..."}
    // CheckEmail: {error:false, data:{exists:true, user:{...}}}
    final data = json['data'];
    String? token;
    UserModel? user;
    if (data is Map<String, dynamic>) {
      if (data['token'] is String) token = data['token'];
      if (data['user'] is Map<String, dynamic>) user = UserModel.fromJson(data['user']);
      // Some endpoints return user directly in data
      if (user == null && data.containsKey('email')) {
        // Direct user object (Me)
        try {
          user = UserModel.fromJson(data);
        } catch (_) {}
      }
    } else if (data is Map && (data as Map)['email'] != null) {
      user = UserModel.fromJson(Map<String, dynamic>.from(data as Map));
    }

    return AuthResponse(
      error: json['error'] as bool? ?? false,
      message: json['message'] as String?,
      token: token,
      user: user,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}
