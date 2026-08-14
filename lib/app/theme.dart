import 'package:flutter/material.dart';

/// Palette ported from the web prototype (oklch values converted to sRGB hex).
/// Los neutros se resuelven según [isDark] para que el mismo código
/// funcione en modo claro y oscuro; los acentos son fijos.
class AppColors {
  static bool isDark = false;

  static Color get background =>
      isDark ? const Color(0xFF12161D) : const Color(0xFFFCFAF4);
  static Color get surface =>
      isDark ? const Color(0xFF1A2029) : const Color(0xFFFEFDFA);
  static Color get surface2 =>
      isDark ? const Color(0xFF242B36) : const Color(0xFFF6F3EC);
  static Color get foreground =>
      isDark ? const Color(0xFFEDF1F6) : const Color(0xFF151B24);
  static Color get muted =>
      isDark ? const Color(0xFF2A3240) : const Color(0xFFEEEBE4);
  static Color get mutedForeground =>
      isDark ? const Color(0xFF9AA3B2) : const Color(0xFF5D646F);
  static Color get border =>
      isDark ? const Color(0xFF2F3744) : const Color(0xFFE1DED5);
  static Color get hairline => isDark
      ? const Color(0x4D2F3744)
      : const Color(0xB3E1DED5); // border @ 30% / 70%
  static const primary = Color(0xFF1C8742);
  static const primaryForeground = Color(0xFFFDFCF8);
  static const primarySoft = Color(0xFFD5F5DA);
  static const accent = Color(0xFF4EC983);
  static const accentSoft = Color(0xFFDEFAE6);
  static const amber = Color(0xFFE1A035);
  static const amberSoft = Color(0xFFFFF0CC);
  static const danger = Color(0xFFD74745);
  static const dangerSoft = Color(0xFFFFEBE8);

  static const ai1 = Color(0xFF4EBE7D);
  static const ai2 = Color(0xFF00BCC5);
  static const ai3 = Color(0xFFA682E1);
}

/// 120deg gradient: ai1 → ai2 (50%) → ai3
const aiGradient = LinearGradient(
  colors: [AppColors.ai1, AppColors.ai2, AppColors.ai3],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// .card utility from the web app
BoxDecoration cardDeco({
  double radius = 24,
  Color? color,
  EdgeInsetsGeometry? padding,
}) {
  return BoxDecoration(
    color: color ?? AppColors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.hairline),
    boxShadow: const [
      BoxShadow(
        color: Color(0x3D151B24),
        offset: Offset(0, 6),
        blurRadius: 24,
        spreadRadius: -12,
      ),
    ],
  );
}

class AppText {
  static const serifItalic = TextStyle(
    fontFamily: 'serif',
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w600,
  );
}

/// Estilos de botones compartidos (enviar, acciones principales).
class AppButtons {
  static const sendIcon = Icons.arrow_upward_rounded;

  static ButtonStyle get primaryCircle => IconButton.styleFrom(
    backgroundColor: AppColors.primary,
    shape: const CircleBorder(),
  );

  static const sendForeground = AppColors.primaryForeground;
}

ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: AppColors.isDark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        secondary: AppColors.accent,
        onSecondary: AppColors.foreground,
        surface: AppColors.surface,
        onSurface: AppColors.foreground,
        error: AppColors.danger,
      );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    splashFactory: InkSparkle.splashFactory,
    textTheme: base.textTheme.copyWith(
      bodyLarge: TextStyle(
        color: AppColors.foreground,
        fontSize: 15,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: AppColors.foreground,
        fontSize: 14,
        height: 1.4,
      ),
      titleLarge: TextStyle(
        color: AppColors.foreground,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: TextStyle(color: AppColors.mutedForeground, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
    ),
    dividerColor: AppColors.hairline,
  );
}
