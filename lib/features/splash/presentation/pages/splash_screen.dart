import 'package:flutter/material.dart';

import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../home/presentation/pages/home_shell_screen.dart';
import '../../../onboarding/presentation/pages/onboarding_one_screen.dart';
import '../../../profile_setup/presentation/pages/profile_setup_screen.dart';
import '../widgets/background/background.dart';
import '../widgets/header/header.dart';
import '../widgets/loader/loader.dart';
import '../widgets/logo/logo.dart';

/// Splash: centered branding, animated logo + progress, then navigates forward.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _timeline;
  late final AnimationController _ring;
  late final AnimationController _glow;

  late final Animation<double> _intro;
  late final Animation<double> _progress;

  bool _navigated = false;

  /// Session resolution kicked off in [initState] so it runs in
  /// parallel with the branding animation — by the time the progress
  /// line finishes, Firebase / Firestore checks are usually done.
  late final Future<AuthSessionState> _sessionFuture;

  /// Lazily-built repository. Instantiating it here keeps Firebase
  /// out of `main.dart` and out of every widget below.
  late final AuthRepository _authRepository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(),
  );

  /// Line fills by ~72% of this duration, then holds at 100%; on complete → next screen.
  static const Duration _totalDuration = Duration(milliseconds: 3200);

  @override
  void initState() {
    super.initState();

    _timeline = AnimationController(vsync: this, duration: _totalDuration);
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _intro = CurvedAnimation(
      parent: _timeline,
      curve: const Interval(0.0, 0.28, curve: Curves.easeOutCubic),
    );
    _progress = CurvedAnimation(
      parent: _timeline,
      curve: const Interval(
        0.05,
        0.72,
        curve: Curves.easeInOutCubic,
      ),
    );

    _sessionFuture = _authRepository.resolveSession();

    _timeline.addStatusListener(_onTimelineStatus);
    _timeline.forward();
  }

  Future<void> _onTimelineStatus(AnimationStatus status) async {
    if (status != AnimationStatus.completed || _navigated || !mounted) return;
    _navigated = true;

    // Wait for Firebase / Firestore to finish (in practice already
    // done by the time the 3.2s animation completes).
    final session = await _sessionFuture;
    if (!mounted) return;

    final next = switch (session) {
      AuthSessionState.ready => const HomeShellScreen(),
      AuthSessionState.profileIncomplete => const ProfileSetupScreen(),
      AuthSessionState.unauthenticated => const OnboardingOneScreen(),
    };

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => next,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _timeline.removeStatusListener(_onTimelineStatus);
    _timeline.dispose();
    _ring.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SplashBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final maxH = constraints.maxHeight;
            final contentW = maxW.clamp(0, 520).toDouble();
            final logoSize = (maxH * 0.22).clamp(140.0, 210.0).toDouble();
            final bottomPad = (maxH * 0.045).clamp(12.0, 28.0);

            return SafeArea(
              child: AnimatedBuilder(
                animation: Listenable.merge([_timeline, _ring, _glow]),
                builder: (context, child) {
                  final intro = _intro.value;
                  final progress = _progress.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Transform.translate(
                          offset: Offset(0, 12 * (1 - intro)),
                          child: Opacity(
                            opacity: intro,
                            child: Transform.scale(
                              scale: 0.94 + 0.06 * intro,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SplashLogo(
                                    diameter: logoSize,
                                    ringRotation: _ring.value * 2 * 3.141592653589793,
                                    glowPulse: _glow.value,
                                  ),
                                  SizedBox(
                                    height: (maxW * 0.065).clamp(18.0, 28.0),
                                  ),
                                  SizedBox(
                                    width: contentW,
                                    child: SplashHeader(
                                      maxContentWidth: contentW,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: maxW,
                        child: SplashLoader(progress: progress),
                      ),
                      SizedBox(height: bottomPad),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
