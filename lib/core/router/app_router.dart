import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../di/injection.dart';
import '../../features/news/presentation/bloc/news_event.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../navigation/main_shell.dart';
import '../storage/token_storage.dart';

abstract class AppRoutes {
  static const onboarding = '/';
  static const auth = '/auth';
  static const home = '/home';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.onboarding,
  routes: [
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (context, state) => const OnboardingPage(),
      redirect: (context, state) async {
        final hasToken = await TokenStorage().hasToken();
        if (hasToken) {
          return AppRoutes.home;
        }
        return null; // show onboarding
      },
    ),
    GoRoute(
      path: AppRoutes.auth,
      name: 'auth',
      builder: (context, state) => const AuthPage(),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => BlocProvider(
        create: (_) => Injection.createNewsBloc()..add(const FetchNews()),
        child: const MainShell(),
      ),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Route not found: ${state.uri}')),
  ),
);
