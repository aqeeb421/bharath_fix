

import 'package:flutter/material.dart';

import '../features/Authentication/login_screen.dart';
import '../features/Authentication/otp_screen.dart';
import '../features/Authentication/register_screen.dart';
import '../features/Authentication/welcome_screen.dart';
import '../features/Dashboard/dashboard_screen.dart';
import '../features/Splash/splash_screen.dart';
import '../features/Bookings/booking_success_screen.dart';

class AppRoutes {
  static const splash = "/";

  static const welcome = "/welcome";
  static const register = "/register";
  static const login = "/login";
  static const otp = "/otp";
  static const dashboard = "/dashboard";
  static const bookingSuccess = "/booking-success";

  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    welcome: (_) => const WelcomeScreen(),
    register: (_) => const RegisterScreen(),
    login: (_) => const LoginScreen(),
    otp: (_) => const OtpScreen(),
    dashboard: (_) => const DashboardScreen(),
    bookingSuccess: (_) => const BookingSuccessScreen(),
  };
}
