import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/widgets/app_result_dialog.dart';
import '../../../../core/widgets/gluco_sliver_app_bar.dart';
import '../../../../core/widgets/soft_blob_background.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../reminders/presentation/widgets/gluco_app_bar_reminders_actions.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../../profile/data/user_profile_store.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/profile_display_data.dart';
import '../../../profile/presentation/bloc/profile_setup_bloc.dart';
import '../widgets/cards/profile_white_card.dart';
import '../widgets/continue/profile_continue_gradient_button.dart';
import 'profile_setup_complete_placeholder_screen.dart';

enum SmokingHistory { current, former, never }

enum ActivityLevel { sedentary, moderate, active }

/// Full-width custom segmented row: green fill sits flush in the track (no odd inner pill).
class _MedicalSegmentRow<T> extends StatelessWidget {
  const _MedicalSegmentRow({
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  static const double _outerR = 14;
  static const double _innerR = 10;

  @override
  Widget build(BuildContext context) {
    assert(values.length == labels.length, 'values and labels must match');
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 360;
        final fs = narrow && values.length > 2 ? 12.5 : 14.0;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_outerR),
            border: Border.all(
              color: AppColors.neutral200.withValues(alpha: 0.9),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary900.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_innerR),
            child: ColoredBox(
              color: AppColors.neutral100,
              child: Row(
                children: List.generate(values.length, (i) {
                  final v = values[i];
                  final sel = selected == v;
                  return Expanded(
                    child: _SegmentCell(
                      label: labels[i],
                      selected: sel,
                      fontSize: fs,
                      onTap: () => onChanged(v),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SegmentCell extends StatelessWidget {
  const _SegmentCell({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.fontSize,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primary200.withValues(alpha: 0.35),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: selected ? AppColors.primary600 : Colors.transparent,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.onPrimary : AppColors.neutral700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Second profile step — conditions, lifestyle, clinical metrics.
///
/// Route-level wrapper: wires up the profile + auth repository graph
/// and provisions a [ProfileSetupBloc] so the view below can stay
/// pure and focus on UI / form state only.
class MedicalDetailsScreen extends StatelessWidget {
  const MedicalDetailsScreen({
    super.key,
    required this.fullName,
    required this.age,
    required this.biologicalSex,
    required this.heightCm,
    required this.weightKg,
    required this.bmi,
    required this.diabetesTypeLabel,
    required this.familyHistory,
    required this.targetMinMgDl,
    required this.targetMaxMgDl,
  });

  final String fullName;
  final int age;
  final String biologicalSex;
  final int heightCm;
  final double weightKg;
  final double? bmi;
  final String diabetesTypeLabel;
  final bool familyHistory;
  final int targetMinMgDl;
  final int targetMaxMgDl;

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSourceImpl(),
    );
    final profileRepository = ProfileRepositoryImpl(
      remoteDataSource: ProfileRemoteDataSourceImpl(),
    );
    return BlocProvider<ProfileSetupBloc>(
      create: (_) => ProfileSetupBloc(profileRepository: profileRepository),
      child: _MedicalDetailsView(
        authRepository: authRepository,
        fullName: fullName,
        age: age,
        biologicalSex: biologicalSex,
        heightCm: heightCm,
        weightKg: weightKg,
        bmi: bmi,
        diabetesTypeLabel: diabetesTypeLabel,
        familyHistory: familyHistory,
        targetMinMgDl: targetMinMgDl,
        targetMaxMgDl: targetMaxMgDl,
      ),
    );
  }
}

class _MedicalDetailsView extends StatefulWidget {
  const _MedicalDetailsView({
    required this.authRepository,
    required this.fullName,
    required this.age,
    required this.biologicalSex,
    required this.heightCm,
    required this.weightKg,
    required this.bmi,
    required this.diabetesTypeLabel,
    required this.familyHistory,
    required this.targetMinMgDl,
    required this.targetMaxMgDl,
  });

  final AuthRepository authRepository;
  final String fullName;
  final int age;
  final String biologicalSex;
  final int heightCm;
  final double weightKg;
  final double? bmi;
  final String diabetesTypeLabel;
  final bool familyHistory;
  final int targetMinMgDl;
  final int targetMaxMgDl;

  @override
  State<_MedicalDetailsView> createState() => _MedicalDetailsViewState();
}

class _MedicalDetailsViewState extends State<_MedicalDetailsView> {
  bool _hypertension = false;
  bool _heartDisease = false;
  SmokingHistory _smoking = SmokingHistory.never;
  ActivityLevel _activity = ActivityLevel.moderate;

  final _hba1c = TextEditingController();
  final _medication = TextEditingController();

  @override
  void dispose() {
    _hba1c.dispose();
    _medication.dispose();
    super.dispose();
  }

  String get _smokingLabel => switch (_smoking) {
        SmokingHistory.current => 'Current',
        SmokingHistory.former => 'Former',
        SmokingHistory.never => 'Never',
      };

  String get _activityLabel => switch (_activity) {
        ActivityLevel.sedentary => 'Sedentary',
        ActivityLevel.moderate => 'Moderate',
        ActivityLevel.active => 'Active',
      };

  void _onSaveContinue() {
    FocusScope.of(context).unfocus();

    final currentUser = widget.authRepository.getCurrentUser();
    if (currentUser == null) {
      AppResultDialog.show(
        context,
        variant: AppResultVariant.error,
        title: 'Session expired',
        message: 'Please sign in again to save your profile.',
        autoDismiss: false,
      );
      return;
    }

    final hba1cText = _hba1c.text.trim();
    final medicationText = _medication.text.trim();
    final hba1cValue = hba1cText.isEmpty ? null : double.tryParse(hba1cText);

    final profile = UserProfile(
      uid: currentUser.uid,
      email: currentUser.email,
      fullName: widget.fullName,
      age: widget.age,
      biologicalSex: widget.biologicalSex,
      heightCm: widget.heightCm,
      weightKg: widget.weightKg,
      bmi: widget.bmi,
      diabetesTypeLabel: widget.diabetesTypeLabel,
      familyHistory: widget.familyHistory,
      hypertension: _hypertension,
      heartDisease: _heartDisease,
      smokingLabel: _smokingLabel,
      activityLabel: _activityLabel,
      hba1c: hba1cValue,
      medication: medicationText.isEmpty ? null : medicationText,
      targetGlucoseMinMgDl: widget.targetMinMgDl,
      targetGlucoseMaxMgDl: widget.targetMaxMgDl,
    );

    // Avatar was captured on step 1 and kept in memory by
    // `UserProfileStore.avatarBytes`. The Bloc uploads it to
    // Firebase Storage after the profile doc is written.
    final avatarBytes = UserProfileStore.avatarBytes;

    context.read<ProfileSetupBloc>().add(
          ProfileSetupSubmitted(
            profile: profile,
            avatarBytes: avatarBytes,
          ),
        );
  }

  /// Warms the legacy in-memory cache so the Profile tab shows the
  /// freshly-saved values immediately, without a second Firestore
  /// read on next navigation.
  void _syncLegacyCache(UserProfile saved) {
    UserProfileStore.setProfile(
      ProfileDisplayData(
        fullName: saved.fullName,
        email: saved.email ?? '',
        age: saved.age,
        biologicalSex: saved.biologicalSex,
        heightCm: saved.heightCm,
        weightKg: saved.weightKg,
        bmi: saved.bmi,
        diabetesTypeLabel: saved.diabetesTypeLabel,
        familyHistory: saved.familyHistory,
        hypertension: saved.hypertension,
        heartDisease: saved.heartDisease,
        smokingLabel: saved.smokingLabel,
        activityLabel: saved.activityLabel,
        hba1cDisplay: saved.hba1c?.toString(),
        medicationDisplay: saved.medication,
        targetGlucoseMinMgDl: saved.targetGlucoseMinMgDl,
        targetGlucoseMaxMgDl: saved.targetGlucoseMaxMgDl,
      ),
    );
  }

  Future<void> _onSaveSuccess(UserProfile saved) async {
    _syncLegacyCache(saved);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const ProfileSetupCompletePlaceholderScreen(),
      ),
      (_) => false,
    );
  }

  Future<void> _onSaveFailure(String message) async {
    await AppResultDialog.show(
      context,
      variant: AppResultVariant.error,
      title: 'Could not save profile',
      message: message,
      autoDismiss: false,
    );
    if (!mounted) return;
    context.read<ProfileSetupBloc>().add(const ProfileSetupStatusReset());
  }

  InputDecoration _clinicalDec(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFEDEDED),
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 15, color: AppColors.neutral500),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: BlocListener<ProfileSetupBloc, ProfileSetupState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          switch (state.status) {
            case ProfileSetupStatus.success:
              final saved = state.savedProfile;
              if (saved != null) _onSaveSuccess(saved);
              break;
            case ProfileSetupStatus.failure:
              _onSaveFailure(
                state.errorMessage ??
                    'Something went wrong. Please try again.',
              );
              break;
            case ProfileSetupStatus.initial:
            case ProfileSetupStatus.saving:
              break;
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SoftBlobBackground(
                profileSoft: true,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxW = constraints.maxWidth;
                    final hPad = (maxW * 0.055).clamp(16.0, 28.0);
                    final contentMax = maxW.clamp(0, 520).toDouble();
                    final gap = (maxW * 0.04).clamp(14.0, 18.0);

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        GlucoSliverAppBar(
                          title: 'Medical details',
                          subtitle: 'Conditions, lifestyle & clinical info',
                          showBackButton: true,
                          actions: glucoAppBarRemindersActions(),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(hPad, 10, hPad, gap),
                          sliver: SliverToBoxAdapter(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: contentMax,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Help us personalize your metabolic '
                                      'journey — answer what you can.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: (maxW * 0.038)
                                            .clamp(14.0, 16.0),
                                        height: 1.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    SizedBox(height: gap),
                                    _ConditionsCard(
                                      hypertension: _hypertension,
                                      heartDisease: _heartDisease,
                                      onHypertension: (v) =>
                                          setState(() => _hypertension = v),
                                      onHeartDisease: (v) =>
                                          setState(() => _heartDisease = v),
                                    ),
                                    SizedBox(height: gap),
                                    _LifestyleCard(
                                      smoking: _smoking,
                                      activity: _activity,
                                      onSmoking: (v) =>
                                          setState(() => _smoking = v),
                                      onActivity: (v) =>
                                          setState(() => _activity = v),
                                    ),
                                    SizedBox(height: gap),
                                    _ClinicalCard(
                                      hba1cController: _hba1c,
                                      medicationController: _medication,
                                      clinicalDec: _clinicalDec,
                                    ),
                                    SizedBox(height: gap),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth;
                  final hPad = (maxW * 0.055).clamp(16.0, 28.0);
                  final contentMax = maxW.clamp(0, 520).toDouble();
                  return Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMax),
                        child: BlocBuilder<ProfileSetupBloc,
                            ProfileSetupState>(
                          buildWhen: (prev, curr) =>
                              prev.status != curr.status,
                          builder: (context, state) {
                            final saving = state.isSaving;
                            return ProfileContinueGradientButton(
                              label: 'Save & Continue',
                              isLoading: saving,
                              onPressed: saving ? null : _onSaveContinue,
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConditionsCard extends StatelessWidget {
  const _ConditionsCard({
    required this.hypertension,
    required this.heartDisease,
    required this.onHypertension,
    required this.onHeartDisease,
  });

  final bool hypertension;
  final bool heartDisease;
  final ValueChanged<bool> onHypertension;
  final ValueChanged<bool> onHeartDisease;

  @override
  Widget build(BuildContext context) {
    return ProfileWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary600,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Conditions',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _yesNoRow(
            'Hypertension History',
            hypertension,
            onHypertension,
            showInfo: true,
          ),
          const SizedBox(height: 16),
          _yesNoRow(
            'Heart Disease',
            heartDisease,
            onHeartDisease,
          ),
        ],
      ),
    );
  }

  Widget _yesNoRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    bool showInfo = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (showInfo) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.neutral400,
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        _MedicalSegmentRow<bool>(
          values: const [true, false],
          labels: const ['Yes', 'No'],
          selected: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _LifestyleCard extends StatelessWidget {
  const _LifestyleCard({
    required this.smoking,
    required this.activity,
    required this.onSmoking,
    required this.onActivity,
  });

  final SmokingHistory smoking;
  final ActivityLevel activity;
  final ValueChanged<SmokingHistory> onSmoking;
  final ValueChanged<ActivityLevel> onActivity;

  @override
  Widget build(BuildContext context) {
    return ProfileWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_run,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Lifestyle',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Smoking History',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral700,
            ),
          ),
          const SizedBox(height: 10),
          _MedicalSegmentRow<SmokingHistory>(
            values: const [
              SmokingHistory.current,
              SmokingHistory.former,
              SmokingHistory.never,
            ],
            labels: const ['Current', 'Former', 'Never'],
            selected: smoking,
            onChanged: onSmoking,
          ),
          const SizedBox(height: 20),
          Text(
            'Activity Level',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral700,
            ),
          ),
          const SizedBox(height: 10),
          _ActivityTile(
            selected: activity == ActivityLevel.sedentary,
            icon: Icons.weekend_outlined,
            title: 'Sedentary',
            subtitle: 'Little to no exercise',
            onTap: () => onActivity(ActivityLevel.sedentary),
          ),
          const SizedBox(height: 10),
          _ActivityTile(
            selected: activity == ActivityLevel.moderate,
            icon: Icons.directions_walk,
            title: 'Moderate',
            subtitle: 'Light exercise 1-3 days/week',
            onTap: () => onActivity(ActivityLevel.moderate),
          ),
          const SizedBox(height: 10),
          _ActivityTile(
            selected: activity == ActivityLevel.active,
            icon: Icons.fitness_center,
            title: 'Active',
            subtitle: 'Hard exercise 3-5 days/week',
            onTap: () => onActivity(ActivityLevel.active),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.primary600 : AppColors.neutral200;
    final iconColor = selected ? AppColors.primary600 : AppColors.neutral600;

    return Material(
      color: selected ? AppColors.primary50 : AppColors.neutral100,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primary200.withValues(alpha: 0.35),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClinicalCard extends StatelessWidget {
  const _ClinicalCard({
    required this.hba1cController,
    required this.medicationController,
    required this.clinicalDec,
  });

  final TextEditingController hba1cController;
  final TextEditingController medicationController;
  final InputDecoration Function(String hint, {Widget? suffixIcon}) clinicalDec;

  @override
  Widget build(BuildContext context) {
    return ProfileWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.tertiary400,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Clinical Metrics',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'HbA1c Level (%)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral700,
                  ),
                ),
              ),
              _optionalChip(),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: hba1cController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: clinicalDec('e.g. 5.7').copyWith(
              suffixText: '%',
              suffixStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current Medication',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral700,
                  ),
                ),
              ),
              _optionalChip(),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: medicationController,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: clinicalDec(
              'e.g. Metformin, Statins',
              suffixIcon: const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.medication_outlined,
                  color: AppColors.neutral500,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionalChip() {
    return Text(
      'Optional',
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.neutral500,
      ),
    );
  }
}
