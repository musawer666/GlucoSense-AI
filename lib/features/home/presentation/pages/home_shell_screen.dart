import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/services/reminder_scheduler.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../log_reading/data/datasources/glucose_log_remote_data_source.dart';
import '../../../log_reading/data/repositories/glucose_log_repository_impl.dart';
import '../../../log_reading/presentation/pages/log_reading_screen.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../../profile/presentation/cubit/shell_profile_cubit.dart';
import '../../../meal/presentation/pages/meal_predictor_screen.dart';
import '../../../profile/presentation/pages/profile_screen.dart';
import '../../../reminders/data/datasources/reminder_remote_data_source.dart';
import '../../../reminders/data/repositories/reminder_repository_impl.dart';
import '../../../risk_prediction/presentation/pages/risk_prediction_screen.dart';
import '../../../trends/presentation/pages/trends_screen.dart';
import '../widgets/floating_bottom_nav_bar.dart';
import 'tabs/home_tab_screen.dart';

/// App root after onboarding: floating pill bottom nav, **Home** at index 0.
///
/// Provides [ShellProfileCubit] so every tab shares one `users/{uid}`
/// snapshot — profile edits show up everywhere immediately.
///
/// Each tab still owns its feature Bloc/Cubit; only the profile stream
/// is centralized here.
class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen>
    with WidgetsBindingObserver {
  static const int _riskTabIndex = 3;

  int _index = 0;

  /// Bumps when the user leaves the Risk tab so [IndexedStack] rebuilds
  /// [RiskPredictionScreen] with a fresh bloc — no stale ML result.
  int _riskScreenGeneration = 0;

  void _goToTab(int i) {
    setState(() {
      if (_index == _riskTabIndex && i != _riskTabIndex) {
        _riskScreenGeneration++;
      }
      _index = i;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Fire-and-forget: rebuild the alarm queue from the user's settings
    // + recent logs. Any failure is logged and swallowed so home never
    // blocks on this.
    unawaited(_rescheduleReminders());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the user brings the app back to the foreground, re-run the
    // scheduler so any reminders that already fired get cleaned up and
    // tomorrow's next occurrences get queued.
    if (state == AppLifecycleState.resumed) {
      unawaited(_rescheduleReminders());
    }
  }

  Future<void> _rescheduleReminders() async {
    try {
      final authRepo = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
      );
      final user = authRepo.getCurrentUser();
      if (user == null) return;

      final reminderRepo = ReminderRepositoryImpl(
        remoteDataSource: ReminderRemoteDataSourceImpl(),
      );
      final logRepo = GlucoseLogRepositoryImpl(
        remoteDataSource: GlucoseLogRemoteDataSourceImpl(),
      );

      final settings = await reminderRepo.fetch(user.uid);
      final recent =
          await logRepo.watchRecent(user.uid, limit: 24).first.timeout(
                const Duration(seconds: 4),
                onTimeout: () => const [],
              );

      await ReminderScheduler.instance.rescheduleAll(
        settings: settings,
        recentLogs: recent,
      );
    } catch (e, st) {
      debugPrint('⚠️ Reminder reschedule from HomeShell failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  /// Reserve space so scroll content clears the bottom nav (compact bar + safe area).
  double _bottomReserve(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final navCore = (w * 0.22).clamp(64.0, 78.0);
    return navCore + MediaQuery.paddingOf(context).bottom;
  }

  @override
  Widget build(BuildContext context) {
    final hInset = (MediaQuery.sizeOf(context).width * 0.045).clamp(14.0, 28.0);

    return BlocProvider(
      create: (_) => ShellProfileCubit(
        profileRepository: ProfileRepositoryImpl(
          remoteDataSource: ProfileRemoteDataSourceImpl(),
        ),
        authRepository: AuthRepositoryImpl(
          remoteDataSource: AuthRemoteDataSourceImpl(),
        ),
      )..subscribe(),
      child: Scaffold(
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
                  HomeTabScreen(onSwitchTab: _goToTab),
                  const LogReadingScreen(),
                  const MealPredictorScreen(),
                  RiskPredictionScreen(
                    key: ValueKey<String>('risk_$_riskScreenGeneration'),
                  ),
                  const TrendsScreen(),
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
              onTap: _goToTab,
            ),
          ),
        ],
      ),
    ),
    );
  }
}
