import 'package:flutter/material.dart';
import '../../services/theme_service.dart';

class AppColors {
  // Light Theme Palette
  static const Color primary = Color(0xFF000062); // Theme Deep Navy #000062
  static const Color secondary = Color(0xFF1A1A80); // Secondary Blue
  static const Color accentGreen = Color(0xFFE8ECF8); // Soft accent tint
  static const Color statusPendingText = Color(0xFFFFB300);
  static const Color statusPendingBg = Color(0xFFFFF8E1);

  // Stitch Dark Theme Palette
  static const Color darkBackground = Color(0xFF0B0E17); // Obsidian Dark Canvas
  static const Color darkCard = Color(0xFF141A29); // Deep Slate Card Surface
  static const Color darkCardElevated = Color(0xFF1E263B); // Elevated Card Surface
  static const Color darkBorder = Color(0xFF2A354F); // Muted Border
  static const Color darkTitle = Color(0xFFF8FAFC); // Crisp Light Title Text
  static const Color darkSubtitle = Color(0xFF94A3B8); // Muted Ice Slate Subtitle
  static const Color darkPrimary = Color(0xFF2563EB); // Vibrant Neon Electric Blue
  static const Color darkSecondary = Color(0xFF3B82F6); // Secondary Blue Accent

  // Dynamic Theme Colors (Auto-adapts to ThemeService.isDarkMode state!)
  static Color get background => ThemeService().isDarkMode ? darkBackground : Colors.white;
  static Color get card => ThemeService().isDarkMode ? darkCard : const Color(0xFFF7F8FA);
  static Color get border => ThemeService().isDarkMode ? darkBorder : const Color(0xFFEAEAEA);
  static Color get title => ThemeService().isDarkMode ? darkTitle : const Color(0xFF111111);
  static Color get subtitle => ThemeService().isDarkMode ? darkSubtitle : const Color(0xFF757575);
}