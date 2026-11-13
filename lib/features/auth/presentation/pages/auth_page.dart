import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/google_sign_in_error.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../cubit/auth_cubit.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final dio = Injection.createDioClient();
        final ds = AuthRemoteDataSourceImpl(dioClient: dio);
        final repo = AuthRepositoryImpl(remote: ds, storage: TokenStorage());
        return AuthCubit(repository: repo);
      },
      child: const _AuthView(),
    );
  }
}

class _AuthView extends StatefulWidget {
  const _AuthView();

  @override
  State<_AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<_AuthView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(text: '');
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _goToMain() {
    if (!mounted) return;
    // Use GoRouter directly to avoid context lookup issues inside BlocConsumer
    GoRouter.of(context).go('/home');
  }

  void _showForgotSheet() {
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cardColors = theme.extension<AppCardColors>()!;
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
            left: 24,
            right: 24,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cardColors.descriptionColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Forgot Password',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cardColors.titleColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your email address to receive a password reset link.',
                style: TextStyle(
                  fontSize: 14,
                  color: cardColors.descriptionColor,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _capsuleDec(ctx, 'Email Address', Icons.mail_outline_rounded),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () async {
                    final cubit = context.read<AuthCubit>();
                    await cubit.forgotPassword(emailCtrl.text);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Send Reset Link',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    final cubit = context.read<AuthCubit>();
                    await cubit.resendVerify(emailCtrl.text);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(
                    'Resend Verification Email',
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColors = theme.extension<AppCardColors>()!;
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          final msg = state.message.toLowerCase();
          if (msg.contains('registered')) {
            context.read<AuthCubit>().setMode(AuthMode.login);
          } else if (msg.contains('reset link') ||
              msg.contains('resend') ||
              msg.contains('verification') ||
              msg.contains('emailed')) {
            context.read<AuthCubit>().setMode(context.read<AuthCubit>().mode);
          } else {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _goToMain();
            });
          }
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      builder: (context, state) {
        final mode = context.read<AuthCubit>().mode;
        final isLogin = mode == AuthMode.login;
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: primaryColor,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Header Banner (Reference Matching)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Skip Button Header
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _goToMain,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Skip',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLogin ? 'Sign In' : 'Create Account',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isLogin
                                  ? 'Welcome back! Sign in to continue reading Makkal Velicham Tamil news.'
                                  : 'Join Makkal Velicham to bookmark stories and participate in news discussions.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.88),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Curved White / Dark Body Container
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (!isLogin) ...[
                                  TextFormField(
                                    controller: _nameCtrl,
                                    textCapitalization: TextCapitalization.words,
                                    decoration: _capsuleDec(context, 'Full Name', Icons.person_outline_rounded),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    decoration: _capsuleDec(context, 'Phone Number (Optional)', Icons.phone_outlined),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _capsuleDec(context, 'Email Address', Icons.mail_outline_rounded),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _obscure,
                                  decoration: _capsuleDec(context, 'Password', Icons.lock_outline_rounded).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        size: 20,
                                        color: cardColors.descriptionColor,
                                      ),
                                      onPressed: () => setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                ),
                                if (!isLogin) ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _confirmCtrl,
                                    obscureText: _obscureConfirm,
                                    decoration: _capsuleDec(context, 'Confirm Password', Icons.lock_outline_rounded).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                          size: 20,
                                          color: cardColors.descriptionColor,
                                        ),
                                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),

                                // Forgot Password Link
                                if (isLogin)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _showForgotSheet,
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: cardColors.descriptionColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        if (_emailCtrl.text.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Please enter email address first')),
                                          );
                                          return;
                                        }
                                        context.read<AuthCubit>().resendVerify(_emailCtrl.text);
                                      },
                                      child: Text(
                                        'Resend Verification?',
                                        style: TextStyle(
                                          color: cardColors.descriptionColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 16),

                                // Primary Pill Button (Sign in / Create Account)
                                SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? primaryColor : Colors.black,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: const StadiumBorder(),
                                    ),
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            FocusScope.of(context).unfocus();
                                            context.read<AuthCubit>().submit(
                                                  name: _nameCtrl.text,
                                                  email: _emailCtrl.text,
                                                  phone: _phoneCtrl.text,
                                                  password: _passCtrl.text,
                                                  passwordConfirmation: isLogin ? _passCtrl.text : _confirmCtrl.text,
                                                );
                                          },
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                          )
                                        : Text(
                                            isLogin ? 'Sign in' : 'Create Account',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Mode Switcher Button (Register / Sign In) below Sign In button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isLogin ? "Don't have an account? " : "Already have an account? ",
                                      style: TextStyle(
                                        color: cardColors.descriptionColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        final nextMode = isLogin ? AuthMode.register : AuthMode.login;
                                        context.read<AuthCubit>().setMode(nextMode);
                                      },
                                      child: Text(
                                        isLogin ? 'Register' : 'Sign In',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                if (isLogin) ...[
                                  const SizedBox(height: 10),
                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        if (_emailCtrl.text.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Enter email address to check')),
                                          );
                                          return;
                                        }
                                        context.read<AuthCubit>().checkEmail(_emailCtrl.text);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Checking email registration status...')),
                                        );
                                      },
                                      child: Text(
                                        'Check if email exists',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: cardColors.descriptionColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 28),

                                // Clay Style Google Sign In Button (Centered, Larger 3D Google Icon, No Arrow)
                                _SocialPillButton(
                                  icon: Image.asset(
                                    'assets/images/auth/google_sign_in.png',
                                    height: 36,
                                    width: 36,
                                    fit: BoxFit.contain,
                                    errorBuilder: (ctx, err, stack) => const Icon(
                                      Icons.g_mobiledata_rounded,
                                      color: Color(0xFF4285F4),
                                      size: 34,
                                    ),
                                  ),
                                  label: 'Continue with Google',
                                  onPressed: () async {
                                    try {
                                      dev.log('[GoogleLogin][UI:AuthPage] Starting Google sign-in', name: 'GoogleLogin');
                                      final googleSignIn = GoogleSignIn(
                                        serverClientId: ApiConstants.googleServerClientId,
                                      );
                                      final googleUser = await googleSignIn.signIn();
                                      if (googleUser == null) {
                                        dev.log('[GoogleLogin][UI:AuthPage] User cancelled Google picker', name: 'GoogleLogin');
                                        return;
                                      }
                                      dev.log('[GoogleLogin][UI:AuthPage] Google user: email=${googleUser.email} id=${googleUser.id}', name: 'GoogleLogin');

                                      final googleAuth = await googleUser.authentication;
                                      final idToken = googleAuth.idToken;
                                      if (idToken == null) {
                                        dev.log('[GoogleLogin][UI:AuthPage] ERROR: idToken is null. accessToken present=${googleAuth.accessToken != null}', name: 'GoogleLogin');
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Failed to get Google ID token')),
                                          );
                                        }
                                        return;
                                      }
                                      dev.log('[GoogleLogin][UI:AuthPage] Got idToken ${idToken.substring(0, 20)}... (len=${idToken.length}), calling backend', name: 'GoogleLogin');

                                      if (context.mounted) {
                                        context.read<AuthCubit>().socialLogin('google', idToken);
                                      }
                                    } catch (e, s) {
                                      dev.log('[GoogleLogin][UI:AuthPage] error throw: $e', name: 'GoogleLogin', error: e, stackTrace: s);
                                      if (e is ArgumentError) return;
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(friendlyGoogleSignInMessage(e))),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static InputDecoration _capsuleDec(BuildContext context, String hint, IconData icon) {
    final theme = Theme.of(context);
    final cardColors = theme.extension<AppCardColors>()!;
    final isDark = theme.brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: cardColors.descriptionColor.withValues(alpha: 0.5),
        fontSize: 14,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 10),
        child: Icon(icon, size: 20, color: cardColors.descriptionColor.withValues(alpha: 0.7)),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 46),
      filled: true,
      fillColor: isDark
          ? theme.colorScheme.surface
          : cardColors.descriptionColor.withValues(alpha: 0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}

class _SocialPillButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialPillButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColors = theme.extension<AppCardColors>()!;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E32) : const Color(0xFFF3F5FC),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
          width: 2,
        ),
        boxShadow: [
          // Volumetric Claymorphism drop shadow
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : const Color(0xFF98A6B8).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
          // Top light highlight shadow for 3D clay effect
          BoxShadow(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white,
            blurRadius: 10,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cardColors.titleColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
