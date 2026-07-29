import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {

  static const Color indigo      = Color(0xFF4F46E5);
  static const Color indigoDeep  = Color(0xFF3730A3);
  static const Color indigoSoft  = Color(0xFFEEF2FF);

  static const Color emerald     = Color(0xFF059669);
  static const Color emeraldSoft = Color(0xFFECFDF5);

  static const Color amber       = Color(0xFFD97706);
  static const Color amberSoft   = Color(0xFFFFFBEB);

  static const Color rose        = Color(0xFFE11D48);
  static const Color roseSoft    = Color(0xFFFFF1F2);

  static const Color sky         = Color(0xFF0284C7);
  static const Color skySoft     = Color(0xFFE0F2FE);

  static const Color violet      = Color(0xFF7C3AED);
  static const Color violetSoft  = Color(0xFFF5F3FF);


  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: indigo,
      onPrimary: Colors.white,
      secondary: emerald,
      onSecondary: Colors.white,
      error: rose,
      onError: Colors.white,
      background: const Color(0xFFF7F8FC),
      onBackground: const Color(0xFF0F0F23),
      surface: Colors.white,
      onSurface: const Color(0xFF0F0F23),
      surfaceVariant: const Color(0xFFF1F2F8),
      onSurfaceVariant: const Color(0xFF64748B),
      outline: const Color(0xFFE2E5F0),
    ),
    scaffoldBackgroundColor: const Color(0xFFF7F8FC),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: const TextStyle(
        color: Color(0xFF0F0F23),
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF0F0F23), size: 22),
      shape: Border(bottom: BorderSide(color: const Color(0xFFE2E5F0), width: 0.5)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E5F0), width: 0.5),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: indigo,
      unselectedItemColor: Color(0xFF94A3B8),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F2F8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: indigo, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: rose, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      hintStyle: const TextStyle(color: Color(0xFFB0BAD0), fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: indigo,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xFFE2E5F0)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: indigo),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: indigo,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFE2E5F0), thickness: 0.5, space: 0),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF1F2F8),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
  );

  // ── Dark theme ────────────────────────────────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFF818CF8),
      onPrimary: const Color(0xFF1E1B4B),
      secondary: const Color(0xFF34D399),
      onSecondary: const Color(0xFF064E3B),
      error: const Color(0xFFFB7185),
      onError: const Color(0xFF4C0519),
      background: const Color(0xFF09090F),
      onBackground: const Color(0xFFF1F5F9),
      surface: const Color(0xFF12121E),
      onSurface: const Color(0xFFF1F5F9),
      surfaceVariant: const Color(0xFF1E1E30),
      onSurfaceVariant: const Color(0xFF94A3B8),
      outline: const Color(0xFF1E2035),
    ),
    scaffoldBackgroundColor: const Color(0xFF09090F),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF12121E),
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: const TextStyle(
        color: Color(0xFFF1F5F9),
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: Color(0xFFF1F5F9), size: 22),
      shape: Border(bottom: BorderSide(color: const Color(0xFF1E2035), width: 0.5)),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF12121E),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1E2035), width: 0.5),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF12121E),
      selectedItemColor: Color(0xFF818CF8),
      unselectedItemColor: Color(0xFF475569),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E30),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E2035), width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF818CF8),
        foregroundColor: const Color(0xFF1E1B4B),
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF818CF8),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xFF1E2035)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF818CF8),
      foregroundColor: Color(0xFF1E1B4B),
      elevation: 4,
      shape: CircleBorder(),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFF1E2035), thickness: 0.5, space: 0),
  );

  // ── Semantic color helpers ─────────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status) {
      case 'overdue': return rose;
      case 'urgent': return amber;
      case 'done': return emerald;
      default: return sky;
    }
  }
}
