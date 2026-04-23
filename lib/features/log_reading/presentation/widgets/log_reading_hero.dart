import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';

/// Animated hero for the Log Reading screen.
///
/// Shows the title, a pulsing droplet orb accent, and a supportive tagline
/// chip that reinforces what the data powers.
class LogReadingHero extends StatefulWidget {
  const LogReadingHero({
    super.key,
    required this.width,
    this.trailingChip,
  });

  final double width;

  /// Optional pill/badge rendered in the top-right row (e.g. streak).
  final Widget? trailingChip;

  @override
  State<LogReadingHero> createState() => _LogReadingHeroState();
}

class _LogReadingHeroState extends State<LogReadingHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary100,
                          AppColors.primary50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.primary200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_graph_rounded,
                          size: 13,
                          color: AppColors.primary700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Glucose journal',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.trailingChip != null) widget.trailingChip!,
                ],
              ),
              const SizedBox(height: 12),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.neutral900,
                    AppColors.primary800,
                  ],
                ).createShader(rect),
                child: Text(
                  'Log Reading',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: (w * 0.085).clamp(28.0, 34.0),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Record fasting, pre-meal, and post-meal glucose. '
                'Fuels trends, risk checks, and meal insights.',
                style: GoogleFonts.inter(
                  fontSize: (w * 0.036).clamp(13.0, 15.0),
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _PulseOrb(controller: _pulse),
      ],
    );
  }
}

class _PulseOrb extends StatelessWidget {
  const _PulseOrb({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary400.withValues(alpha: 0.18 + 0.14 * t),
                      AppColors.primary400.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              Container(
                width: 50 + 6 * t,
                height: 50 + 6 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary400,
                      AppColors.primary700,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary500.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
