import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'l10n.dart';

/// Design tokens extracted from the web app (Tailwind v4 @theme).
class AppColors {
  static const accent = Color(0xFF1D4ED8);
  static const accentSoft = Color(0xFFDBEAFE);
  static const ok = Color(0xFF16A34A);
  static const okSoft = Color(0xFFDCFCE7);
  static const bad = Color(0xFFDC2626);
  static const badSoft = Color(0xFFFEE2E2);
  static const pending = Color(0xFFD97706);
  static const pendingSoft = Color(0xFFFEF3C7);
  static const foreground = Color(0xFF111827);
  static const background = Color(0xFFFFFFFF);

  static const zinc50 = Color(0xFFFAFAFA);
  static const zinc100 = Color(0xFFF4F4F5);
  static const zinc200 = Color(0xFFE4E4E7);
  static const zinc300 = Color(0xFFD4D4D8);
  static const zinc400 = Color(0xFFA1A1AA);
  static const zinc500 = Color(0xFF71717A);
  static const zinc600 = Color(0xFF52525B);
  static const zinc700 = Color(0xFF3F3F46);
  static const zinc800 = Color(0xFF27272A);
  static const zinc900 = Color(0xFF18181B);
}

class AppRadius {
  static const control = 12.0; // rounded-xl
  static const card = 16.0; // rounded-2xl
}

TextStyle ar(double size, FontWeight weight, Color color, {double? height}) =>
    isFr
        ? fr(size, weight, color, height: height)
        : GoogleFonts.ibmPlexSansArabic(
            fontSize: size, fontWeight: weight, color: color, height: height);

TextStyle mono(double size, FontWeight weight, Color color) =>
    GoogleFonts.ibmPlexMono(fontSize: size, fontWeight: weight, color: color);

class AppText {
  static TextStyle get h1 => ar(18, FontWeight.w700, AppColors.foreground);
  static TextStyle get h2 => ar(16, FontWeight.w700, AppColors.foreground);
  static TextStyle get title => ar(14, FontWeight.w700, AppColors.foreground);
  static TextStyle get semibold => ar(14, FontWeight.w600, AppColors.foreground);
  static TextStyle get body => ar(14, FontWeight.w400, AppColors.foreground);
  static TextStyle get label => ar(14, FontWeight.w500, AppColors.zinc700);
  static TextStyle get small => ar(12, FontWeight.w400, AppColors.zinc500);
  static TextStyle get tiny => ar(11, FontWeight.w400, AppColors.zinc400);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      primary: AppColors.accent,
      surface: AppColors.background,
    ),
  );
  final textTheme = isFr
      ? GoogleFonts.quicksandTextTheme(base.textTheme)
      : GoogleFonts.ibmPlexSansArabicTextTheme(base.textTheme);
  return base.copyWith(
    textTheme: textTheme.apply(
      bodyColor: AppColors.foreground,
      displayColor: AppColors.foreground,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        // Avoid the zoom transition's black backdrop flash on Android.
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    dividerTheme: const DividerThemeData(color: AppColors.zinc100, space: 1),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.accent),
  );
}
