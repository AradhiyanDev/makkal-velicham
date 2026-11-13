import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/utils/google_sign_in_error.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';

class LoginPromptBottomSheet extends StatelessWidget {
  const LoginPromptBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LoginPromptBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF181828) : Colors.white;
    final cardBg = isDark ? const Color(0xFF222238) : const Color(0xFFF8F9FE);
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final descColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 32),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: descColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: descColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, size: 18, color: descColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Header Section with 3D Hero Character Asset (login_join_hero.png)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Login to\nUnlock More!',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: titleColor,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be a part of our community and enjoy a better news experience.',
                          style: TextStyle(
                            fontSize: 12,
                            color: descColor,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 9,
                    child: Image.asset(
                      'assets/images/login_join_hero.png',
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
              const SizedBox(height:1),

              // Inner Feature Grid Card using Provided 3D Icons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: descColor.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ImageAssetFeatureItem(
                            imageAsset: 'assets/images/like.png',
                            title: 'Like',
                            subtitle: 'Show your support for the news you love.',
                            titleColor: titleColor,
                            descColor: descColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ImageAssetFeatureItem(
                            imageAsset: 'assets/images/comment.png',
                            title: 'Comment',
                            subtitle: 'Share your thoughts and join the discussion.',
                            titleColor: titleColor,
                            descColor: descColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ImageAssetFeatureItem(
                            imageAsset: 'assets/images/feeds_on_your_intrest.png',
                            title: 'Feeds on Your Interest',
                            subtitle: 'Get personalized news based on what you care about.',
                            titleColor: titleColor,
                            descColor: descColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ImageAssetFeatureItem(
                            imageAsset: 'assets/images/latest_news_only.png',
                            title: 'Latest News Only',
                            subtitle: 'Avoid already seen news and get fresh, latest updates.',
                            titleColor: titleColor,
                            descColor: descColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              // 1. Primary Gradient Login Button
              Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/auth');
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Icon(Icons.person_rounded, color: Colors.white, size: 22),
                        Spacer(),
                        Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Google Login Button
              Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF222238) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: descColor.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    try {
                      dev.log('[GoogleLogin][UI:BottomSheet] Starting Google sign-in', name: 'GoogleLogin');
                      final googleSignIn = GoogleSignIn(
                        serverClientId: ApiConstants.googleServerClientId,
                      );
                      final googleUser = await googleSignIn.signIn();
                      if (googleUser == null) {
                        dev.log('[GoogleLogin][UI:BottomSheet] User cancelled Google picker', name: 'GoogleLogin');
                        return;
                      }
                      dev.log('[GoogleLogin][UI:BottomSheet] Google user: email=${googleUser.email} id=${googleUser.id}', name: 'GoogleLogin');
                      final googleAuth = await googleUser.authentication;
                      final idToken = googleAuth.idToken;
                      if (idToken == null) {
                        dev.log('[GoogleLogin][UI:BottomSheet] ERROR: idToken is null. accessToken present=${googleAuth.accessToken != null}', name: 'GoogleLogin');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to get Google ID token')),
                          );
                        }
                        return;
                      }
                      dev.log('[GoogleLogin][UI:BottomSheet] Got idToken ${idToken.substring(0, 20)}... (len=${idToken.length}), calling backend', name: 'GoogleLogin');
                      final dio = Injection.createDioClient();
                      final ds = AuthRemoteDataSourceImpl(dioClient: dio);
                      final repo = AuthRepositoryImpl(remote: ds, storage: TokenStorage());
                      await repo.socialLogin('google', idToken);
                      dev.log('[GoogleLogin][UI:BottomSheet] Backend login success', name: 'GoogleLogin');
                      if (context.mounted) {
                        Navigator.pop(context);
                        context.go('/home');
                      }
                    } catch (e, s) {
                      dev.log('[GoogleLogin][UI:BottomSheet] error throw: $e', name: 'GoogleLogin', error: e, stackTrace: s);
                      if (e is ArgumentError) return;
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(friendlyGoogleSignInMessage(e))),
                        );
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/auth/google_sign_in.png',
                          height: 24,
                          width: 24,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.g_mobiledata_rounded,
                            color: Color(0xFF4285F4),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageAssetFeatureItem extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color descColor;

  const _ImageAssetFeatureItem({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.descColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: Image.asset(
            imageAsset,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: descColor,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
