import 'package:flutter/material.dart';

class SafeRoadTheme {
  // Brand Colors
  static const Color primary = Color(0xFF000080); // Navy Blue
  static const Color secondary = Color(0xFF000000); // Black
  static const Color background = Color(0xFFFFFFFF); // White
  static const Color surface = Color(0xFFF5F5F5); // Light Gray
  static const Color error = Color(0xFFB00020); // Error Red
  static const Color success = Color(0xFF4CAF50); // Success Green
  static const Color warning = Color(0xFFFFA000); // Warning Orange

  static const navigationBarTheme = NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: Colors.white,
  );

  // Map Colors
  static const Color mapCircle =
      Color(0x29000080); // Navy Blue with 16% opacity
  static const Color mapCircleBorder = Color(0xFF000080); // Navy Blue
  static const Color defectMarker = Color(0xFFB00020); // Error Red

  // Text Styles
  static TextStyle get headingLarge => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: secondary,
      );

  static TextStyle get headingMedium => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: secondary,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontSize: 16,
        color: secondary,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontSize: 14,
        color: secondary,
      );

  // Input Decoration
  static InputDecoration inputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: surface,
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
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // Button Styles
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: background,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      );

  static ButtonStyle get secondaryButton => ElevatedButton.styleFrom(
        backgroundColor: surface,
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      );

  // Card Decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // Animation Durations
  static const Duration quickAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 500);

  // Loading Indicator
  static Widget loadingIndicator({Color? color}) {
    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(color ?? primary),
      strokeWidth: 3,
    );
  }

  // Snackbar Styles
  static SnackBarBehavior get snackBarBehavior => SnackBarBehavior.floating;

  static SnackBar successSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      backgroundColor: success,
      behavior: snackBarBehavior,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  static SnackBar errorSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      backgroundColor: error,
      behavior: snackBarBehavior,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
