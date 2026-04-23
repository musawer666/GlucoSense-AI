import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';

/// Pill-style action card used on the home tab to route to key features.
///
/// Two visual variants:
///   * [HomeActionVariant.gradient] — primary CTA with green gradient
///     surface and soft green glow (used for the first / hero action).
///   * [HomeActionVariant.surface]  — white surface with subtle border
///     and a coloured icon chip on the trailing side.
enum HomeActionVariant { gradient, surface }

class HomeActionCard extends StatelessWidget {
  const HomeActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.variant = HomeActionVariant.surface,
    this.accentColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final HomeActionVariant variant;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final isGradient = variant == HomeActionVariant.gradient;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isGradient
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [AppColors.primary700, AppColors.primary500],
                  )
                : null,
            color: isGradient ? null : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: isGradient ? null : Border.all(color: AppColors.neutral200),
            boxShadow: [
              if (isGradient)
                BoxShadow(
                  color: AppColors.primary700.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 14, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isGradient
                              ? Colors.white
                              : AppColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isGradient
                              ? Colors.white.withValues(alpha: 0.82)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _Trailing(
                  icon: icon,
                  isGradient: isGradient,
                  accentColor: accentColor ?? AppColors.primary500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing({
    required this.icon,
    required this.isGradient,
    required this.accentColor,
  });

  final IconData icon;
  final bool isGradient;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (isGradient) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: accentColor, size: 20),
    );
  }
}
