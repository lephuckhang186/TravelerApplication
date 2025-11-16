import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/loading_screen.dart';
// import 'dart:async'; // Tạm thời comment vì không dùng Timer

void main() {
  runApp(
    DevicePreview(
      enabled: true, // Bật mô phỏng thiết bị
      builder: (context) => const MyApp(), // App chính của bạn
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoneyFlow - Smart Finance Tracker',
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      builder: (context, child) {
        // Use system/default text scaling without overriding
        return DevicePreview.appBuilder(context, child!);
      },
      locale: DevicePreview.locale(context),
      theme: _buildModernTheme(),
      home: const LoadingScreen(),
    );
  }

  ThemeData _buildModernTheme() {
    // Modern palette: clean white + purple accent (matching Settings)
    const primaryColor = Color(0xFF7B61FF); // Purple (Settings color)
    const secondaryColor = Color(0xFF9B7FFF); // Lighter purple accent
    const accentColor = Color(0xFFE8E0FF); // Soft purple for highlights
    const backgroundColor = Color(0xFFFFFFFF); // Pure white

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily, // Inter font - modern and clean
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        tertiary: accentColor,
        surface: backgroundColor,
        onSurface: Colors.black87,
        background: backgroundColor,
        onBackground: Colors.black87,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        // Modern typography scale matching the designs
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.43,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.33,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        color: Colors.white,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
