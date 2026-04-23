import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/widgets/soft_blob_background.dart';
import '../../../home/presentation/pages/home_shell_screen.dart';

/// Celebratory completion screen after medical details — animated greeting + CTA to home.
class ProfileSetupCompletePlaceholderScreen extends StatefulWidget {
  const ProfileSetupCompletePlaceholderScreen({super.key});

  @override
  State<ProfileSetupCompletePlaceholderScreen> createState() =>
      _ProfileSetupCompletePlaceholderScreenState();
}

class _ProfileSetupCompletePlaceholderScreenState
    extends State<ProfileSetupCompletePlaceholderScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _pulse;
  late final AnimationController _ctaGlow;

  late final Animation<double> _iconPop;
  late final Animation<double> _titleIn;
  late final Animation<double> _greetIn;
  late final Animation<double> _subIn;
  late final Animation<double> _f1;
  late final Animation<double> _f2;
  late final Animation<double> _f3;
  late final Animation<double> _ctaIn;
  late final Animation<double> _footnoteIn;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _ctaGlow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _iconPop = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.22, curve: Curves.elasticOut),
    );
    _titleIn = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.08, 0.28, curve: Curves.easeOutCubic),
    );
    _greetIn = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.14, 0.34, curve: Curves.easeOutCubic),
    );
    _subIn = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.22, 0.42, curve: Curves.easeOutCubic),
    );
    _f1 = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.32, 0.52, curve: Curves.easeOutCubic),
    );
    _f2 = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.40, 0.60, curve: Curves.easeOutCubic),
    );
    _f3 = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.48, 0.68, curve: Curves.easeOutCubic),
    );
    _ctaIn = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.58, 0.88, curve: Curves.easeOutCubic),
    );
    _footnoteIn = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.72, 0.95, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    _ctaGlow.dispose();
    super.dispose();
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const HomeShellScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: SoftBlobBackground(
        profileSoft: true,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final pad = (w * 0.06).clamp(16.0, 28.0);

              return Stack(
                fit: StackFit.expand,
                children: [
                  _FloatingParticles(
                    pulse: _pulse,
                    width: w,
                    height: constraints.maxHeight,
                  ),
                  SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(pad, 24, pad, 32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 48,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: Listenable.merge([
                              _entrance,
                              _pulse,
                            ]),
                            builder: (context, _) {
                              return Transform.scale(
                                scale: 0.85 + _iconPop.value * 0.15,
                                child: Opacity(
                                  opacity: _iconPop.value.clamp(0.0, 1.0),
                                  child: _SuccessBadge(
                                    pulse: _pulse.value,
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: (w * 0.06).clamp(20.0, 32.0)),
                          _FadeSlide(
                            animation: _titleIn,
                            offsetY: 18,
                            child: Text(
                              "You're all set!",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: (w * 0.075).clamp(26.0, 34.0),
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _FadeSlide(
                            animation: _greetIn,
                            offsetY: 14,
                            child: Text(
                              'Welcome to GlucoSense',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: (w * 0.048).clamp(18.0, 22.0),
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary700,
                              ),
                            ),
                          ),
                          SizedBox(height: (w * 0.04).clamp(14.0, 20.0)),
                          _FadeSlide(
                            animation: _subIn,
                            offsetY: 20,
                            child: Text(
                              'Your profile is complete. We will tailor insights, '
                              'targets, and reminders to your metabolic context.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: (w * 0.038).clamp(14.0, 16.0),
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          SizedBox(height: (w * 0.07).clamp(24.0, 36.0)),
                          _FadeSlide(
                            animation: _f1,
                            offsetY: 24,
                            child: _FeatureLine(
                              icon: Icons.auto_awesome_rounded,
                              text: 'Personalized glucose insights',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _FadeSlide(
                            animation: _f2,
                            offsetY: 24,
                            child: _FeatureLine(
                              icon: Icons.notifications_active_outlined,
                              text: 'Smart reminders when you need them',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _FadeSlide(
                            animation: _f3,
                            offsetY: 24,
                            child: _FeatureLine(
                              icon: Icons.shield_outlined,
                              text: 'Your data stays private and secure',
                            ),
                          ),
                          SizedBox(height: (w * 0.09).clamp(28.0, 44.0)),
                          _FadeSlide(
                            animation: _ctaIn,
                            offsetY: 28,
                            child: AnimatedBuilder(
                              animation: _ctaGlow,
                              builder: (context, _) {
                                final t = _ctaGlow.value;
                                final spread = 12 + t * 10;
                                return DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary400
                                            .withValues(alpha: 0.28 + t * 0.12),
                                        blurRadius: spread,
                                        spreadRadius: t * 2,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: FilledButton(
                                    onPressed: () => _goHome(context),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary600,
                                      foregroundColor: AppColors.onPrimary,
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: (w * 0.1).clamp(28.0, 40.0),
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Enter GlucoSense',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _FadeSlide(
                            animation: _footnoteIn,
                            offsetY: 12,
                            child: Text(
                              'You can update your profile anytime in Settings.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                height: 1.4,
                                color: AppColors.neutral500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FadeSlide extends StatelessWidget {
  const _FadeSlide({
    required this.animation,
    required this.child,
    this.offsetY = 16,
  });

  final Animation<double> animation;
  final Widget child;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * offsetY),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge({required this.pulse});

  final double pulse;

  @override
  Widget build(BuildContext context) {
    final ring = 1.0 + math.sin(pulse * math.pi * 2) * 0.04;
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: ring,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary300.withValues(alpha: 0.55),
                  width: 2,
                ),
              ),
            ),
          ),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary400,
                  AppColors.primary600,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary600.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.onPrimary,
              size: 52,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary600, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: AppColors.neutral800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingParticles extends StatelessWidget {
  const _FloatingParticles({
    required this.pulse,
    required this.width,
    required this.height,
  });

  final Animation<double> pulse;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final p = pulse.value;
          return CustomPaint(
            size: Size(width, height),
            painter: _ParticlesPainter(phase: p),
          );
        },
      ),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final dots = <Offset>[
      Offset(size.width * 0.12, size.height * 0.18),
      Offset(size.width * 0.88, size.height * 0.22),
      Offset(size.width * 0.18, size.height * 0.72),
      Offset(size.width * 0.82, size.height * 0.68),
      Offset(size.width * 0.5, size.height * 0.12),
    ];
    for (var i = 0; i < dots.length; i++) {
      final o = (phase + i * 0.17) % 1.0;
      final a = 0.12 + math.sin(o * math.pi * 2) * 0.08;
      final r = 3.0 + (i % 3) * 1.2;
      final paint = Paint()
        ..color = AppColors.primary400.withValues(alpha: a)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dots[i], r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}
