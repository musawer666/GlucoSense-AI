import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/constants/asset_paths.dart';
import '../widgets/content/onboarding_bottom_card.dart';
import '../widgets/illustration/onboarding_illustration.dart';
import '../widgets/skip_button/skip_button.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import 'onboarding_two_screen.dart';

/// First onboarding step — illustration + bottom card + skip/next.
class OnboardingOneScreen extends StatelessWidget {
  const OnboardingOneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                const _OnboardingBackground(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 14, 2),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary50,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.primary200,
                              ),
                            ),
                            child: Text(
                              'Step 1 of 2',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          OnboardingSkipButton(
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute<void>(
                                  builder: (_) => const LoginScreen(),
                                ),
                                (_) => false,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 58,
                      child: Center(
                        child: OnboardingIllustration(
                          imageAsset: AssetPaths.onboarding1,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 42,
                      child: OnboardingBottomCard(
                        title: 'Track your glucose with clarity',
                        subtitle:
                            'Log fasting, pre-meal, and post-meal readings in a simple and organized way.',
                        pageIndex: 0,
                        pageCount: 2,
                        onNext: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const OnboardingTwoScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingBackground extends StatelessWidget {
  const _OnboardingBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary50,
            AppColors.neutral50,
            AppColors.secondary50.withValues(alpha: 0.55),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _GlowOrb(
              size: 220,
              color: AppColors.primary200.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            top: 120,
            left: -60,
            child: _GlowOrb(
              size: 180,
              color: AppColors.secondary200.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}
