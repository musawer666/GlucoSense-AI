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
import '../../../log_reading/data/datasources/glucose_log_remote_data_source.dart';
import '../../../log_reading/data/repositories/glucose_log_repository_impl.dart';
import '../../data/datasources/reminder_remote_data_source.dart';
import '../../data/repositories/reminder_repository_impl.dart';
import '../../domain/entities/snack_reminder.dart';
import '../cubit/reminders_cubit.dart';
import '../cubit/reminders_state.dart';
import '../widgets/add_snack_reminder_sheet.dart';
import '../widgets/delivery_reliability_banner.dart';
import '../widgets/fasting_reminder_card.dart';
import '../widgets/meal_reminder_card.dart';
import '../widgets/reminders_master_switch.dart';
import '../widgets/snack_reminders_section.dart';

/// Full settings screen for meal + fasting + snack reminders.
///
/// Follows the project's conventional entry pattern: wraps a
/// `BlocProvider` that provisions the cubit + repositories, then
/// renders the presentation body.
class RemindersSettingsScreen extends StatelessWidget {
  const RemindersSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RemindersCubit>(
      create: (_) => RemindersCubit(
        reminderRepository: ReminderRepositoryImpl(
          remoteDataSource: ReminderRemoteDataSourceImpl(),
        ),
        logRepository: GlucoseLogRepositoryImpl(
          remoteDataSource: GlucoseLogRemoteDataSourceImpl(),
        ),
        authRepository: AuthRepositoryImpl(
          remoteDataSource: AuthRemoteDataSourceImpl(),
        ),
      )..subscribe(),
      child: const _RemindersView(),
    );
  }
}

class _RemindersView extends StatelessWidget {
  const _RemindersView();

  Future<void> _addSnack(BuildContext context) async {
    final cubit = context.read<RemindersCubit>();
    final draft = await AddSnackReminderSheet.show(context);
    if (draft == null) return;
    await cubit.addSnack(
      label: draft.label,
      time: draft.time,
      daysOfWeek: draft.daysOfWeek,
    );
  }

  Future<void> _editSnack(
    BuildContext context,
    SnackReminder snack,
  ) async {
    final cubit = context.read<RemindersCubit>();
    final edited = await AddSnackReminderSheet.show(context, initial: snack);
    if (edited == null) return;
    await cubit.updateSnack(snack.copyWith(
      label: edited.label,
      time: edited.time,
      daysOfWeek: edited.daysOfWeek,
    ));
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SnackReminder snack,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text('"${snack.label}" will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<RemindersCubit>().removeSnack(snack.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: BlocConsumer<RemindersCubit, RemindersState>(
        listenWhen: (p, c) =>
            p.errorMessage != c.errorMessage &&
            c.errorMessage != null &&
            c.status == RemindersStatus.error,
        listener: (context, state) {
          if (state.errorMessage == null) return;
          AppResultDialog.show(
            context,
            variant: AppResultVariant.error,
            title: 'Reminders update failed',
            message: state.errorMessage!,
            autoDismiss: false,
          );
        },
        builder: (context, state) {
          final cubit = context.read<RemindersCubit>();
          final loading = state.status == RemindersStatus.initial ||
              state.status == RemindersStatus.loading;

          return SoftBlobBackground(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final pad = (w * 0.055).clamp(16.0, 22.0);

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const GlucoSliverAppBar(title: 'Reminders'),
                    if (loading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: AppInlineLoader()),
                      )
                    else
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(pad, 18, pad, 48),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const DeliveryReliabilityBanner(),
                              const SizedBox(height: 14),
                              RemindersMasterSwitch(
                                value: state.settings.masterEnabled,
                                enabled: state.status !=
                                    RemindersStatus.saving,
                                onChanged: cubit.setMasterEnabled,
                              ),
                              const SizedBox(height: 20),
                              _SectionHeader(
                                title: 'Morning',
                                subtitle:
                                    'Capture your baseline the moment you wake up.',
                                icon: Icons.wb_sunny_rounded,
                              ),
                              const SizedBox(height: 10),
                              FastingReminderCard(
                                enabled: state.settings.fastingEnabled,
                                time: state.settings.fastingTime,
                                interactive:
                                    state.settings.masterEnabled,
                                onEnabledChanged: cubit.setFastingEnabled,
                                onTimeChanged: cubit.setFastingTime,
                              ),
                              const SizedBox(height: 22),
                              _SectionHeader(
                                title: 'Meals',
                                subtitle:
                                    'Pre and post-meal pings so you capture the full picture.',
                                icon: Icons.restaurant_rounded,
                              ),
                              const SizedBox(height: 10),
                              _MealList(state: state, cubit: cubit),
                              const SizedBox(height: 22),
                              _SectionHeader(
                                title: 'Snacks',
                                subtitle: 'Add your own snack time reminders.',
                                icon: Icons.cookie_rounded,
                              ),
                              const SizedBox(height: 10),
                              SnackRemindersSection(
                                snacks: state.settings.snacks,
                                interactive:
                                    state.settings.masterEnabled &&
                                        state.status !=
                                            RemindersStatus.saving,
                                onAddTap: () => _addSnack(context),
                                onEdit: (s) => _editSnack(context, s),
                                onDelete: (s) => _confirmDelete(context, s),
                                onToggle: (s, v) =>
                                    cubit.setSnackEnabled(s.id, v),
                              ),
                              const SizedBox(height: 22),
                              _InlineHint(
                                text:
                                    'Reminders are rescheduled each time you open the app. Keep this app updated in the background for best reliability.',
                              ),
                              const SizedBox(height: 8),
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
      ),
    );
  }
}

class _MealList extends StatelessWidget {
  const _MealList({required this.state, required this.cubit});

  final RemindersState state;
  final RemindersCubit cubit;

  @override
  Widget build(BuildContext context) {
    final slots = [
      state.settings.breakfast,
      state.settings.lunch,
      state.settings.dinner,
    ];

    return Column(
      children: [
        for (var i = 0; i < slots.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          MealReminderCard(
            slot: slots[i],
            interactive: state.settings.masterEnabled &&
                state.status != RemindersStatus.saving,
            onEnabledChanged: (v) =>
                cubit.setSlotEnabled(slots[i].mealTag, v),
            onPreMealEnabledChanged: (v) =>
                cubit.setPreMealEnabled(slots[i].mealTag, v),
            onPostMealEnabledChanged: (v) =>
                cubit.setPostMealEnabled(slots[i].mealTag, v),
            onPreMealTimeChanged: (t) =>
                cubit.setPreMealTime(slots[i].mealTag, t),
            onPostMealTimeChanged: (t) =>
                cubit.setPostMealTime(slots[i].mealTag, t),
            onDaysChanged: (d) => cubit.setSlotDays(slots[i].mealTag, d),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary700),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineHint extends StatelessWidget {
  const _InlineHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary100),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.primary700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
