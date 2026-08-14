import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyle {
  static TextStyle get heading => GoogleFonts.plusJakartaSans(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: AppColors.title,
  );

  static TextStyle get title => GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.title,
  );

  static TextStyle get body => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    color: AppColors.title,
  );

  static TextStyle get button => GoogleFonts.plusJakartaSans(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get mainTitle => TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.bold,
    fontSize: 24,
    color: AppColors.title,
    letterSpacing: -0.5,
  );

  static TextStyle get sectionHeader => TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.bold,
    fontSize: 18,
    color: AppColors.title,
    letterSpacing: -0.3,
  );

  static TextStyle get cardTitle => TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.bold,
    fontSize: 14,
    color: AppColors.title,
  );

  static TextStyle get bodyBold => TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: AppColors.title,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.w500,
    fontSize: 14,
    color: AppColors.title,
  );

  static TextStyle get subtitle => TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.w500,
    fontSize: 13,
    color: AppColors.subtitle,
  );
}