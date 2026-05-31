import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/butce_aktarim/butce_aktarim_screen.dart';
import 'screens/butce_takip/butce_takip_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/dis_hekimligi/dis_hekimligi_screen.dart';
import 'screens/ek_odeme/ek_odeme_screen.dart';
import 'screens/evrak_arsiv/evrak_arsiv_screen.dart';
import 'screens/fatura/fatura_screen.dart';
import 'screens/gundem/gundem_screen.dart';
import 'screens/login_screen.dart';
import 'screens/raporlama/raporlama_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/taksit/taksit_onay_screen.dart';

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
        GoRoute(
          path: '/taksit-onay/:danismanlikId',
          builder: (context, state) {
            final danismanlikId = state.pathParameters['danismanlikId']!;
            return TaksitOnayScreen(danismanlikId: danismanlikId);
          },
        ),
        // Modül 2: Bütçe Aktarımları
        GoRoute(
          path: '/butce-aktarim',
          builder: (context, state) => const ButceAktarimScreen(),
        ),
        // Modül 3: Dönemsel Ek Ödeme
        GoRoute(
          path: '/ek-odeme',
          builder: (context, state) => const EkOdemeScreen(),
        ),
        // Modül 4: Diş Hekimliği Katkı Payı
        GoRoute(
          path: '/dis-hekimligi',
          builder: (context, state) => const DisHekimligiScreen(),
        ),
        // Modül 5: Toplantı Gündem Derleyici
        GoRoute(
          path: '/gundem',
          builder: (context, state) => const GundemScreen(),
        ),
        // Modül 6: Raporlama ve Arşivleme
        GoRoute(
          path: '/raporlama',
          builder: (context, state) => const RaporlamaScreen(),
        ),
        // Modül 7: Evrak Arşivi
        GoRoute(
          path: '/evrak-arsiv',
          builder: (context, state) => const EvrakArsivScreen(),
        ),
        // Modül 8: Fatura Basım
        GoRoute(
          path: '/fatura',
          builder: (context, state) => const FaturaScreen(),
        ),
        // Modül 9: Bütçe Ödenek Takibi
        GoRoute(
          path: '/butce-takip',
          builder: (context, state) => const ButceTakipScreen(),
        ),
      ],
    );
  }
}
