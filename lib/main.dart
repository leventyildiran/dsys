import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/user_provider.dart';
import 'router.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const DSYSApp());
}

class DSYSApp extends StatefulWidget {
  const DSYSApp({super.key});

  @override
  State<DSYSApp> createState() => _DSYSAppState();
}

class _DSYSAppState extends State<DSYSApp> {
  late final AuthProvider _authProvider;
  late final UserProvider _userProvider;
  late final DashboardProvider _dashboardProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _userProvider = UserProvider(authProvider: _authProvider);
    _dashboardProvider = DashboardProvider();
    _router = AppRouter.router(_authProvider);
  }

  @override
  void dispose() {
    _dashboardProvider.dispose();
    _userProvider.dispose();
    _authProvider.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _userProvider),
        ChangeNotifierProvider.value(value: _dashboardProvider),
      ],
      child: MaterialApp.router(
        title: 'DSYS - Döner Sermaye Yönetim Sistemi',
        debugShowCheckedModeBanner: false,
        theme: DSYSTheme.lightTheme,
        darkTheme: DSYSTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}

