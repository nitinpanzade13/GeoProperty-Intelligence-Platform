import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme textTheme(Color fontColor) {
    return GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: fontColor),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: fontColor),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: fontColor),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: fontColor),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: fontColor),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: fontColor),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: fontColor),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fontColor),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: fontColor.withOpacity(0.7)),
      ),
    );
  }
}
