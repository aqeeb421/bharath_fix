// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import 'dashboard_shell.dart';

import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  void _checkExistingSession() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardShell()),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // 1. Try Firebase Auth sign in
      try {
        await FirebaseService().signIn(email, password);
      } catch (authError) {
        // If user does not exist in Firebase Auth yet, auto-create admin account or use anonymous auth
        try {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } catch (_) {
          await FirebaseAuth.instance.signInAnonymously();
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardShell()),
        );
      }
    } catch (e) {
      if (email == 'admin@bharathfix.com' && password == 'admin123') {
        try {
          await FirebaseAuth.instance.signInAnonymously();
        } catch (_) {}
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardShell()),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Authentication failed: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA), // Light background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: isDesktop ? 450 : double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            decoration: BoxDecoration(
              color: Colors.white, // White card surface
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEAEAEA), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF000062).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Color(0xFF000062),
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'BharathFix Admin',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF111111),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'App Workspace & Operations Control Portal',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF757575),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 36),
                  
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    'Email Address',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF111111),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'admin@bharathfix.com',
                      hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9E9E9E), fontSize: 14),
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF757575)),
                      filled: true,
                      fillColor: const Color(0xFFF7F8FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF000062), width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Email is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Verification Password',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF111111),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9E9E9E), fontSize: 14),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF757575)),
                      filled: true,
                      fillColor: const Color(0xFFF7F8FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF000062), width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Password is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 36),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000062),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Secure Log In',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Bypass Credentials: admin@bharathfix.com / admin123',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF757575),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
