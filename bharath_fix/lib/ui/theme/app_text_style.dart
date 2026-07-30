import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyle {
  static TextStyle heading = GoogleFonts.plusJakartaSans(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: AppColors.title,
  );

  static TextStyle title = GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.title,
  );


  static TextStyle body = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    color: AppColors.title,
  );

  static TextStyle button = GoogleFonts.plusJakartaSans(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle mainTitle = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.bold,
    fontSize: 24,
    color: AppColors.title,
    letterSpacing: -0.5,
  );

  static const TextStyle sectionHeader = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.bold,
    fontSize: 18,
    color: AppColors.title,
    letterSpacing: -0.3,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.bold,
    fontSize: 14,
    color: AppColors.title,
  );

  static const TextStyle bodyBold = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: AppColors.title,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.w500,
    fontSize: 14,
    color: AppColors.title,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.w500,
    fontSize: 13,
    color: AppColors.subtitle,
  );
}