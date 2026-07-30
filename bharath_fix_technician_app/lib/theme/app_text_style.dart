import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyle {
  static TextStyle get mainTitle => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.title,
      );

  static TextStyle get sectionHeader => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.title,
      );

  static TextStyle get cardTitle => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.title,
      );

  static TextStyle get subtitle => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.subtitle,
      );

  static TextStyle get buttonText => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );
}
