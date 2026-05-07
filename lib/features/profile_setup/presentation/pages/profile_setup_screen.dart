import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/gluco_sliver_app_bar.dart';
import '../../../../core/widgets/soft_blob_background.dart';
import '../../../reminders/presentation/widgets/gluco_app_bar_reminders_actions.dart';
import '../../../profile/data/user_profile_store.dart';
import '../utils/bmi_utils.dart';
import '../widgets/avatar/profile_avatar_picker.dart';
import '../widgets/cards/bmi_display_card.dart';
import '../widgets/cards/glucose_target_range_card.dart';
import '../widgets/cards/height_weight_row.dart';
import '../widgets/cards/metabolic_context_card.dart';
import '../widgets/cards/personal_info_section.dart';
import '../widgets/continue/profile_continue_gradient_button.dart';
import '../widgets/header/profile_setup_header.dart';
import 'medical_details_screen.dart';

/// Profile setup — metabolic profile UI (no backend).
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _heightCm = TextEditingController();
  final _weightKg = TextEditingController();

  /// Starts at 0–0 mg/dL until the user adjusts the range slider.
  RangeValues _glucoseRange = const RangeValues(0, 0);

  String? _biologicalSex;
  DiabetesType _diabetes = DiabetesType.none;
  bool _familyHistory = false;

  @override
  void initState() {
    super.initState();
    _heightCm.addListener(_onMetricsChanged);
    _weightKg.addListener(_onMetricsChanged);
  }

  @override
  void dispose() {
    _heightCm.removeListener(_onMetricsChanged);
    _weightKg.removeListener(_onMetricsChanged);
    _name.dispose();
    _age.dispose();
    _heightCm.dispose();
    _weightKg.dispose();
    super.dispose();
  }

  void _onMetricsChanged() => setState(() {});

  double? get _bmi {
    final h = int.tryParse(_heightCm.text.trim());
    final w = double.tryParse(_weightKg.text.trim());
    if (h == null || w == null) return null;
    return computeBmi(heightCm: h, weightKg: w);
  }

  void _onContinue() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final age = int.tryParse(_age.text.trim());
    final h = int.tryParse(_heightCm.text.trim());
    final w = double.tryParse(_weightKg.text.trim());
    final minT = _glucoseRange.start.round();
    final maxT = _glucoseRange.end.round();

    if (age == null ||
        h == null ||
        w == null ||
        _biologicalSex == null) {
      AppToast.show(
        context,
        message: 'Please complete all required profile fields.',
        variant: AppToastVariant.error,
      );
      return;
    }
    if (minT >= maxT) {
      AppToast.show(
        context,
        message: 'Set your glucose target so the minimum is below the maximum.',
        variant: AppToastVariant.error,
      );
      return;
    }
    if (minT < 40 || maxT > 400) {
      AppToast.show(
        context,
        message: 'Keep your target range between 40 and 400 mg/dL.',
        variant: AppToastVariant.error,
      );
      return;
    }

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MedicalDetailsScreen(
          fullName: _name.text.trim(),
          age: age,
          biologicalSex: _biologicalSex!,
          heightCm: h,
          weightKg: w,
          bmi: _bmi,
          diabetesTypeLabel: _diabetes == DiabetesType.none
              ? 'None'
              : _diabetes == DiabetesType.type1
                  ? 'Type 1'
                  : _diabetes == DiabetesType.type2
                      ? 'Type 2'
                      : 'Pre-diabetes',
          familyHistory: _familyHistory,
          targetMinMgDl: minT,
          targetMaxMgDl: maxT,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: SoftBlobBackground(
        profileSoft: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final hPad = (maxW * 0.055).clamp(16.0, 28.0);
            final contentMax = maxW.clamp(0, 520).toDouble();
            final sectionGap = (maxW * 0.045).clamp(14.0, 20.0);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                GlucoSliverAppBar(
                  title: 'Tell us about you',
                  subtitle: 'Set up your profile',
                  actions: glucoAppBarRemindersActions(),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMax),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const ProfileSetupIntro(),
                              SizedBox(height: (maxW * 0.04).clamp(14.0, 20.0)),
                              ProfileAvatarPicker(
                                onImageBytesPicked: (bytes) =>
                                    UserProfileStore.setAvatarBytes(bytes),
                              ),
                              SizedBox(height: sectionGap),
                              PersonalInfoSection(
                                nameController: _name,
                                ageController: _age,
                                biologicalSex: _biologicalSex,
                                onSexChanged: (v) =>
                                    setState(() => _biologicalSex = v),
                              ),
                              SizedBox(height: sectionGap),
                              HeightWeightRow(
                                heightController: _heightCm,
                                weightController: _weightKg,
                              ),
                              SizedBox(height: sectionGap),
                              BmiDisplayCard(bmi: _bmi),
                              SizedBox(height: sectionGap),
                              MetabolicContextCard(
                                diabetesType: _diabetes,
                                onDiabetesChanged: (v) =>
                                    setState(() => _diabetes = v),
                                familyHistory: _familyHistory,
                                onFamilyHistoryChanged: (v) =>
                                    setState(() => _familyHistory = v),
                              ),
                              SizedBox(height: sectionGap),
                              GlucoseTargetRangeCard(
                                values: _glucoseRange,
                                onChanged: (v) =>
                                    setState(() => _glucoseRange = v),
                              ),
                              SizedBox(height: (maxW * 0.07).clamp(22.0, 30.0)),
                              ProfileContinueGradientButton(
                                onPressed: _onContinue,
                              ),
                              SizedBox(height: (maxW * 0.04).clamp(12.0, 16.0)),
                              Text(
                                'You can always update this later in your '
                                'Profile settings.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  height: 1.45,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
