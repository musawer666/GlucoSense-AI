import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/widgets/app_loader.dart' show AppInlineLoader;
import '../../../../core/widgets/app_result_dialog.dart';
import '../../../../core/widgets/gluco_sliver_app_bar.dart';
import '../../../../core/widgets/soft_blob_background.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../data/datasources/glucose_log_remote_data_source.dart';
import '../../data/repositories/glucose_log_repository_impl.dart';
import '../../domain/glucose_log_entry.dart';
import '../cubit/log_reading_cubit.dart';
import '../cubit/log_reading_state.dart';
import '../widgets/animated_section.dart';
import '../widgets/form_section_label.dart';
import '../widgets/glucose_classification_badge.dart';
import '../widgets/glucose_delta_card.dart';
import '../widgets/glucose_input_field.dart';
import '../widgets/log_form_card.dart';
import '../widgets/log_reading_hero.dart';
import '../widgets/meal_tag_chips.dart';
import '../widgets/reading_type_selector.dart';
import '../widgets/recent_log_empty_card.dart';
import '../widgets/recent_log_tile.dart';
import '../widgets/save_reading_button.dart';
import '../widgets/streak_chip.dart';
import '../widgets/timestamp_picker_tile.dart';
import '../widgets/today_summary_strip.dart';

/// Clinical glucose journal — feeds Trends, Risk (Model 1), Meal, Alerts.
///
/// Distinct from Meal Predictor: no meal name is collected here; the
/// meal tag alone is enough context for analytics, while Meal Predictor
/// handles per-meal AI analysis.
class LogReadingScreen extends StatelessWidget {
  const LogReadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LogReadingCubit>(
      create: (_) => LogReadingCubit(
        logRepository: GlucoseLogRepositoryImpl(
          remoteDataSource: GlucoseLogRemoteDataSourceImpl(),
        ),
        authRepository: AuthRepositoryImpl(
          remoteDataSource: AuthRemoteDataSourceImpl(),
        ),
      )..subscribe(),
      child: const _LogReadingView(),
    );
  }
}

class _LogReadingView extends StatefulWidget {
  const _LogReadingView();

  @override
  State<_LogReadingView> createState() => _LogReadingViewState();
}

class _LogReadingViewState extends State<_LogReadingView> {
  final TextEditingController _glucoseController = TextEditingController();

  @override
  void dispose() {
    _glucoseController.dispose();
    super.dispose();
  }

  Future<void> _pickTimestamp(
    BuildContext context,
    LogReadingCubit cubit,
  ) async {
    final state = cubit.state;
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDate: state.timestamp,
    );
    if (d == null || !context.mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(state.timestamp),
    );
    if (t == null || !context.mounted) return;
    cubit.setTimestamp(DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  String _fmtDateTime(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$mm/$dd $hh:$min';
  }

  int? _parseGlucose(String text) {
    final v = int.tryParse(text.trim());
    if (v == null) return null;
    if (v < 40 || v > 500) return null;
    return v;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LogReadingCubit, LogReadingState>(
      listenWhen: (p, c) =>
          p.uiStatus != c.uiStatus || p.userMessage != c.userMessage,
      listener: (context, state) {
        if (state.uiStatus == LogReadingUiStatus.saved) {
          _glucoseController.clear();
          AppResultDialog.show(
            context,
            variant: AppResultVariant.success,
            title: 'Reading saved',
            message: 'Your glucose log was saved.',
          );
          context.read<LogReadingCubit>().resetAfterSaveFeedback();
        }
        if (state.uiStatus == LogReadingUiStatus.error &&
            state.userMessage != null) {
          AppResultDialog.show(
            context,
            variant: AppResultVariant.error,
            title: 'Could not save',
            message: state.userMessage!,
            autoDismiss: false,
          );
          context.read<LogReadingCubit>().clearTransientMessages();
        }
      },
      builder: (context, state) {
        final cubit = context.read<LogReadingCubit>();
        final loadingList = state.uiStatus == LogReadingUiStatus.loadingList;
        final saving = state.uiStatus == LogReadingUiStatus.saving;
        final parsedGlucose = _parseGlucose(state.glucoseText);
        final streak = computeLoggingStreak(state.recentLogs);

        return SoftBlobBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final pad = (w * 0.055).clamp(16.0, 22.0);
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const GlucoSliverAppBar(title: 'Log Reading'),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(pad, 18, pad, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedSection(
                            delay: const Duration(milliseconds: 60),
                            child: LogReadingHero(
                              width: w,
                              trailingChip: StreakChip(days: streak),
                            ),
                          ),
                          const SizedBox(height: 18),
                          AnimatedSection(
                            delay: const Duration(milliseconds: 140),
                            child: TodaySummaryStrip(logs: state.recentLogs),
                          ),
                          const SizedBox(height: 20),
                          AnimatedSection(
                            delay: const Duration(milliseconds: 220),
                            child: LogFormCard(
                              child: loadingList
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 40,
                                      ),
                                      child: Center(child: AppInlineLoader()),
                                    )
                                  : _FormBody(
                                      state: state,
                                      cubit: cubit,
                                      saving: saving,
                                      glucoseController: _glucoseController,
                                      parsedGlucose: parsedGlucose,
                                      onPickTimestamp: () =>
                                          _pickTimestamp(context, cubit),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          AnimatedSection(
                            delay: const Duration(milliseconds: 340),
                            child: _RecentLogsHeader(
                              count: state.recentLogs.length,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (state.recentLogs.isEmpty)
                            AnimatedSection(
                              delay: const Duration(milliseconds: 400),
                              child: const RecentLogEmptyCard(),
                            )
                          else
                            ..._buildAnimatedLogs(state.recentLogs),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _buildAnimatedLogs(List<GlucoseLogEntry> logs) {
    final take = logs.take(12).toList();
    return List<Widget>.generate(take.length, (i) {
      final entry = take[i];
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AnimatedSection(
          delay: Duration(milliseconds: 400 + i * 55),
          offset: const Offset(0, 0.1),
          child: RecentLogTile(entry: entry, fmt: _fmtDateTime),
        ),
      );
    });
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.state,
    required this.cubit,
    required this.saving,
    required this.glucoseController,
    required this.parsedGlucose,
    required this.onPickTimestamp,
  });

  final LogReadingState state;
  final LogReadingCubit cubit;
  final bool saving;
  final TextEditingController glucoseController;
  final int? parsedGlucose;
  final VoidCallback onPickTimestamp;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FormSectionLabel(icon: Icons.tune_rounded, title: 'Reading type'),
        const SizedBox(height: 10),
        ReadingTypeSelector(
          selected: state.readingType,
          onChanged: cubit.setReadingType,
        ),
        const SizedBox(height: 18),
        const FormSectionLabel(
          icon: Icons.monitor_heart_rounded,
          title: 'Glucose level',
          hint: 'Enter the latest reading from your glucometer.',
        ),
        const SizedBox(height: 10),
        GlucoseInputField(
          controller: glucoseController,
          onChanged: cubit.setGlucoseText,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: parsedGlucose == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      GlucoseClassificationBadge(
                        value: parsedGlucose,
                        type: state.readingType,
                      ),
                      const SizedBox(height: 10),
                      GlucoseDeltaCard(
                        currentValue: parsedGlucose,
                        readingType: state.readingType,
                        recentLogs: state.recentLogs,
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 18),
        const FormSectionLabel(
          icon: Icons.local_dining_rounded,
          title: 'Meal tag',
        ),
        const SizedBox(height: 10),
        MealTagChips(selected: state.mealTag, onSelected: cubit.setMealTag),
        const SizedBox(height: 18),
        const FormSectionLabel(icon: Icons.event_rounded, title: 'Timestamp'),
        const SizedBox(height: 10),
        TimestampPickerTile(
          timestamp: state.timestamp,
          onTap: onPickTimestamp,
          enabled: !saving,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: state.validationMessage == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _ValidationBanner(message: state.validationMessage!),
                ),
        ),
        const SizedBox(height: 20),
        SaveReadingButton(
          onPressed: saving ? null : cubit.submit,
          saving: saving,
        ),
      ],
    );
  }
}

class _ValidationBanner extends StatelessWidget {
  const _ValidationBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.destructive.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: AppColors.destructive,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.destructive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentLogsHeader extends StatelessWidget {
  const _RecentLogsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary400, AppColors.primary700],
            ),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Recent logs',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary100,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.primary200),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary700,
            ),
          ),
        ),
      ],
    );
  }
}
