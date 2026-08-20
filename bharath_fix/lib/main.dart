import 'package:bharath_fix/ui/theme/app_theme.dart';
import 'package:bharath_fix/utils/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:bharath_fix/services/database_service.dart';
import 'package:bharath_fix/services/notification_service.dart';
import 'package:bharath_fix/services/theme_service.dart';
import 'package:bharath_fix/services/language_service.dart';
import 'package:bharath_fix/services/auth_enforcement_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await ThemeService().init();
  await LanguageService().init();

  bool firebaseAvailable = false;
  try {
    await Firebase.initializeApp();
    firebaseAvailable = true;
    await NotificationService.initialize();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e. Operating in SQLite offline mode.");
  }

  final dbService = DatabaseService();
  dbService.setFirebaseAvailable(firebaseAvailable);
  
  if (firebaseAvailable) {
    await dbService.seedFirebaseIfEmpty();
  }
  // Prefetch profile to load the current session if user is already logged in

  await dbService.fetchProfile();

  AuthEnforcementService().startMonitoring();

  runApp(const MyApp());
}





class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService().themeModeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: "BharathFix",
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          navigatorKey: navigatorKey,
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}