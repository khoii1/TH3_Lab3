import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.deepOrange,
      scaffoldBackgroundColor: const Color(0xFFF7F5F2),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }
}
