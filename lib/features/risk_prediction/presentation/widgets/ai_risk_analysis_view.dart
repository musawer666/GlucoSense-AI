import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/widgets/app_result_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../domain/entities/risk_output.dart';
import '../../domain/services/saved_ml_risk_mapper.dart';
import '../bloc/risk_prediction_bloc.dart';

String _fmtRiskSavedAt(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  final y = d.year;
  final hh = d.hour.toString().padLeft(2, '0');
  final min = d.minute.toString().padLeft(2, '0');
  return '$mm/$dd/$y · $hh:$min';
}

enum RiskResultFooterHint { currentSession, savedOnProfile }

String _riskResultFooterCaption(RiskResultFooterHint hint) {
  switch (hint) {
    case RiskResultFooterHint.currentSession:
      return 'Leaving this tab clears this until you run analysis again.';
    case RiskResultFooterHint.savedOnProfile:
      return 'Saved to your account — also shown on Home and Log. '
          'Run analysis again to refresh.';
  }
}

/// Risk-analysis content for the Risk Prediction screen.
///
/// All state comes from [RiskPredictionBloc] — this widget is a
/// pure consumer. Editable profile chips dispatch [RiskProfileFieldsPatched]
/// (Firebase). Latest glucose values are read-only and come from Firestore.
class AiRiskAnalysisView extends StatelessWidget {
  const AiRiskAnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RiskPredictionBloc, RiskPredictionState>(
      listenWhen: (prev, curr) =>
          prev.errorMessage != curr.errorMessage ||
          prev.lastMutation != curr.lastMutation ||
          prev.toastMessage != curr.toastMessage,
      listener: _onStateChanged,
      builder: (context, state) {
        switch (state.status) {
          case RiskStatus.initial:
          case RiskStatus.loading:
            return const _LoadingBlock();
          case RiskStatus.failure when state.profile == null:
            return _ErrorBlock(
              message: state.errorMessage ?? 'Could not load your profile.',
              onRetry: () =>
                  context.read<RiskPredictionBloc>().add(const RiskSubscribed()),
            );
          case RiskStatus.missingProfile:
            return const _MissingProfileBlock();
          case RiskStatus.ready:
          case RiskStatus.updating:
          case RiskStatus.failure:
            return _ReadyBlock(state: state);
        }
      },
    );
  }

  void _onStateChanged(BuildContext context, RiskPredictionState state) {
    if (state.errorMessage != null && state.profile != null) {
      AppResultDialog.show(
        context,
        variant: AppResultVariant.error,
        message: state.errorMessage,
      );
      context.read<RiskPredictionBloc>().add(const RiskMutationAcknowledged());
      return;
    }
    final toast = state.toastMessage;
    if (toast != null) {
      AppToast.show(
        context,
        message: toast,
        variant: state.toastIsError
            ? AppToastVariant.error
            : AppToastVariant.info,
      );
      context.read<RiskPredictionBloc>().add(const RiskToastAcknowledged());
      return;
    }
    if (state.lastMutation != null) {
      context.read<RiskPredictionBloc>().add(const RiskMutationAcknowledged());
    }
  }
}

// ── Ready / editing block ─────────────────────────────────────────

class _ReadyBlock extends StatelessWidget {
  const _ReadyBlock({required this.state});
  final RiskPredictionState state;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile!;
    final missing = state.missingFields;

    final saved = savedMlRiskFromUserProfile(profile);
    final live = state.result;
    final display = live ?? saved;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (display != null) ...[
          if (live != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Current run',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            )
          else if (saved != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                profile.lastMlRiskAt != null
                    ? 'Last saved · ${_fmtRiskSavedAt(profile.lastMlRiskAt!)}'
                    : 'Last saved to your profile',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          _ResultCard(
            result: display,
            footerHint: live != null
                ? RiskResultFooterHint.currentSession
                : RiskResultFooterHint.savedOnProfile,
          ),
          const SizedBox(height: 12),
        ],
        _SectionCard(
          title: 'Saved Profile Data',
          icon: Icons.badge_outlined,
          child: Padding(
            padding: const EdgeInsets.only(left: 6, right: 2),
            child: _TwoColumnWrap(
              children: _profileChips(context, profile),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Latest Glucose Inputs',
          icon: Icons.monitor_heart_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'These values are read-only here. They update from Firestore '
                'when you log fasting, pre-meal, or post-meal readings on the '
                'Log tab.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 6, right: 2),
                child: _TwoColumnWrap(
                  children: _glucoseChips(profile),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (missing.isNotEmpty)
          _SectionCard(
            title: 'Missing Required Fields',
            icon: Icons.error_outline_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...missing.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.radio_button_unchecked_rounded,
                          size: 14,
                          color: AppColors.destructive,
                        ),
                        const SizedBox(width: 6),
                        Expanded(child: Text(e)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _missingFieldsHint(missing),
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        if (missing.isNotEmpty) const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: state.canTapRunAnalysis
              ? () => context
                  .read<RiskPredictionBloc>()
                  .add(const RiskAnalysisRequested())
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary600,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: AppColors.neutral300,
            disabledForegroundColor: AppColors.neutral700,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.psychology_alt_rounded),
          label: const Text('Run Diabetes Risk Analysis'),
        ),
      ],
    );

    return Stack(
      children: [
        content,
        if (state.isUpdating || state.isPredictionLoading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.white.withValues(alpha: 0.35),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static const _glucoseMissingLabels = {
    'Fasting glucose reading',
    'Pre-meal glucose reading',
    'Post-meal glucose reading',
  };

  String _missingFieldsHint(List<String> missing) {
    final needsGlucose =
        missing.any((e) => _glucoseMissingLabels.contains(e));
    final needsProfile = missing.any((e) => !_glucoseMissingLabels.contains(e));

    if (needsGlucose && needsProfile) {
      return 'Use the Log tab to add glucose readings. For other items, tap '
          'an editable chip under Saved Profile Data — changes sync to '
          'Firebase automatically.';
    }
    if (needsGlucose) {
      return 'Log fasting, pre-meal, and post-meal readings on the Log tab. '
          'Those saves update Firestore and will appear here automatically.';
    }
    return 'Tap an editable chip under Saved Profile Data — changes are saved '
        'to Firebase automatically.';
  }

  // ── Chip builders (profile: editable → Firebase; glucose: read-only) ─

  List<Widget> _profileChips(BuildContext context, UserProfile p) {
    return [
      _EditableDataChip(
        label: 'Age',
        value: p.age > 0 ? '${p.age}' : '--',
        icon: Icons.cake_outlined,
        onTap: () => _editNumber(
          context,
          title: 'Update age',
          initial: p.age > 0 ? '${p.age}' : '',
          keyboardType: TextInputType.number,
          onSave: (raw) {
            final age = int.tryParse(raw);
            if (age == null || age <= 0 || age > 120) return null;
            return {'age': age};
          },
        ),
      ),
      _EditableDataChip(
        label: 'Gender',
        value: p.biologicalSex.isEmpty ? '--' : p.biologicalSex,
        icon: Icons.wc_rounded,
        onTap: () => _editOption(
          context,
          title: 'Update gender',
          options: const ['Male', 'Female', 'Other'],
          onSave: (v) => {'biologicalSex': v},
        ),
      ),
      _EditableDataChip(
        label: 'BMI',
        value: p.bmi?.toStringAsFixed(1) ?? '--',
        icon: Icons.monitor_weight_outlined,
        onTap: () => _editNumber(
          context,
          title: 'Update BMI',
          initial: p.bmi?.toStringAsFixed(1) ?? '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onSave: (raw) {
            final bmi = double.tryParse(raw);
            if (bmi == null || bmi <= 0 || bmi > 80) return null;
            return {'bmi': bmi};
          },
        ),
      ),
      _EditableDataChip(
        label: 'Family History',
        value: p.familyHistory ? 'Yes' : 'No',
        icon: Icons.family_restroom_rounded,
        onTap: () => _editOption(
          context,
          title: 'Family history of diabetes',
          options: const ['Yes', 'No'],
          onSave: (v) => {'familyHistory': v == 'Yes'},
        ),
      ),
      _EditableDataChip(
        label: 'Hypertension',
        value: p.hypertension ? 'Yes' : 'No',
        icon: Icons.favorite_border_rounded,
        onTap: () => _editOption(
          context,
          title: 'Hypertension',
          options: const ['Yes', 'No'],
          onSave: (v) => {'hypertension': v == 'Yes'},
        ),
      ),
      _EditableDataChip(
        label: 'Heart Disease',
        value: p.heartDisease ? 'Yes' : 'No',
        icon: Icons.heart_broken_outlined,
        onTap: () => _editOption(
          context,
          title: 'Heart disease',
          options: const ['Yes', 'No'],
          onSave: (v) => {'heartDisease': v == 'Yes'},
        ),
      ),
      _EditableDataChip(
        label: 'Smoking',
        value: p.smokingLabel.isEmpty ? '--' : p.smokingLabel,
        icon: Icons.smoke_free_rounded,
        onTap: () => _editOption(
          context,
          title: 'Smoking history',
          options: const ['Current', 'Former', 'Never'],
          onSave: (v) => {'smokingLabel': v},
        ),
      ),
      _EditableDataChip(
        label: 'Activity',
        value: p.activityLabel.isEmpty ? '--' : p.activityLabel,
        icon: Icons.directions_run_rounded,
        onTap: () => _editOption(
          context,
          title: 'Activity level',
          options: const ['Sedentary', 'Moderate', 'Active'],
          onSave: (v) => {'activityLabel': v},
        ),
      ),
      _EditableDataChip(
        label: 'HbA1c',
        value: p.hba1c?.toStringAsFixed(1) ?? '--',
        icon: Icons.opacity_rounded,
        onTap: () => _editNumber(
          context,
          title: 'Update HbA1c (%)',
          initial: p.hba1c?.toStringAsFixed(1) ?? '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onSave: (raw) {
            if (raw.isEmpty) return {'hba1c': null};
            final v = double.tryParse(raw);
            if (v == null || v <= 0 || v > 20) return null;
            return {'hba1c': v};
          },
        ),
      ),
      _EditableDataChip(
        label: 'Medication',
        value: (p.medication == null || p.medication!.isEmpty)
            ? '--'
            : p.medication!,
        icon: Icons.medication_outlined,
        onTap: () => _editText(
          context,
          title: 'Update medication',
          initial: p.medication ?? '',
          onSave: (raw) =>
              {'medication': raw.trim().isEmpty ? null : raw.trim()},
        ),
      ),
    ];
  }

  List<Widget> _glucoseChips(UserProfile p) {
    return [
      _EditableDataChip(
        label: 'Fasting',
        value: p.latestFastingMgDl != null
            ? '${p.latestFastingMgDl} mg/dL'
            : '--',
        icon: Icons.wb_sunny_outlined,
        onTap: null,
      ),
      _EditableDataChip(
        label: 'Pre-Meal',
        value: p.latestPreMealMgDl != null
            ? '${p.latestPreMealMgDl} mg/dL'
            : '--',
        icon: Icons.restaurant_outlined,
        onTap: null,
      ),
      _EditableDataChip(
        label: 'Post-Meal',
        value: p.latestPostMealMgDl != null
            ? '${p.latestPostMealMgDl} mg/dL'
            : '--',
        icon: Icons.local_dining_outlined,
        onTap: null,
      ),
    ];
  }

  // ── Edit flows ────────────────────────────────────────────────

  Future<void> _editNumber(
    BuildContext context, {
    required String title,
    required String initial,
    required TextInputType keyboardType,
    required Map<String, dynamic>? Function(String raw) onSave,
  }) async {
    final raw = await _showTextSheet(
      context,
      title: title,
      initial: initial,
      keyboardType: keyboardType,
    );
    if (raw == null) return;
    final patch = onSave(raw.trim());
    if (patch == null) return;
    if (!context.mounted) return;
    _dispatch(context, patch);
  }

  Future<void> _editText(
    BuildContext context, {
    required String title,
    required String initial,
    required Map<String, dynamic> Function(String raw) onSave,
  }) async {
    final raw = await _showTextSheet(
      context,
      title: title,
      initial: initial,
      keyboardType: TextInputType.text,
    );
    if (raw == null) return;
    if (!context.mounted) return;
    _dispatch(context, onSave(raw));
  }

  Future<void> _editOption(
    BuildContext context, {
    required String title,
    required List<String> options,
    required Map<String, dynamic> Function(String value) onSave,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ...options.map(
              (e) => ListTile(
                title: Text(e),
                onTap: () => Navigator.of(ctx).pop(e),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
    if (selected == null) return;
    if (!context.mounted) return;
    _dispatch(context, onSave(selected));
  }

  void _dispatch(BuildContext context, Map<String, dynamic> patch) {
    if (patch.isEmpty) return;
    context.read<RiskPredictionBloc>()
      ..add(const RiskResultCleared())
      ..add(RiskProfileFieldsPatched(patch));
  }

  Future<String?> _showTextSheet(
    BuildContext context, {
    required String title,
    required String initial,
    required TextInputType keyboardType,
    String? suffix,
  }) async {
    final controller = TextEditingController(text: initial);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                suffixText: suffix,
                filled: true,
                fillColor: AppColors.neutral100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary600,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status blocks ─────────────────────────────────────────────────

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(strokeWidth: 2.6),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Could not load your data',
      icon: Icons.error_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary600,
              foregroundColor: AppColors.onPrimary,
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _MissingProfileBlock extends StatelessWidget {
  const _MissingProfileBlock();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Profile not set up yet',
      icon: Icons.person_outline_rounded,
      child: Text(
        'Complete Profile Setup and Medical Details first — the risk '
        'analysis uses those values as its foundation.',
        style: GoogleFonts.inter(color: AppColors.textSecondary),
      ),
    );
  }
}

// ── Result card ───────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.footerHint,
  });

  final RiskOutput result;
  final RiskResultFooterHint footerHint;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(result.level);
    final dark = Color.lerp(color, Colors.black, 0.35) ?? color;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [dark, color],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'AI Risk Result',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.label,
            style: GoogleFonts.manrope(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Text(
              'Confidence ${result.confidence}%',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: dark,
              ),
            ),
          ),
          if (result.classProbabilitiesPercent != null &&
              result.classProbabilitiesPercent!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Model probabilities',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.classProbabilitiesPercent!.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    '${e.key}  ${e.value.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            result.explanation,
            style: GoogleFonts.inter(
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.94),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _riskResultFooterCaption(footerHint),
            style: GoogleFonts.inter(
              fontSize: 11.5,
              height: 1.35,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(RiskLevel level) {
    switch (level) {
      case RiskLevel.normal:
        return AppColors.primary700;
      case RiskLevel.prediabetic:
        return AppColors.tertiary700;
      case RiskLevel.diabetic:
        return const Color(0xFFB91C1C);
    }
  }
}

// ── Layout helpers ────────────────────────────────────────────────

class _TwoColumnWrap extends StatelessWidget {
  const _TwoColumnWrap({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const spacing = 8.0;
        final width = (c.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}

class _EditableDataChip extends StatelessWidget {
  const _EditableDataChip({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  /// When null, the chip is read-only (e.g. glucose from Firestore only).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _chipPalette(label);
    final readOnly = onTap == null;
    return Tooltip(
      message: readOnly
          ? 'Synced from Firestore when you log readings'
          : 'Tap to edit (saved to Firebase)',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minWidth: 152, minHeight: 74),
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow.withValues(alpha: 0.18),
                  blurRadius: 7,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: palette.border),
                  ),
                  child: Icon(icon, size: 16, color: palette.iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: palette.titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: palette.valueColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.neutral300),
                  ),
                  child: Icon(
                    readOnly ? Icons.cloud_done_outlined : Icons.edit_outlined,
                    size: 12,
                    color: palette.iconColor.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _RiskChipPalette _chipPalette(String key) {
    final k = key.toLowerCase();
    if (k.contains('hba1c') ||
        k.contains('fasting') ||
        k.contains('pre-meal') ||
        k.contains('post-meal')) {
      return const _RiskChipPalette(
        background: Color(0xFFF4F8FF),
        border: Color(0xFFCDDCF7),
        iconColor: Color(0xFF2F5EA8),
        titleColor: Color(0xFF405B8A),
        valueColor: Color(0xFF162D59),
        shadow: Color(0xFFBCD0F5),
      );
    }
    if (k.contains('hypertension') || k.contains('heart')) {
      return const _RiskChipPalette(
        background: Color(0xFFFFF6F4),
        border: Color(0xFFF4D5CD),
        iconColor: Color(0xFF9B3B2A),
        titleColor: Color(0xFF8D4C42),
        valueColor: Color(0xFF4A1F18),
        shadow: Color(0xFFF1BCAD),
      );
    }
    return const _RiskChipPalette(
      background: Color(0xFFF3FFFD),
      border: Color(0xFFC9F1EA),
      iconColor: Color(0xFF0D6A62),
      titleColor: Color(0xFF2E6B66),
      valueColor: Color(0xFF0F1E33),
      shadow: Color(0xFFA8E5D7),
    );
  }
}

class _RiskChipPalette {
  const _RiskChipPalette({
    required this.background,
    required this.border,
    required this.iconColor,
    required this.titleColor,
    required this.valueColor,
    required this.shadow,
  });

  final Color background;
  final Color border;
  final Color iconColor;
  final Color titleColor;
  final Color valueColor;
  final Color shadow;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    required this.icon,
  });

  final String title;
  final Widget child;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.primary100,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: AppColors.primary700),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: AppColors.neutral200),
          const SizedBox(height: 8),
          DefaultTextStyle(
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.4,
              color: AppColors.neutral700,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
