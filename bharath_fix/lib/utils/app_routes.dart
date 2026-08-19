

import 'package:flutter/material.dart';

import '../features/Authentication/login_screen.dart';
import '../features/Authentication/otp_screen.dart';
import '../features/Authentication/register_screen.dart';
import '../features/Authentication/welcome_screen.dart';
import '../features/Dashboard/dashboard_screen.dart';
import '../features/Splash/splash_screen.dart';
import '../features/Bookings/booking_success_screen.dart';
import '../features/Bookings/order_success_screen.dart';
import '../models/OrderModel.dart';

class AppRoutes {
  static const splash = "/";

  static const welcome = "/welcome";
  static const register = "/register";
  static const login = "/login";
  static const otp = "/otp";
  static const dashboard = "/dashboard";
  static const home = "/dashboard";
  static const bookings = "/dashboard";
  static const bookingSuccess = "/booking-success";
  static const orderSuccess = "/order-success";

  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    welcome: (_) => const WelcomeScreen(),
    register: (_) => const RegisterScreen(),
    login: (_) => const LoginScreen(),
    otp: (_) => const OtpScreen(),
    dashboard: (_) => const DashboardScreen(),
    bookingSuccess: (_) => const BookingSuccessScreen(),
    orderSuccess: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is OrderModel) {
        return OrderSuccessScreen(order: args);
      }
      return OrderSuccessScreen(
        order: OrderModel(
          id: 'ORD_${DateTime.now().millisecondsSinceEpoch}',
          userId: '',
          userName: '',
          userPhone: '',
          userEmail: '',
          deliveryAddress: 'Default Address',
          productId: '',
          productName: 'Appliance Item',
          productImage: '',
          price: 0,
          totalPaid: 0,
          deliveryOtp: '5829',
        ),
      );
    },
  };
}
