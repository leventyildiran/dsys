import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

/// DSYS uygulama yönlendirici yapılandırması.
///
/// Auth durumuna göre otomatik redirect uygular:
/// - Yükleme durumundaysa → splash
/// - Oturum açılmamışsa → login
/// - Oturum açılmışsa → dashboard
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (BuildContext context, GoRouterState state) {
        final isLoading = authProvider.isLoading;
        final isAuthenticated = authProvider.isAuthenticated;
        final currentLocation = state.matchedLocation;

        // Yükleme sırasında splash'ta kal
        if (isLoading) {
          return currentLocation == '/splash' ? null : '/splash';
        }

        // Oturum açılmamışsa login'e yönlendir
        if (!isAuthenticated) {
          return currentLocation == '/login' ? null : '/login';
        }

        // Oturum açıksa ve hala splash/login'deyse dashboard'a yönlendir
        if (currentLocation == '/splash' || currentLocation == '/login') {
          return '/dashboard';
        }

        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
      ],
    );
  }
}
