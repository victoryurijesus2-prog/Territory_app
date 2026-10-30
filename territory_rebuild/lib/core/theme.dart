import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFFF5722);
  static const Color primaryDark = Color(0xFFE64A19);
  static const Color secondary = Color(0xFF00BCD4);
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  static const List<String> territoryColors = [
    '#FF5722', '#2196F3', '#4CAF50', '#9C27B0',
    '#FF9800', '#00BCD4', '#F44336', '#795548',
    '#E91E63', '#009688', '#3F51B5', '#FFEB3B',
  ];

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark, primary: primary, secondary: secondary, surface: const Color(0xFF1A1A1A)),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black,
      cardColor: const Color(0xFF1E1E1E),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), iconTheme: IconThemeData(color: Colors.white)),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white30), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24))),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF2A2A2A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 2)), labelStyle: const TextStyle(color: Colors.white54), hintStyle: const TextStyle(color: Colors.white30)),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Color(0xFF1A1A1A), selectedItemColor: primary, unselectedItemColor: Colors.white38, type: BottomNavigationBarType.fixed),
    );
  }

  static ThemeData light() {
    return ThemeData(brightness: Brightness.light, colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light, primary: primary, secondary: secondary), useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF5F5F5));
  }
}
