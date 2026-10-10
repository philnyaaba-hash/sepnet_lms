import 'package:flutter/material.dart';

/// SkillBridge Python Lab visual identity.
///
/// A calm, high-contrast palette suited to bright, often low-quality phone
/// screens, with large touch targets and legible type for young learners. We do
/// not copy any third-party product's branding.
class AppTheme {
  const AppTheme._();

  /// SkillBridge primary blue.
  static const Color brandBlue = Color(0xFF0B5FA5);
  static const Color brandBlueDark = Color(0xFF073E6D);

  /// Warm accent used for rewards / highlights.
  static const Color brandAmber = Color(0xFFF5A623);

  /// Code editor surface (works in both themes for consistent code colours).
  static const Color codeSurface = Color(0xFF0F1B2D);
  static const Color codeSurfaceLight = Color(0xFFF4F6F8);

  // Token colours for the Python syntax highlighter.
  static const Color tokenKeyword = Color(0xFFC678DD);
  static const Color tokenString = Color(0xFF98C379);
  static const Color tokenNumber = Color(0xFFD19A66);
  static const Color tokenComment = Color(0xFF7F848E);
  static const Color tokenBuiltin = Color(0xFF61AFEF);
  static const Color tokenOperator = Color(0xFF56B6C2);
  static const Color tokenVariable = Color(0xFFE5C07B);

  /// Comfortable minimum touch target for children on small screens.
  static const double minTouchTarget = 48;

  static ThemeData light() => _base(
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandBlue,
          brightness: Brightness.light,
        ),
        surface: codeSurfaceLight,
      );

  static ThemeData dark() => _base(
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandBlue,
          brightness: Brightness.dark,
        ),
        surface: codeSurface,
      );

  static ThemeData _base({
    required ColorScheme colorScheme,
    required Color surface,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
    );
    return base.copyWith(
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        centerTitle: false,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 12,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      cardTheme: CardThemeData(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      chipTheme: base.chipTheme.copyWith(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      textTheme: base.textTheme.apply(fontSizeFactor: 1.0),
    );
  }
}
