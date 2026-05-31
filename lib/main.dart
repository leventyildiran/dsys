import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/butce_aktarim_provider.dart';
import 'providers/butce_takip_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/dis_hekimligi_provider.dart';
import 'providers/ek_odeme_provider.dart';
import 'providers/evrak_arsiv_provider.dart';
import 'providers/fatura_provider.dart';
import 'providers/gundem_provider.dart';
import 'providers/raporlama_provider.dart';
import 'providers/taksit_provider.dart';
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
  late final TaksitProvider _taksitProvider;
  late final ButceAktarimProvider _butceAktarimProvider;
  late final EkOdemeProvider _ekOdemeProvider;
  late final DisHekimligiProvider _disHekimligiProvider;
  late final GundemProvider _gundemProvider;
  late final RaporlamaProvider _raporlamaProvider;
  late final EvrakArsivProvider _evrakArsivProvider;
  late final FaturaProvider _faturaProvider;
  late final ButceTakipProvider _butceTakipProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _userProvider = UserProvider(authProvider: _authProvider);
    _dashboardProvider = DashboardProvider();
    _taksitProvider = TaksitProvider();
    _butceAktarimProvider = ButceAktarimProvider();
    _ekOdemeProvider = EkOdemeProvider();
    _disHekimligiProvider = DisHekimligiProvider();
    _gundemProvider = GundemProvider();
    _raporlamaProvider = RaporlamaProvider();
    _evrakArsivProvider = EvrakArsivProvider();
    _faturaProvider = FaturaProvider();
    _butceTakipProvider = ButceTakipProvider();
    _router = AppRouter.router(_authProvider);
  }

  @override
  void dispose() {
    _butceTakipProvider.dispose();
    _faturaProvider.dispose();
    _evrakArsivProvider.dispose();
    _raporlamaProvider.dispose();
    _gundemProvider.dispose();
    _disHekimligiProvider.dispose();
    _ekOdemeProvider.dispose();
    _butceAktarimProvider.dispose();
    _taksitProvider.dispose();
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
        ChangeNotifierProvider.value(value: _taksitProvider),
        ChangeNotifierProvider.value(value: _butceAktarimProvider),
        ChangeNotifierProvider.value(value: _ekOdemeProvider),
        ChangeNotifierProvider.value(value: _disHekimligiProvider),
        ChangeNotifierProvider.value(value: _gundemProvider),
        ChangeNotifierProvider.value(value: _raporlamaProvider),
        ChangeNotifierProvider.value(value: _evrakArsivProvider),
        ChangeNotifierProvider.value(value: _faturaProvider),
        ChangeNotifierProvider.value(value: _butceTakipProvider),
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

