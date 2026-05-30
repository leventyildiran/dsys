import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
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
          builder: (context, state) => const _DashboardPlaceholder(),
        ),
      ],
    );
  }
}

/// Dashboard ekranı için geçici placeholder widget.
/// Faz 2'de gerçek dashboard ile değiştirilecektir.
class _DashboardPlaceholder extends StatelessWidget {
  const _DashboardPlaceholder();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('DSYS - Döner Sermaye Yönetim Sistemi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () => authProvider.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Hoş Geldiniz!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              authProvider.user?.email ?? '',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
