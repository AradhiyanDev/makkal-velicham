import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTheme {
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: AppColors.accent,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.accent),
      iconTheme: const IconThemeData(color: AppColors.lightTextSecondary),
      textTheme: _textTheme(Brightness.light),
      extensions: const [AppCardColors.light],
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: Colors.white24),
      iconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
      textTheme: _textTheme(Brightness.dark),
      extensions: const [AppCardColors.dark],
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return TextTheme(
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: primary,
        height: 1.22,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        height: 1.5,
        color: secondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: secondary.withValues(alpha: 0.8),
      ),
    );
  }
}

/// ThemeExtension so widgets can read card colors from Theme instead of hardcoding
@immutable
class AppCardColors extends ThemeExtension<AppCardColors> {
  final Color cardBackground;
  final Color titleColor;
  final Color descriptionColor;
  final Color placeholderShimmer;
  final Color errorIconBg;

  const AppCardColors({
    required this.cardBackground,
    required this.titleColor,
    required this.descriptionColor,
    required this.placeholderShimmer,
    required this.errorIconBg,
  });

  static const light = AppCardColors(
    cardBackground: AppColors.lightCard,
    titleColor: AppColors.lightTextPrimary,
    descriptionColor: AppColors.lightTextSecondary,
    placeholderShimmer: Color(0xFFE8E8EE),
    errorIconBg: Color(0xFFE8E8EE),
  );

  static const dark = AppCardColors(
    cardBackground: AppColors.darkCard,
    titleColor: AppColors.darkTextPrimary,
    descriptionColor: AppColors.darkTextSecondary,
    placeholderShimmer: Color(0xFF2A2A40),
    errorIconBg: Color(0xFF2A2A40),
  );

  @override
  AppCardColors copyWith({
    Color? cardBackground,
    Color? titleColor,
    Color? descriptionColor,
    Color? placeholderShimmer,
    Color? errorIconBg,
  }) {
    return AppCardColors(
      cardBackground: cardBackground ?? this.cardBackground,
      titleColor: titleColor ?? this.titleColor,
      descriptionColor: descriptionColor ?? this.descriptionColor,
      placeholderShimmer: placeholderShimmer ?? this.placeholderShimmer,
      errorIconBg: errorIconBg ?? this.errorIconBg,
    );
  }

  @override
  AppCardColors lerp(ThemeExtension<AppCardColors>? other, double t) {
    if (other is! AppCardColors) return this;
    return AppCardColors(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      titleColor: Color.lerp(titleColor, other.titleColor, t)!,
      descriptionColor: Color.lerp(descriptionColor, other.descriptionColor, t)!,
      placeholderShimmer: Color.lerp(placeholderShimmer, other.placeholderShimmer, t)!,
      errorIconBg: Color.lerp(errorIconBg, other.errorIconBg, t)!,
    );
  }
}
