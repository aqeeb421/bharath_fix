import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pending_verification_screen.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('NotificationService initialization error: $e');
  }
  runApp(const TechnicianApp());
}

class TechnicianApp extends StatelessWidget {
  const TechnicianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BharathFix Partner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }
          final user = authSnapshot.data;
          if (user == null) {
            return const LoginScreen();
          }

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('providers').doc(user.uid).snapshots(),
            builder: (context, docSnapshot) {
              if (docSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                );
              }

              final data = docSnapshot.data?.data() ?? {};
              final statusRaw = (data['status'] ?? 'pending_verification').toString().trim().toLowerCase();
              final bool isApproved = statusRaw == 'active' || statusRaw == 'approved' || statusRaw == 'verified';

              if (isApproved) {
                return const DashboardScreen();
              } else {
                return const PendingVerificationScreen();
              }
            },
          );
        },
      ),
    );
  }
}
