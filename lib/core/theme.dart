import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────
//  TRIPSQUAD DESIGN SYSTEM
//  Matches the brand identity exactly.
// ─────────────────────────────────────────────────────────────

class TSColors {
  TSColors._();

  // ── Brand colours ──────────────────────────────────────────
  static const lime    = Color(0xFFCCFF45);
  static const coral   = Color(0xFFFF4757);
  static const blue    = Color(0xFF3D8EFF);
  static const purple  = Color(0xFF9B6DFF);
  static const gold    = Color(0xFFFFB800);
  static const teal    = Color(0xFF00D4AA);
  static const pink    = Color(0xFFFF6CAE);
  static const orange  = Color(0xFFFF8040);

  // ── Background surfaces ────────────────────────────────────
  static const bg      = Color(0xFF08080E);
  static const s1      = Color(0xFF0F0F1C);
  static const s2      = Color(0xFF171728);
  static const s3      = Color(0xFF1E1E32);

  // ── Text ───────────────────────────────────────────────────
  static const text    = Color(0xFFF0EDF8);
  static const text2   = Color(0xFFC0BCDA);
  static const muted   = Color(0xFF6A6485);
  static const muted2  = Color(0xFF8884A0);

  // ── Borders ────────────────────────────────────────────────
  static const border  = Color(0x12FFFFFF);
  static const border2 = Color(0x1FFFFFFF);

  // ── Ambient glows ──────────────────────────────────────────
  static const limeGlow      = Color(0x33CCFF45);
  static const gradientStart = Color(0xFF0A0A14);
  static const gradientEnd   = Color(0xFF08080E);

  // ── Semantic dimmed variants ────────────────────────────────
  static Color limeDim(double opacity)   => lime.withOpacity(opacity);
  static Color coralDim(double opacity)  => coral.withOpacity(opacity);
  static Color blueDim(double opacity)   => blue.withOpacity(opacity);
  static Color purpleDim(double opacity) => purple.withOpacity(opacity);
  static Color goldDim(double opacity)   => gold.withOpacity(opacity);
  static Color tealDim(double opacity)   => teal.withOpacity(opacity);
}

class TSTextStyles {
  TSTextStyles._();

  // Display/heading = Clash Display (personality, editorial).
  // Body/caption    = Satoshi (premium, buttery at every size).
  // Both ship as bundled TTF assets — see pubspec.yaml.

  static const _display = 'Clash Display';
  static const _body    = 'Satoshi';

  // Display Hero — for peak moments (reveal, splash)
  static TextStyle displayHero({Color? color, double? size}) => TextStyle(
        fontFamily: _display,
        fontSize: size ?? 56,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.04 * (size ?? 56),
        height: 0.88,
        color: color ?? TSColors.text,
      );

  // Display
  static TextStyle display({Color? color, double? size}) => TextStyle(
        fontFamily: _display,
        fontSize: size ?? 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * (size ?? 48),
        height: 0.92,
        color: color ?? TSColors.text,
      );

  // Heading
  static TextStyle heading({Color? color, double? size}) => TextStyle(
        fontFamily: _display,
        fontSize: size ?? 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * (size ?? 24),
        height: 1.15,
        color: color ?? TSColors.text,
      );

  // Title
  static TextStyle title({Color? color, double? size}) => TextStyle(
        fontFamily: _display,
        fontSize: size ?? 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
        color: color ?? TSColors.text,
      );

  // Body
  static TextStyle body({Color? color, double? size, FontWeight? weight}) =>
      TextStyle(
        fontFamily: _body,
        fontSize: size ?? 14,
        fontWeight: weight ?? FontWeight.w400,
        height: 1.6,
        color: color ?? TSColors.text2,
      );

  // Label (uppercase tracking)
  static TextStyle label({Color? color, double? size}) => TextStyle(
        fontFamily: _display,
        fontSize: size ?? 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.14,
        color: color ?? TSColors.muted,
      );

  // Caption
  static TextStyle caption({Color? color}) => TextStyle(
        fontFamily: _body,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color ?? TSColors.muted2,
        height: 1.5,
      );
}

class TSRadius {
  TSRadius._();
  static const xs  = BorderRadius.all(Radius.circular(8));
  static const sm  = BorderRadius.all(Radius.circular(10));
  static const md  = BorderRadius.all(Radius.circular(14));
  static const lg  = BorderRadius.all(Radius.circular(18));
  static const xl  = BorderRadius.all(Radius.circular(24));
  static const full = BorderRadius.all(Radius.circular(100));
  // iOS icon
  static const icon = BorderRadius.all(Radius.circular(22));
  // Raw values for use in ClipRRect etc.
  static const double mdValue = 14;
  static const double lgValue = 18;
  static const double xlValue = 24;
}

class TSSpacing {
  TSSpacing._();
  static const xxs = 4.0;
  static const xs  = 8.0;
  static const sm  = 12.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;
}

// ── App theme ─────────────────────────────────────────────────
ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: TSColors.bg,
    colorScheme: const ColorScheme.dark(
      primary:   TSColors.lime,
      secondary: TSColors.purple,
      error:     TSColors.coral,
      surface:   TSColors.s1,
    ),
    // Default text font is Satoshi (body). Display is Clash Display
    // and applied per-style via TSTextStyles.
    fontFamily: 'Satoshi',
    appBarTheme: const AppBarTheme(
      backgroundColor: TSColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: TSColors.bg,
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Clash Display',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: TSColors.text,
        letterSpacing: -0.01,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge:  TextStyle(fontFamily: 'Clash Display', fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(fontFamily: 'Clash Display', fontWeight: FontWeight.w700),
      titleLarge:    TextStyle(fontFamily: 'Clash Display', fontWeight: FontWeight.w600),
      bodyLarge:     TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w400),
      bodyMedium:    TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w400),
      labelSmall:    TextStyle(fontFamily: 'Clash Display', fontWeight: FontWeight.w600, letterSpacing: 0.14),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TSColors.s2,
      border: OutlineInputBorder(
        borderRadius: TSRadius.md,
        borderSide: const BorderSide(color: TSColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: TSRadius.md,
        borderSide: const BorderSide(color: TSColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: TSRadius.md,
        borderSide: const BorderSide(color: TSColors.lime, width: 1.5),
      ),
      hintStyle: const TextStyle(
        fontFamily: 'DM Sans',
        color: TSColors.muted,
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: TSSpacing.md,
        vertical: TSSpacing.sm,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TSColors.lime,
        foregroundColor: TSColors.bg,
        minimumSize: const Size(double.infinity, 52),
        shape: const RoundedRectangleBorder(borderRadius: TSRadius.md),
        textStyle: const TextStyle(
          fontFamily: 'Syne',
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.01,
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TSColors.muted2,
        side: const BorderSide(color: TSColors.border2),
        minimumSize: const Size(double.infinity, 52),
        shape: const RoundedRectangleBorder(borderRadius: TSRadius.md),
        textStyle: const TextStyle(
          fontFamily: 'Syne',
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: TSColors.border,
      thickness: 1,
      space: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: TSColors.s1,
      selectedItemColor: TSColors.lime,
      unselectedItemColor: TSColors.muted,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Syne',
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.04,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Syne',
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.04,
      ),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}
