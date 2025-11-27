import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TripWise App Theme - Palette: Trắng & Xanh Ngọc Bích
///
/// Color Palette:
/// - Primary (Main Brand): #40E0D0 (Turquoise - Xanh ngọc bích)
/// - Secondary: #2E8B8B (Dark Turquoise - Xanh ngọc bích đậm)  
/// - Support (Borders/Dividers): #B0E0E6 (Powder Blue - Xanh nhạt)
/// - Background: #FFFFFF (White - Trắng)
/// - Surface: #F8FFFF (Ghost White - Trắng kem nhẹ)
/// - Text Primary: #2E8B8B (Dark Turquoise cho text chính)
/// - Text Secondary: #5F9EA0 (Cadet Blue cho text phụ)
/// - Success: #20B2AA (Light Sea Green)
/// - Warning/Error: #FF6B6B (Light Coral)

class AppColors {
  // Primary Colors - Màu chủ đạo
  static const Color primary = Color(0xFF40E0D0); // Turquoise - Xanh ngọc bích
  static const Color secondary = Color(0xFF2E8B8B); // Dark Turquoise - Xanh ngọc bích đậm
  static const Color accent = Color(0xFF40E0D0); // Turquoise - Accent giống primary
  static const Color support = Color(0xFFB0E0E6); // Powder Blue - Xanh nhạt cho borders
  static const Color background = Color(0xFFFFFFFF); // White - Trắng
  static const Color surface = Color(0xFFF8FFFF); // Ghost White - Trắng kem nhẹ

  // Text Colors - Màu chữ
  static const Color textPrimary = Color(0xFF2E8B8B); // Dark Turquoise cho text chính
  static const Color textSecondary = Color(0xFF5F9EA0); // Cadet Blue cho text phụ
  static const Color textOnAccent = Color(0xFFFFFFFF); // White text trên accent

  // Status Colors - Màu trạng thái
  static const Color success = Color(0xFF20B2AA); // Light Sea Green
  static const Color warning = Color(0xFFFF6B6B); // Light Coral

  // Interactive States - Trạng thái tương tác
  static const Color accentHover = Color(0xFF3CCCC0); // Darker turquoise for hover
  static const Color accentPressed = Color(0xFF2EB8B8); // Even darker for pressed

  // Chart Colors - Màu biểu đồ (hài hòa với palette)
  static const List<Color> chartColors = [
    primary, // #40E0D0 - Turquoise
    secondary, // #2E8B8B - Dark Turquoise  
    success, // #20B2AA - Light Sea Green
    Color(0xFF48D1CC), // Medium Turquoise
    Color(0xFF00CED1), // Dark Turquoise
    warning, // #FF6B6B - Light Coral
  ];
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.quattrocento().fontFamily,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnAccent,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textOnAccent,
        tertiary: AppColors.support,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.warning,
        onError: AppColors.textOnAccent,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.background,

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.quattrocento(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // Text Theme
      textTheme: GoogleFonts.quattrocentoTextTheme().copyWith(
        // Display styles
        displayLarge: GoogleFonts.quattrocento(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.quattrocento(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          color: AppColors.textPrimary,
        ),

        // Headline styles
        headlineLarge: GoogleFonts.quattrocento(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.quattrocento(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        // Title styles
        titleLarge: GoogleFonts.quattrocento(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.quattrocento(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        titleSmall: GoogleFonts.quattrocento(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),

        // Body styles
        bodyLarge: GoogleFonts.quattrocento(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.quattrocento(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.43,
          color: AppColors.textPrimary,
        ),
        bodySmall: GoogleFonts.quattrocento(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.33,
          color: AppColors.textSecondary,
        ),

        // Label styles
        labelLarge: GoogleFonts.quattrocento(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: AppColors.textPrimary,
        ),
        labelMedium: GoogleFonts.quattrocento(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: AppColors.textSecondary,
        ),
        labelSmall: GoogleFonts.quattrocento(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: AppColors.textSecondary,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnAccent,
              elevation: 3,
              shadowColor: AppColors.primary.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              textStyle: GoogleFonts.quattrocento(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ).copyWith(
              // Hover state
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return AppColors.accentHover;
                }
                if (states.contains(WidgetState.pressed)) {
                  return AppColors.accentPressed;
                }
                return AppColors.primary;
              }),
            ),
      ),

      textButtonTheme: TextButtonThemeData(
        style:
            TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: GoogleFonts.quattrocento(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ).copyWith(
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return AppColors.accentHover;
                }
                return AppColors.primary;
              }),
            ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: GoogleFonts.quattrocento(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      // Input Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.support),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.support),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.warning),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.warning, width: 2),
        ),
        labelStyle: GoogleFonts.quattrocento(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.quattrocento(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.support,
        thickness: 1,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: AppColors.textPrimary),

      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(color: AppColors.textOnAccent),
    );
  }
}
