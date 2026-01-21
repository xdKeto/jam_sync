import 'package:flutter/material.dart';

class AppStyles {
  AppStyles._();

  // Primary Palette
  static const Color primary = Color(0xFF1B4965);
  static const Color secondary = Color(0xFF62B6CB);
  static const Color tertiary = Color(0xFF5FA8D3);
  static const Color accent = Color(0xFFBEE9E8);
  static const Color surface = Color(0xFFCAE9FF);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Text Colors
  static const Color textPrimary = Color(0xFF1B4965);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF1B4965);

  // Background Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF1B4965);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, surface],
  );

  // ============================================
  // RESPONSIVE HELPERS
  // ============================================

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  static double responsiveSize(
    BuildContext context, {
    required double mobile,
    required double tablet,
  }) {
    return isTablet(context) ? tablet : mobile;
  }

  // ============================================
  // TEXT STYLES - HEADINGS
  // ============================================

  // H1 - Display/Hero text
  static TextStyle h1(BuildContext context) => TextStyle(
    fontSize: responsiveSize(context, mobile: 28, tablet: 36),
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  // H2 - Page titles
  static TextStyle h2(BuildContext context) => TextStyle(
    fontSize: responsiveSize(context, mobile: 24, tablet: 30),
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.25,
    letterSpacing: -0.3,
  );

  // H3 - Section headers
  static TextStyle h3(BuildContext context) => TextStyle(
    fontSize: responsiveSize(context, mobile: 20, tablet: 24),
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  // H4 - Card titles
  static TextStyle h4(BuildContext context) => TextStyle(
    fontSize: responsiveSize(context, mobile: 18, tablet: 20),
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.35,
  );

  // H5 - Subsection headers
  static TextStyle h5(BuildContext context) => TextStyle(
    fontSize: responsiveSize(context, mobile: 16, tablet: 18),
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  // H6 - Small headers
  static TextStyle h6(BuildContext context) => TextStyle(
    fontSize: responsiveSize(context, mobile: 14, tablet: 16),
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  // ============================================
  // TEXT STYLES - BODY
  // ============================================

  // Body Large
  static TextStyle bodyLarge(BuildContext context) => TextStyle(
    fontSize: responsiveSize(context, mobile: 16, tablet: 18),
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  // Body Medium (default body text)
  static TextStyle bodyMedium(BuildContext context) => TextStyle(
    fontSize: responsiveSize(context, mobile: 14, tablet: 16),
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  // Body Small
  static TextStyle bodySmall(BuildContext context) => TextStyle(
    fontSize: responsiveSize(context, mobile: 12, tablet: 14),
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  // ============================================
  // TEXT STYLES - LABELS
  // ============================================

  // Label Large - Buttons, tabs
  static TextStyle labelLarge(BuildContext context) => TextStyle(
    fontSize: responsiveSize(context, mobile: 14, tablet: 16),
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.4,
    letterSpacing: 0.1,
  );

  // Label Medium - Form labels
  static TextStyle labelMedium(BuildContext context) => TextStyle(
    fontSize: responsiveSize(context, mobile: 12, tablet: 14),
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.4,
    letterSpacing: 0.1,
  );

  // Label Small - Chips, badges
  static TextStyle labelSmall(BuildContext context) => TextStyle(
    fontSize: responsiveSize(context, mobile: 10, tablet: 12),
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.4,
    letterSpacing: 0.2,
  );

  // ============================================
  // TEXT STYLES - CAPTIONS & HELPER TEXT
  // ============================================

  // Caption - Image captions, helper text
  static TextStyle caption(BuildContext context) => TextStyle(
    fontSize: responsiveSize(context, mobile: 12, tablet: 14),
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );

  // Overline - Category labels, timestamps
  static TextStyle overline(BuildContext context) => TextStyle(
    fontSize: responsiveSize(context, mobile: 10, tablet: 12),
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.5,
    letterSpacing: 1.0,
  );

  // ============================================
  // TEXT STYLES - SPECIAL PURPOSE
  // ============================================

  // Button text
  static TextStyle button(BuildContext context) => TextStyle(
    fontSize: responsiveSize(context, mobile: 14, tablet: 16),
    fontWeight: FontWeight.w600,
    color: textOnPrimary,
    height: 1.2,
    letterSpacing: 0.5,
  );

  // Link text
  static TextStyle link(BuildContext context) => TextStyle(
    fontSize: responsiveSize(context, mobile: 14, tablet: 16),
    fontWeight: FontWeight.w500,
    color: secondary,
    height: 1.5,
    decoration: TextDecoration.underline,
    decorationColor: secondary,
  );

  // Error text
  static TextStyle errorText(BuildContext context) => TextStyle(
    fontSize: responsiveSize(context, mobile: 12, tablet: 14),
    fontWeight: FontWeight.w400,
    color: error,
    height: 1.4,
  );

  // Hint text (placeholder)
  static TextStyle hint(BuildContext context) => TextStyle(
    fontSize: responsiveSize(context, mobile: 14, tablet: 16),
    fontWeight: FontWeight.w400,
    color: grey500,
    height: 1.5,
  );

  // ============================================
  // STATIC TEXT STYLES (tanpa context)
  // Digunakan untuk kasus dimana context tidak tersedia
  // ============================================

  static const TextStyle staticH1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle staticH2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.25,
    letterSpacing: -0.3,
  );

  static const TextStyle staticH3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle staticBodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle staticBodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle staticBodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle staticLabelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle staticCaption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );
}
