import 'dart:developer' as dev;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/google_sign_in_error.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/entities/user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _repo().getMe();
  }

  AuthRepositoryImpl _repo() => AuthRepositoryImpl(
        remote: AuthRemoteDataSourceImpl(dioClient: DioClient()),
        storage: TokenStorage(),
      );

  void _refresh() {
    setState(() {
      _userFuture = _repo().getMe();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final errStr = snapshot.error.toString().toLowerCase();
            final isUnauth = errStr.contains('unauthenticated') ||
                errStr.contains('unauthorized') ||
                errStr.contains('401') ||
                errStr.contains('unauth');
            if (isUnauth) {
              return _GuestProfileView(onLoginSuccess: _refresh);
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error.toString().replaceAll('Exception: ', ''),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          final user = snapshot.data!;
          final settings = user.settings;
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.transparent,
                        backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                            ? CachedNetworkImageProvider(user.avatar!)
                            : const AssetImage('assets/images/auth/user.png') as ImageProvider,
                      ),
                      const SizedBox(height: 12),
                      Text(user.name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(user.email, style: theme.textTheme.bodySmall),
                      if (user.phone != null && user.phone!.isNotEmpty)
                        Text(user.phone!, style: theme.textTheme.bodySmall),
                      if (user.description != null && user.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(user.description!, textAlign: TextAlign.center),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _Tile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: settings == null
                      ? null
                      : '${settings.language} · ${settings.theme ?? 'light'}',
                  onTap: () {},
                ),
                _Tile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: settings == null
                      ? null
                      : (settings.notificationEnabled ? 'On' : 'Off'),
                  onTap: () {},
                ),
                _Tile(icon: Icons.info_outline_rounded, title: 'About', onTap: () {}),
                const SizedBox(height: 16),
                _Tile(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  onTap: () async {
                    await _repo().logout();
                    if (context.mounted) context.go('/auth');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }
}

class _GuestProfileView extends StatelessWidget {
  final VoidCallback onLoginSuccess;
  const _GuestProfileView({required this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColors = theme.extension<AppCardColors>()!;
    final titleColor = cardColors.titleColor;
    final descColor = cardColors.descriptionColor;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hero image
            Image.asset(
              'assets/images/login_join_hero.png',
              height: 180,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.person_outline_rounded,
                size: 80,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Login to view\n your Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: titleColor,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sign in to see your details, manage settings and get a personalized experience.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: descColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            // Primary Login button
            Container(
              height: 52,
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 340),
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
                onPressed: () => context.go('/auth'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Icon(Icons.person_rounded, color: Colors.white, size: 22),
                      Spacer(),
                      Text(
                        'Login',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Spacer(),
                      Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Google button
            Container(
              height: 52,
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 340),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222238) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: descColor.withValues(alpha: 0.18)),
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
                    dev.log('[GoogleLogin][UI:Profile] Starting Google sign-in', name: 'GoogleLogin');
                    final googleSignIn = GoogleSignIn(
                      serverClientId: ApiConstants.googleServerClientId,
                    );
                    final googleUser = await googleSignIn.signIn();
                    if (googleUser == null) {
                      dev.log('[GoogleLogin][UI:Profile] User cancelled Google picker', name: 'GoogleLogin');
                      return;
                    }
                    dev.log('[GoogleLogin][UI:Profile] Google user: email=${googleUser.email} id=${googleUser.id}', name: 'GoogleLogin');
                    final googleAuth = await googleUser.authentication;
                    final idToken = googleAuth.idToken;
                    if (idToken == null) {
                      dev.log('[GoogleLogin][UI:Profile] ERROR: idToken is null. accessToken present=${googleAuth.accessToken != null}', name: 'GoogleLogin');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to get Google ID token')),
                        );
                      }
                      return;
                    }
                    dev.log('[GoogleLogin][UI:Profile] Got idToken ${idToken.substring(0, 20)}... (len=${idToken.length}), calling backend', name: 'GoogleLogin');
                    final dio = Injection.createDioClient();
                    final ds = AuthRemoteDataSourceImpl(dioClient: dio);
                    final repo = AuthRepositoryImpl(remote: ds, storage: TokenStorage());
                    await repo.socialLogin('google', idToken);
                    dev.log('[GoogleLogin][UI:Profile] Backend login success', name: 'GoogleLogin');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Login successful')),
                      );
                    }
                    onLoginSuccess();
                  } catch (e, s) {
                    dev.log('[GoogleLogin][UI:Profile] error throw: $e', name: 'GoogleLogin', error: e, stackTrace: s);
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
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
