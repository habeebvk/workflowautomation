import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => LightTheme.theme;
  static ThemeData get dark => DarkTheme.theme;
}

/* =======================
   🌞 LIGHT THEME
======================= */
class LightTheme {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,

      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.lightGreen,
        brightness: Brightness.light,

        // ✅ PRIMARY COLOR FOR LIGHT MODE
        primary: Colors.black,
        onPrimary: Colors.white,
      ),

      scaffoldBackgroundColor: Colors.white,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.lightGreen,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      iconTheme: const IconThemeData(color: Colors.black),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.lightGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.black),
        bodyLarge: TextStyle(color: Colors.black),
      ),
    );
  }
}

/* =======================
   🌙 DARK THEME
======================= */
class DarkTheme {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,

      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.lightGreen,
        brightness: Brightness.dark,

        // ✅ PRIMARY COLOR FOR DARK MODE
        primary: Colors.white,
        onPrimary: Colors.black,
      ),

      scaffoldBackgroundColor: Colors.black,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      iconTheme: const IconThemeData(color: Colors.white),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.lightGreen,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
      ),
    );
  }
}
