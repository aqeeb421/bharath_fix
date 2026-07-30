import 'package:bharath_fix/ui/theme/app_theme.dart';
import 'package:bharath_fix/utils/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bharath_fix/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseAvailable = false;
  try {
    await Firebase.initializeApp();
    firebaseAvailable = true;
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "BharathFix",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}