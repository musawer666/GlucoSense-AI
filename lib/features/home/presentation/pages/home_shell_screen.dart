import 'package:flutter/material.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../log_reading/presentation/pages/log_reading_screen.dart';
import '../../../meal/presentation/pages/meal_predictor_screen.dart';
import '../../../profile/presentation/pages/profile_screen.dart';
import '../../../risk_prediction/presentation/pages/risk_prediction_screen.dart';
import '../widgets/floating_bottom_nav_bar.dart';
import 'tabs/home_tab_screen.dart';

/// App root after onboarding: floating pill bottom nav, **Home** at index 0.
///
/// Each tab now owns its own BlocProvider, so the shell is a pure
/// navigator — it no longer creates feature cubits.
class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _index = 0;

  /// Reserve space so scroll content clears the bottom nav (compact bar + safe area).
  double _bottomReserve(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final navCore = (w * 0.22).clamp(64.0, 78.0);
    return navCore + MediaQuery.paddingOf(context).bottom;
  }

  @override
  Widget build(BuildContext context) {
    final hInset = (MediaQuery.sizeOf(context).width * 0.045).clamp(14.0, 28.0);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: _bottomReserve(context)),
              child: IndexedStack(
                index: _index,
                children: [
                  HomeTabScreen(onSwitchTab: (i) => setState(() => _index = i)),
                  const LogReadingScreen(),
                  const MealPredictorScreen(),
                  const RiskPredictionScreen(),
                  const ProfileScreen(),
                ],
              ),
            ),
          ),
          Positioned(
            left: hInset,
            right: hInset,
            bottom: MediaQuery.paddingOf(context).bottom,
            child: FloatingBottomNavBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
            ),
          ),
        ],
      ),
    );
  }
}
