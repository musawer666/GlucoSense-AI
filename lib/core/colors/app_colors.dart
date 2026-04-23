import 'package:flutter/material.dart';

/// **Luminous Vitality** design system colors.
///
/// Primary [#2DD4BF], Secondary [#8B5CF6], Tertiary [#FB923C], Neutral [#F9FAFB]
/// with 10-step scales (50 → 900) aligned to the brand swatches.
abstract final class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Primary (Teal) — brand token: #2DD4BF (scale step 400)
  // ---------------------------------------------------------------------------
  static const Color primary50 = Color(0xFFF0FDFA);
  static const Color primary100 = Color(0xFFCCFBF1);
  static const Color primary200 = Color(0xFF99F6E4);
  static const Color primary300 = Color(0xFF5EEAD4);
  static const Color primary400 = Color(0xFF2DD4BF);
  static const Color primary500 = Color(0xFF14B8A6);
  static const Color primary600 = Color(0xFF0D9488);
  static const Color primary700 = Color(0xFF0F766E);
  static const Color primary800 = Color(0xFF115E59);
  static const Color primary900 = Color(0xFF134E4A);

  /// Main brand primary (matches design system “Primary” chip).
  static const Color primary = primary400;

  // ---------------------------------------------------------------------------
  // Secondary (Violet) — brand token: #8B5CF6 (scale step 500)
  // ---------------------------------------------------------------------------
  static const Color secondary50 = Color(0xFFFAF5FF);
  static const Color secondary100 = Color(0xFFF3E8FF);
  static const Color secondary200 = Color(0xFFE9D5FF);
  static const Color secondary300 = Color(0xFFD8B4FE);
  static const Color secondary400 = Color(0xFFC084FC);
  static const Color secondary500 = Color(0xFF8B5CF6);
  static const Color secondary600 = Color(0xFF7C3AED);
  static const Color secondary700 = Color(0xFF6D28D9);
  static const Color secondary800 = Color(0xFF5B21B6);
  static const Color secondary900 = Color(0xFF4C1D95);

  static const Color secondary = secondary500;

  // ---------------------------------------------------------------------------
  // Tertiary (Orange) — brand token: #FB923C (scale step 400)
  // ---------------------------------------------------------------------------
  static const Color tertiary50 = Color(0xFFFFF7ED);
  static const Color tertiary100 = Color(0xFFFFEDD5);
  static const Color tertiary200 = Color(0xFFFED7AA);
  static const Color tertiary300 = Color(0xFFFDBA74);
  static const Color tertiary400 = Color(0xFFFB923C);
  static const Color tertiary500 = Color(0xFFF97316);
  static const Color tertiary600 = Color(0xFFEA580C);
  static const Color tertiary700 = Color(0xFFC2410C);
  static const Color tertiary800 = Color(0xFF9A3412);
  static const Color tertiary900 = Color(0xFF7C2D12);

  static const Color tertiary = tertiary400;

  // ---------------------------------------------------------------------------
  // Neutral (Cool gray) — background token: #F9FAFB (scale step 50)
  // ---------------------------------------------------------------------------
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF111827);

  static const Color neutral = neutral50;

  // ---------------------------------------------------------------------------
  // Semantic (UI kit from the design board)
  // ---------------------------------------------------------------------------
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onTertiary = Color(0xFFFFFFFF);

  /// Primary solid button (dark teal surface).
  static const Color buttonPrimary = primary800;

  /// Secondary button surface (light gray).
  static const Color buttonSecondary = neutral200;

  /// Inverted / dark surface.
  static const Color buttonInverted = neutral900;

  /// Outlined button border.
  static const Color buttonOutlinedBorder = neutral300;

  static const Color surface = neutral50;
  static const Color surfaceVariant = neutral100;

  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral600;
  static const Color textOnDark = neutral50;

  /// Destructive / trash icon context.
  static const Color destructive = Color(0xFFEF4444);

  static const Color outline = neutral200;
  static const Color divider = neutral200;

  // ---------------------------------------------------------------------------
  // Main shell — floating bottom navigation
  // ---------------------------------------------------------------------------

  /// Inactive tab icon + label (blue-grey).
  static const Color bottomNavInactive = Color(0xFF8A95A8);

  /// Selected tab pill background (mint / teal from nav design).
  static const Color bottomNavSelected = Color(0xFF66C7B1);

  /// Floating nav bar surface.
  static const Color bottomNavBarSurface = Color(0xFFFFFFFF);
}
