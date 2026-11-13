import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:developer' as dev;

import '../../domain/repositories/auth_repository.dart';

enum AuthMode { login, register }

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  final AuthMode mode;
  const AuthInitial(this.mode);
  @override
  List<Object?> get props => [mode];
}

class AuthLoading extends AuthState {
  final AuthMode mode;
  const AuthLoading(this.mode);
  @override
  List<Object?> get props => [mode];
}

class AuthSuccess extends AuthState {
  final String message;
  const AuthSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final String message;
  final AuthMode mode;
  const AuthError(this.message, this.mode);
  @override
  List<Object?> get props => [message, mode];
}

class AuthOtpState extends AuthState {
  final String email;
  final String maskedEmail;
  final int resendIn;
  final int expiresIn;
  final int nonce;
  final bool isVerifying;
  final bool isResending;
  final String? error;
  final String? notice;

  const AuthOtpState({
    required this.email,
    required this.maskedEmail,
    required this.resendIn,
    required this.expiresIn,
    this.nonce = 0,
    this.isVerifying = false,
    this.isResending = false,
    this.error,
    this.notice,
  });

  AuthOtpState copyWith({
    String? maskedEmail,
    int? resendIn,
    int? expiresIn,
    int? nonce,
    bool? isVerifying,
    bool? isResending,
    String? error,
    String? notice,
  }) {
    return AuthOtpState(
      email: email,
      maskedEmail: maskedEmail ?? this.maskedEmail,
      resendIn: resendIn ?? this.resendIn,
      expiresIn: expiresIn ?? this.expiresIn,
      nonce: nonce ?? this.nonce,
      isVerifying: isVerifying ?? this.isVerifying,
      isResending: isResending ?? this.isResending,
      error: error,
      notice: notice,
    );
  }

  @override
  List<Object?> get props => [email, maskedEmail, resendIn, expiresIn, nonce, isVerifying, isResending, error, notice];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;
  AuthCubit({required this.repository}) : super(const AuthInitial(AuthMode.login));

  AuthMode get mode {
    final s = state;
    if (s is AuthInitial) return s.mode;
    if (s is AuthLoading) return s.mode;
    if (s is AuthError) return s.mode;
    if (s is AuthOtpState) return AuthMode.register;
    return AuthMode.login;
  }

  void setMode(AuthMode m) => emit(AuthInitial(m));

  Future<void> submit({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final currentMode = mode;
    if (email.isEmpty || !email.contains('@')) {
      emit(AuthError('Enter a valid email address', currentMode));
      return;
    }
    if (password.isEmpty) {
      emit(AuthError('Enter your password', currentMode));
      return;
    }
    if (currentMode == AuthMode.register && password.length < 8) {
      emit(AuthError('Password must be at least 8 characters', currentMode));
      return;
    }
    if (currentMode == AuthMode.register) {
      if (name.trim().isEmpty) {
        emit(AuthError('Enter your name', currentMode));
        return;
      }
      // Phone is optional for docs-compat (alternate body has no phone).
      // If provided, basic format check; if empty, allow - datasource will omit it
      // and server fallback avoids 500. Recommended flow still encourages phone.
      if (phone.trim().isNotEmpty && phone.trim().length < 8) {
        emit(AuthError('Enter a valid phone number', currentMode));
        return;
      }
      if (password != passwordConfirmation) {
        emit(AuthError('Passwords do not match', currentMode));
        return;
      }
    }

    emit(AuthLoading(currentMode));
    try {
      if (currentMode == AuthMode.register) {
        final res = await repository.sendRegistrationOtp(
          name: name.trim(),
          email: email.trim(),
          phone: phone.trim(),
          password: password,
          passwordConfirmation: passwordConfirmation,
        );
        final data = res.data ?? const <String, dynamic>{};
        emit(AuthOtpState(
          email: email.trim(),
          maskedEmail: (data['email'] as String?) ?? email.trim(),
          resendIn: (data['resend_in'] as num?)?.toInt() ?? 60,
          expiresIn: (data['expires_in'] as num?)?.toInt() ?? 600,
          notice: res.message,
        ));
      } else {
        final res = await repository.login(email: email.trim(), password: password);
        // token saved inside repo
        emit(AuthSuccess(res.message ?? 'Login successful'));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', ''), currentMode));
    }
  }

  Future<void> verifyOtp(String otp) async {
    final current = state;
    if (current is! AuthOtpState) return;

    final code = otp.trim();
    if (code.length != 6) {
      emit(current.copyWith(error: 'Enter the 6-digit verification code'));
      return;
    }

    emit(current.copyWith(isVerifying: true, error: null, notice: null));
    try {
      final res = await repository.verifyRegistrationOtp(email: current.email, otp: code);
      emit(AuthSuccess(res.message ?? 'Email verified successfully'));
    } catch (e) {
      emit(current.copyWith(
        isVerifying: false,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> resendOtp() async {
    final current = state;
    if (current is! AuthOtpState) return;

    emit(current.copyWith(isResending: true, error: null, notice: null));
    try {
      final res = await repository.resendRegistrationOtp(email: current.email);
      final data = res.data ?? const <String, dynamic>{};
      emit(AuthOtpState(
        email: current.email,
        maskedEmail: (data['email'] as String?) ?? current.maskedEmail,
        resendIn: (data['resend_in'] as num?)?.toInt() ?? 60,
        expiresIn: (data['expires_in'] as num?)?.toInt() ?? current.expiresIn,
        nonce: current.nonce + 1,
        notice: res.message ?? 'A new verification code has been sent.',
      ));
    } catch (e) {
      emit(current.copyWith(
        isResending: false,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  void changeEmail() {
    emit(const AuthInitial(AuthMode.register));
  }

  Future<void> forgotPassword(String email) async {
    final m = mode;
    if (email.isEmpty || !email.contains('@')) {
      emit(AuthError('Enter a valid email', m));
      return;
    }
    emit(AuthLoading(m));
    try {
      final res = await repository.forgotPassword(email.trim());
      emit(AuthSuccess(res.message ?? 'Reset link sent to email'));
      emit(AuthInitial(m)); // back to form
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', ''), m));
    }
  }

  Future<void> resendVerify(String email) async {
    final m = mode;
    emit(AuthLoading(m));
    try {
      final res = await repository.resendVerify(email.trim());
      emit(AuthSuccess(res.message ?? 'Verification email resent'));
      emit(AuthInitial(m));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', ''), m));
    }
  }

  Future<void> checkEmail(String email) async {
    try {
      await repository.checkEmail(email);
    } catch (_) {}
  }

  Future<void> socialLogin(String provider, String identityToken) async {
    final m = mode;
    final preview = identityToken.length > 24 ? '${identityToken.substring(0, 24)}... (len=${identityToken.length})' : identityToken;
    dev.log('[GoogleLogin][Cubit] start provider=$provider token=$preview', name: 'GoogleLogin');
    emit(AuthLoading(m));
    try {
      final res = await repository.socialLogin(provider, identityToken);
      dev.log('[GoogleLogin][Cubit] success message=${res.message}', name: 'GoogleLogin');
      emit(AuthSuccess(res.message ?? 'Login successful'));
    } catch (e, s) {
      dev.log('[GoogleLogin][Cubit] error throw: $e', name: 'GoogleLogin', error: e, stackTrace: s);
      emit(AuthError(e.toString().replaceAll('Exception: ', ''), m));
    }
  }
}
