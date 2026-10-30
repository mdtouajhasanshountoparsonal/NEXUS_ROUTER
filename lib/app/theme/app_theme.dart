import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.black,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: scheme,
      textTheme: _textTheme(AppColors.textPrimary, AppColors.textSecondary),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: _inputTheme(
        fill: AppColors.surface,
        border: AppColors.border,
        hint: AppColors.textTertiary,
        text: AppColors.textPrimary,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionColor: Color(0x55FF3B5C),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.border,
        circularTrackColor: AppColors.border,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceAlt,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.accent,
      onPrimary: Colors.white,
      secondary: AppColors.lightSecondary,
      onSecondary: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      error: AppColors.danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: scheme,
      textTheme: _textTheme(
        AppColors.lightTextPrimary,
        AppColors.lightTextSecondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.lightTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.lightTextSecondary,
        size: 20,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: _inputTheme(
        fill: AppColors.lightSurface,
        border: AppColors.lightBorder,
        hint: AppColors.lightTextTertiary,
        text: AppColors.lightTextPrimary,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionColor: Color(0x33FF3B5C),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.lightBorder,
        circularTrackColor: AppColors.lightBorder,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightTextPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }

  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color border,
    required Color hint,
    required Color text,
  }) {
    OutlineInputBorder outline(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: hint, fontSize: 14),
      prefixIconColor: hint,
      suffixIconColor: hint,
      border: outline(border),
      enabledBorder: outline(border),
      focusedBorder: outline(AppColors.accent, 1.4),
      errorBorder: outline(AppColors.danger),
      focusedErrorBorder: outline(AppColors.danger, 1.4),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 29,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.9,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(fontSize: 15, height: 1.4, color: primary),
      bodyMedium: TextStyle(fontSize: 13.5, height: 1.45, color: secondary),
      bodySmall: TextStyle(fontSize: 11.5, height: 1.35, color: secondary),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: primary,
      ),
      labelSmall: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: secondary,
      ),
    );
  }
}
