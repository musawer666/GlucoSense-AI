import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/constants/asset_paths.dart';
import '../widgets/content/onboarding_bottom_card.dart';
import '../widgets/illustration/onboarding_two_illustration.dart';
import '../widgets/skip_button/skip_button.dart';
import '../../../auth/presentation/pages/login_screen.dart';

/// Second onboarding step — blue/peach panel + copy + check CTA (page 3 of 3).
class OnboardingTwoScreen extends StatelessWidget {
  const OnboardingTwoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final overlap = (constraints.maxHeight * 0.014).clamp(8.0, 18.0);

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
                              'Step 2 of 2',
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
                        child: OnboardingTwoIllustration(
                          imageAsset: AssetPaths.onboarding2,
                          heading: 'Predict Before You Eat',
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 42,
                      child: Transform.translate(
                        offset: Offset(0, -overlap),
                        child: OnboardingBottomCard(
                          title: 'Predict meal spikes before eating',
                          subtitle:
                              'Check how a meal may affect your glucose and choose smarter alternatives.',
                          pageIndex: 1,
                          pageCount: 2,
                          ctaIcon: Icons.check_rounded,
                          onNext: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute<void>(
                                builder: (_) => const LoginScreen(),
                              ),
                              (_) => false,
                            );
                          },
                        ),
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
            AppColors.tertiary50.withValues(alpha: 0.62),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -35,
            child: _GlowOrb(
              size: 230,
              color: AppColors.primary200.withValues(alpha: 0.36),
            ),
          ),
          Positioned(
            top: 130,
            left: -40,
            child: _GlowOrb(
              size: 170,
              color: AppColors.tertiary200.withValues(alpha: 0.32),
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
