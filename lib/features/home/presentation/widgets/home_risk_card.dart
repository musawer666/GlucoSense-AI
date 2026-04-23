import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../risk_prediction/domain/entities/risk_output.dart';

/// Home-screen AI risk summary.
///
/// Two visual states:
///   * **Ready** — [output] is non-null → a coloured pill with the
///     classification (Normal / Pre-Diabetic / Diabetic) plus a one-
///     line explanation and a "View details" CTA.
///   * **Not ready** — [output] is null → soft "Unlock your risk"
///     card that lists the missing inputs and points the user to the
///     Risk Prediction tab.
///
/// The card is deliberately presentation-only; the caller wires the
/// onTap to switch tabs / navigate.
class HomeRiskCard extends StatelessWidget {
  const HomeRiskCard({
    super.key,
    required this.output,
    required this.onTap,
    this.missingFields = const [],
  });

  final RiskOutput? output;
  final List<String> missingFields;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ready = output != null;
    final theme = ready
        ? _themeForLevel(output!.level)
        : _RiskTheme.locked();

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.surface,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: theme.shadow,
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
        child: ready
            ? _ReadyContent(output: output!, theme: theme)
            : _LockedContent(theme: theme, missingFields: missingFields),
      ),
    );
  }

  static _RiskTheme _themeForLevel(RiskLevel level) {
    switch (level) {
      case RiskLevel.normal:
        return _RiskTheme(
          surface: const [AppColors.primary100, AppColors.primary50],
          badgeSurface: const [AppColors.primary500, AppColors.primary700],
          foreground: AppColors.primary900,
          shadow: AppColors.primary400.withValues(alpha: 0.24),
          icon: Icons.verified_rounded,
        );
      case RiskLevel.prediabetic:
        return _RiskTheme(
          surface: const [AppColors.tertiary100, AppColors.tertiary50],
          badgeSurface: const [AppColors.tertiary400, AppColors.tertiary600],
          foreground: AppColors.tertiary900,
          shadow: AppColors.tertiary400.withValues(alpha: 0.24),
          icon: Icons.warning_amber_rounded,
        );
      case RiskLevel.diabetic:
        return _RiskTheme(
          surface: const [Color(0xFFFEE2E2), Color(0xFFFEF2F2)],
          badgeSurface: const [AppColors.destructive, Color(0xFFB91C1C)],
          foreground: const Color(0xFF7F1D1D),
          shadow: AppColors.destructive.withValues(alpha: 0.24),
          icon: Icons.priority_high_rounded,
        );
    }
  }
}

class _ReadyContent extends StatelessWidget {
  const _ReadyContent({required this.output, required this.theme});

  final RiskOutput output;
  final _RiskTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconBadge(icon: theme.icon, surface: theme.badgeSurface),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'AI Risk Assessment',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: theme.foreground.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.foreground.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${output.confidence}%',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: theme.foreground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                output.label,
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: theme.foreground,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                output.explanation,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.45,
                  color: theme.foreground.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.chevron_right_rounded,
          color: theme.foreground.withValues(alpha: 0.6),
        ),
      ],
    );
  }
}

class _LockedContent extends StatelessWidget {
  const _LockedContent({required this.theme, required this.missingFields});

  final _RiskTheme theme;
  final List<String> missingFields;

  @override
  Widget build(BuildContext context) {
    final missingCopy = missingFields.isEmpty
        ? 'Complete your profile and log your first reading to unlock AI risk.'
        : 'Still needed: ${missingFields.take(3).join(', ')}${missingFields.length > 3 ? '…' : ''}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconBadge(icon: theme.icon, surface: theme.badgeSurface),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI RISK ASSESSMENT',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: theme.foreground.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Unlock your risk level',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.foreground,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                missingCopy,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.45,
                  color: theme.foreground.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.chevron_right_rounded,
          color: theme.foreground.withValues(alpha: 0.55),
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.surface});

  final IconData icon;
  final List<Color> surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: surface,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: surface.last.withValues(alpha: 0.32),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 22, color: Colors.white),
    );
  }
}

class _RiskTheme {
  _RiskTheme({
    required this.surface,
    required this.badgeSurface,
    required this.foreground,
    required this.shadow,
    required this.icon,
  });

  factory _RiskTheme.locked() => _RiskTheme(
        surface: const [AppColors.neutral100, AppColors.neutral50],
        badgeSurface: const [AppColors.secondary400, AppColors.secondary600],
        foreground: AppColors.neutral800,
        shadow: AppColors.neutral400.withValues(alpha: 0.22),
        icon: Icons.lock_outline_rounded,
      );

  final List<Color> surface;
  final List<Color> badgeSurface;
  final Color foreground;
  final Color shadow;
  final IconData icon;
}
