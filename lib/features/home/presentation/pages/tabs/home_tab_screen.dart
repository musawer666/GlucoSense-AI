import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/colors/app_colors.dart';
import '../../../../../core/widgets/gluco_sliver_app_bar.dart';
import '../../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../../log_reading/domain/glucose_classification.dart';
import '../../../../log_reading/domain/glucose_log_entry.dart';
import '../../../../log_reading/data/datasources/glucose_log_remote_data_source.dart';
import '../../../../log_reading/data/repositories/glucose_log_repository_impl.dart';
import '../../../../meal/presentation/widgets/home_saved_meals_section.dart';
import '../../../../profile/domain/entities/user_profile.dart';
import '../../../../profile/presentation/cubit/shell_profile_cubit.dart';
import '../../../../reminders/presentation/widgets/gluco_app_bar_reminders_actions.dart';
import '../../../../risk_prediction/domain/services/glucoiq_ml_inference_input_builder.dart';
import '../../../../risk_prediction/domain/services/saved_ml_risk_mapper.dart';
import '../../bloc/home_bloc.dart';
import '../../widgets/current_glucose_card.dart';
import '../../widgets/home_action_card.dart';
import '../../widgets/home_app_bar_avatar.dart';
import '../../widgets/home_greeting.dart';
import '../../widgets/home_risk_card.dart';
import '../../widgets/optimal_window_card.dart';

/// Home tab — premium glucose dashboard.
///
/// The screen is a pure [HomeBloc] consumer:
///   * **Real user name** is pulled from the live Firestore profile
///     snapshot (single source of truth).
///   * **Current saved glucose** is derived from the `latestXxxMgDl`
///     fields on the same profile document.
///
/// Any mutation (logging a new reading, editing the profile, etc.)
/// reflects instantly because the underlying repository stream is
/// reactive.
class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key, this.onSwitchTab});

  /// Called by action pills that map to a sibling bottom-nav tab.
  final ValueChanged<int>? onSwitchTab;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (context) => HomeBloc(
        shellProfileCubit: context.read<ShellProfileCubit>(),
        authRepository: AuthRepositoryImpl(
          remoteDataSource: AuthRemoteDataSourceImpl(),
        ),
        logRepository: GlucoseLogRepositoryImpl(
          remoteDataSource: GlucoseLogRemoteDataSourceImpl(),
        ),
      )..add(const HomeSubscribed()),
      child: _HomeTabView(onSwitchTab: onSwitchTab),
    );
  }
}

class _HomeTabView extends StatelessWidget {
  const _HomeTabView({this.onSwitchTab});

  final ValueChanged<int>? onSwitchTab;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final firstName = state.firstName ?? 'there';
        final avatarInitial = _initialFor(state.firstName);
        final latest = state.currentGlucose;
        final latestValue = latest?.mgDl;
        final readingType = latest?.type.toGlucoseReadingType() ??
            GlucoseReadingType.fasting;
        final status = latestValue != null
            ? GlucoseClassifier.classify(latestValue, readingType)
            : null;

        final inRange = status == GlucoseStatus.normal;
        final statusPillLabel = _statusPillLabel(status);
        final trend = _computeTrend(state.profile, state.chartLogs);
        final chartLogs = state.chartLogs;
        final statusLine = _statusLine(state, status);
        final insight = _insightFor(status);

        return CustomScrollView(
          slivers: [
            GlucoSliverAppBar(
              title: 'Home',
              leading: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: HomeAppBarAvatar(
                  avatarUrl: state.profile?.avatarUrl,
                  initial: avatarInitial,
                  onTap: () => onSwitchTab?.call(5),
                ),
              ),
              actions: glucoAppBarRemindersActions(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeGreeting(firstName: firstName, statusLine: statusLine),
                    const SizedBox(height: 20),
                    OptimalWindowCard(
                      title: insight.title,
                      message: insight.message,
                      icon: insight.icon,
                    ),
                    const SizedBox(height: 18),
                    CurrentGlucoseCard(
                      valueMgDl: latestValue,
                      statusLabel: statusPillLabel,
                      inRange: inRange,
                      trend: trend,
                      chartLogs: chartLogs,
                    ),
                    const SizedBox(height: 18),
                    HomeRiskCard(
                      output: savedMlRiskFromUserProfile(state.profile),
                      missingFields:
                          GlucoiqMlInferenceInputBuilder.missingFieldsForMl(
                        state.profile,
                      ),
                      onTap: () => onSwitchTab?.call(3),
                    ),
                    const SizedBox(height: 22),
                    const HomeSavedMealsSection(),
                    const SizedBox(height: 22),
                    HomeActionCard(
                      title: 'Log Reading',
                      subtitle: 'Record manual data',
                      icon: Icons.add_rounded,
                      variant: HomeActionVariant.gradient,
                      onTap: () => onSwitchTab?.call(1),
                    ),
                    const SizedBox(height: 14),
                    HomeActionCard(
                      title: 'Meal Predict',
                      subtitle: 'Analyze next meal',
                      icon: Icons.restaurant_rounded,
                      accentColor: AppColors.secondary500,
                      onTap: () => onSwitchTab?.call(2),
                    ),
                    const SizedBox(height: 14),
                    HomeActionCard(
                      title: 'Daily Insights',
                      subtitle: 'View trend analysis',
                      icon: Icons.insights_rounded,
                      accentColor: AppColors.tertiary500,
                      onTap: () => onSwitchTab?.call(4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Derivations ────────────────────────────────────────────────

  String _statusPillLabel(GlucoseStatus? status) {
    if (status == null) return 'No data';
    switch (status) {
      case GlucoseStatus.normal:
        return 'In Range';
      case GlucoseStatus.elevated:
        return 'Elevated';
      case GlucoseStatus.high:
        return 'High';
      case GlucoseStatus.low:
        return 'Low';
    }
  }

  /// Prefer the last two **log** readings (chronological). If fewer than
  /// two logs exist, fall back to fasting vs post-meal on the profile.
  GlucoseTrend _computeTrend(
    UserProfile? profile,
    List<GlucoseLogEntry> chartLogs,
  ) {
    if (chartLogs.length >= 2) {
      final sorted = List<GlucoseLogEntry>.from(chartLogs)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final prev = sorted[sorted.length - 2].glucoseMgDl;
      final last = sorted[sorted.length - 1].glucoseMgDl;
      final diff = last - prev;
      if (diff >= 15) return GlucoseTrend.rising;
      if (diff <= -15) return GlucoseTrend.falling;
      return GlucoseTrend.steady;
    }
    if (profile == null) return GlucoseTrend.steady;
    final fasting = profile.latestFastingMgDl;
    final post = profile.latestPostMealMgDl;
    if (fasting == null || post == null) return GlucoseTrend.steady;
    final diff = post - fasting;
    if (diff >= 15) return GlucoseTrend.rising;
    if (diff <= -15) return GlucoseTrend.falling;
    return GlucoseTrend.steady;
  }

  String _statusLine(HomeState state, GlucoseStatus? status) {
    if (state.isLoading) {
      return 'Loading your latest glucose picture…';
    }
    if (state.hasFailure && !state.hasProfile) {
      return state.errorMessage ??
          'We could not load your dashboard. Please try again.';
    }
    if (state.status == HomeStatus.missingProfile) {
      return 'Complete your profile setup to unlock personalised insights.';
    }
    if (status == null) {
      return 'No readings yet. Log your first glucose to see your daily outlook.';
    }
    switch (status) {
      case GlucoseStatus.normal:
        return 'Your glucose levels are perfectly steady today.';
      case GlucoseStatus.elevated:
        return 'Your latest reading is slightly elevated — keep it steady with a light walk.';
      case GlucoseStatus.high:
        return 'Your latest reading is high. Hydrate, avoid sugars, and check again soon.';
      case GlucoseStatus.low:
        return 'Your latest reading is low. Consider a quick carb snack and re-check shortly.';
    }
  }

  /// Single uppercase initial for the avatar fallback. Uses the
  /// first character of the resolved first name, or `U` for user
  /// when we have nothing at all to show.
  String _initialFor(String? firstName) {
    final trimmed = firstName?.trim();
    if (trimmed == null || trimmed.isEmpty) return 'U';
    return trimmed.substring(0, 1).toUpperCase();
  }

  _HomeInsight _insightFor(GlucoseStatus? status) {
    if (status == null) {
      return const _HomeInsight(
        title: 'Start your journal',
        message:
            'Log a fasting, pre-meal, or post-meal reading to unlock personalised insights.',
        icon: Icons.auto_awesome_rounded,
      );
    }
    switch (status) {
      case GlucoseStatus.normal:
        return const _HomeInsight(
          title: 'Optimal Window',
          message:
              'Your current readings suggest it\'s a great time for a high-intensity workout.',
          icon: Icons.lightbulb_rounded,
        );
      case GlucoseStatus.elevated:
        return const _HomeInsight(
          title: 'Gentle Reset',
          message:
              'A 10-minute walk after your next meal can bring levels back into range.',
          icon: Icons.directions_walk_rounded,
        );
      case GlucoseStatus.high:
        return const _HomeInsight(
          title: 'Stay Mindful',
          message:
              'Prefer water, lean protein, and fibre for the next meal to ease the spike.',
          icon: Icons.local_drink_rounded,
        );
      case GlucoseStatus.low:
        return const _HomeInsight(
          title: 'Small Top-Up',
          message:
              'A quick 15g carb snack can gently lift you back into a safe range.',
          icon: Icons.cookie_rounded,
        );
    }
  }
}

/// Maps a `HomeReadingType` back to the shared `GlucoseReadingType`
/// used by the classifier. Kept as a local extension to avoid
/// leaking the log_reading enum into the Home state.
extension on HomeReadingType {
  GlucoseReadingType toGlucoseReadingType() {
    switch (this) {
      case HomeReadingType.fasting:
        return GlucoseReadingType.fasting;
      case HomeReadingType.preMeal:
        return GlucoseReadingType.preMeal;
      case HomeReadingType.postMeal:
        return GlucoseReadingType.postMeal;
    }
  }
}

class _HomeInsight {
  const _HomeInsight({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;
}
