import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home.dart';
import 'screens/onboarding.dart';
import 'services/app_state.dart';
import 'services/notifications.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: C.ink,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await app.init();
  await Notifs.init();
  runApp(const SipsakApp());
  Notifs.scheduleWeek();
}

class SipsakApp extends StatelessWidget {
  const SipsakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Şipşak',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: ListenableBuilder(
        listenable: app,
        builder: (context, _) => app.onboarded ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }
}
