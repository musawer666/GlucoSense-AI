import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/widgets/app_result_dialog.dart';
import '../../domain/profile_display_data.dart';

/// Which profile row is being edited.
enum ProfileField {
  fullName,
  email,
  age,
  biologicalSex,
  heightCm,
  weightKg,
  bmi,
  diabetesType,
  familyHistory,
  hypertension,
  heartDisease,
  smoking,
  activity,
  hba1c,
  medication,
  targetRange,
}

const _kSex = ['Male', 'Female', 'Other'];
const _kDiabetes = ['None', 'Type 1', 'Type 2', 'Pre-diabetes'];
const _kSmoking = ['Current', 'Former', 'Never'];
const _kActivity = ['Sedentary', 'Moderate', 'Active'];

/// Opens a bottom sheet to update one field (or height+weight for BMI / range for targets).
Future<void> showProfileFieldEditor({
  required BuildContext context,
  required ProfileDisplayData current,
  required ProfileField field,
  required ValueChanged<ProfileDisplayData> onSaved,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return _ProfileEditSheet(
        initial: current,
        field: field,
        onSaved: (next) {
          Navigator.of(ctx).pop();
          onSaved(next);
        },
      );
    },
  );
}

class _ProfileEditSheet extends StatefulWidget {
  const _ProfileEditSheet({
    required this.initial,
    required this.field,
    required this.onSaved,
  });

  final ProfileDisplayData initial;
  final ProfileField field;
  final ValueChanged<ProfileDisplayData> onSaved;

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  late final TextEditingController _c1;
  late final TextEditingController _c2;
  String? _dropdownValue;
  bool? _boolVal;

  ProfileField get f => widget.field;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _c1 = TextEditingController();
    _c2 = TextEditingController();
    if (f == ProfileField.fullName) {
      _c1.text = d.fullName;
    } else if (f == ProfileField.email) {
      _c1.text = d.email;
    } else if (f == ProfileField.age) {
      _c1.text = '${d.age}';
    } else if (f == ProfileField.biologicalSex) {
      _dropdownValue =
          _kSex.contains(d.biologicalSex) ? d.biologicalSex : _kSex.first;
    } else if (f == ProfileField.heightCm) {
      _c1.text = '${d.heightCm}';
    } else if (f == ProfileField.weightKg) {
      _c1.text = d.weightKg.toStringAsFixed(1);
    } else if (f == ProfileField.bmi) {
      _c1.text = '${d.heightCm}';
      _c2.text = d.weightKg.toStringAsFixed(1);
    } else if (f == ProfileField.diabetesType) {
      _dropdownValue = _kDiabetes.contains(d.diabetesTypeLabel)
          ? d.diabetesTypeLabel
          : _kDiabetes.first;
    } else if (f == ProfileField.familyHistory) {
      _boolVal = d.familyHistory;
    } else if (f == ProfileField.hypertension) {
      _boolVal = d.hypertension;
    } else if (f == ProfileField.heartDisease) {
      _boolVal = d.heartDisease;
    } else if (f == ProfileField.smoking) {
      _dropdownValue =
          _kSmoking.contains(d.smokingLabel) ? d.smokingLabel : _kSmoking.first;
    } else if (f == ProfileField.activity) {
      _dropdownValue =
          _kActivity.contains(d.activityLabel) ? d.activityLabel : _kActivity.first;
    } else if (f == ProfileField.hba1c) {
      _c1.text = d.hba1cDisplay ?? '';
    } else if (f == ProfileField.medication) {
      _c1.text = d.medicationDisplay ?? '';
    } else if (f == ProfileField.targetRange) {
      _c1.text = '${d.targetGlucoseMinMgDl}';
      _c2.text = '${d.targetGlucoseMaxMgDl}';
    }
  }

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    super.dispose();
  }

  String get _title {
    switch (f) {
      case ProfileField.fullName:
        return 'Full name';
      case ProfileField.email:
        return 'Email';
      case ProfileField.age:
        return 'Age';
      case ProfileField.biologicalSex:
        return 'Biological sex';
      case ProfileField.heightCm:
        return 'Height (cm)';
      case ProfileField.weightKg:
        return 'Weight (kg)';
      case ProfileField.bmi:
        return 'Height & weight';
      case ProfileField.diabetesType:
        return 'Diabetes type';
      case ProfileField.familyHistory:
        return 'Family history';
      case ProfileField.hypertension:
        return 'Hypertension';
      case ProfileField.heartDisease:
        return 'Heart disease';
      case ProfileField.smoking:
        return 'Smoking';
      case ProfileField.activity:
        return 'Activity level';
      case ProfileField.hba1c:
        return 'HbA1c (%)';
      case ProfileField.medication:
        return 'Medication';
      case ProfileField.targetRange:
        return 'Target range (mg/dL)';
    }
  }

  void _save() {
    final d = widget.initial;
    late final ProfileDisplayData next;
    try {
      if (f == ProfileField.fullName) {
        next = d.copyWith(fullName: _c1.text.trim());
      } else if (f == ProfileField.email) {
        next = d.copyWith(email: _c1.text.trim());
      } else if (f == ProfileField.age) {
        next = d.copyWith(age: int.parse(_c1.text.trim()));
      } else if (f == ProfileField.biologicalSex) {
        if (_dropdownValue == null) return;
        next = d.copyWith(biologicalSex: _dropdownValue!);
      } else if (f == ProfileField.heightCm) {
        next = d.copyWith(heightCm: int.parse(_c1.text.trim()));
      } else if (f == ProfileField.weightKg) {
        next = d.copyWith(weightKg: double.parse(_c1.text.trim()));
      } else if (f == ProfileField.bmi) {
        final h = int.parse(_c1.text.trim());
        final kg = double.parse(_c2.text.trim());
        next = d.copyWith(heightCm: h, weightKg: kg);
      } else if (f == ProfileField.diabetesType) {
        if (_dropdownValue == null) return;
        next = d.copyWith(diabetesTypeLabel: _dropdownValue!);
      } else if (f == ProfileField.familyHistory) {
        if (_boolVal == null) return;
        next = d.copyWith(familyHistory: _boolVal!);
      } else if (f == ProfileField.hypertension) {
        if (_boolVal == null) return;
        next = d.copyWith(hypertension: _boolVal!);
      } else if (f == ProfileField.heartDisease) {
        if (_boolVal == null) return;
        next = d.copyWith(heartDisease: _boolVal!);
      } else if (f == ProfileField.smoking) {
        if (_dropdownValue == null) return;
        next = d.copyWith(smokingLabel: _dropdownValue!);
      } else if (f == ProfileField.activity) {
        if (_dropdownValue == null) return;
        next = d.copyWith(activityLabel: _dropdownValue!);
      } else if (f == ProfileField.hba1c) {
        final t = _c1.text.trim();
        next = t.isEmpty
            ? d.copyWith(clearHba1c: true)
            : d.copyWith(hba1cDisplay: t);
      } else if (f == ProfileField.medication) {
        final t = _c1.text.trim();
        next = t.isEmpty
            ? d.copyWith(clearMedication: true)
            : d.copyWith(medicationDisplay: t);
      } else if (f == ProfileField.targetRange) {
        next = d.copyWith(
          targetGlucoseMinMgDl: int.parse(_c1.text.trim()),
          targetGlucoseMaxMgDl: int.parse(_c2.text.trim()),
        );
      } else {
        return;
      }
    } catch (_) {
      AppResultDialog.show(
        context,
        variant: AppResultVariant.error,
        title: 'Invalid value',
        message: 'Please check the values and try again.',
        autoDismiss: false,
      );
      return;
    }
    widget.onSaved(next);
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenW > 560 ? 560 : screenW - 32,
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.primary100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.neutral300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'GlucoSense AI',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _title,
                    style: GoogleFonts.manrope(
                      fontSize: 42 * 0.75,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.52,
                    ),
                    child: SingleChildScrollView(
                      child: _buildBody(screenW),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            side: BorderSide(color: AppColors.neutral400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            foregroundColor: AppColors.primary700,
                            textStyle: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: AppColors.primary600,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            textStyle: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dialogInputDec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.neutral300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.neutral300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary400, width: 1.2),
      ),
    );
  }

  Widget _yesNoPill() {
    final yesSelected = _boolVal ?? false;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.neutral500),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(999),
              ),
              onTap: () => setState(() => _boolVal = true),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: yesSelected ? AppColors.primary100 : Colors.white,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(999),
                  ),
                ),
                child: Text(
                  'Yes',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 46, color: AppColors.neutral500),
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(999),
              ),
              onTap: () => setState(() => _boolVal = false),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !yesSelected ? AppColors.primary100 : Colors.white,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(999),
                  ),
                ),
                child: Text(
                  'No',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(double w) {
    switch (f) {
      case ProfileField.biologicalSex:
        return _buildDropdownField(_kSex);
      case ProfileField.diabetesType:
        return _buildDropdownField(_kDiabetes);
      case ProfileField.smoking:
        return _buildDropdownField(_kSmoking);
      case ProfileField.activity:
        return _buildDropdownField(_kActivity);
      case ProfileField.familyHistory:
      case ProfileField.hypertension:
      case ProfileField.heartDisease:
        return _yesNo();
      case ProfileField.bmi:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BMI updates automatically from height and weight.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _c1,
              keyboardType: TextInputType.number,
              decoration: _dialogInputDec('Height (cm)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _c2,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _dialogInputDec('Weight (kg)'),
            ),
          ],
        );
      case ProfileField.targetRange:
        return Column(
          children: [
            TextField(
              controller: _c1,
              keyboardType: TextInputType.number,
              decoration: _dialogInputDec('Min (mg/dL)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _c2,
              keyboardType: TextInputType.number,
              decoration: _dialogInputDec('Max (mg/dL)'),
            ),
          ],
        );
      default:
        return TextField(
          controller: _c1,
          keyboardType: _keyboardFor(f),
          decoration: _dialogInputDec(_hintFor(f)),
          maxLines: f == ProfileField.medication ? 3 : 1,
        );
    }
  }

  TextInputType _keyboardFor(ProfileField field) {
    switch (field) {
      case ProfileField.age:
      case ProfileField.heightCm:
        return TextInputType.number;
      case ProfileField.weightKg:
      case ProfileField.hba1c:
        return const TextInputType.numberWithOptions(decimal: true);
      case ProfileField.email:
        return TextInputType.emailAddress;
      default:
        return TextInputType.text;
    }
  }

  String _hintFor(ProfileField field) {
    switch (field) {
      case ProfileField.fullName:
        return 'Full name';
      case ProfileField.email:
        return 'Email';
      case ProfileField.age:
        return 'Age';
      case ProfileField.heightCm:
        return 'Height (cm)';
      case ProfileField.weightKg:
        return 'Weight (kg)';
      case ProfileField.hba1c:
        return 'e.g. 5.6';
      case ProfileField.medication:
        return 'e.g. Metformin';
      default:
        return '';
    }
  }

  Widget _buildDropdownField(List<String> options) {
    final v = _dropdownValue != null && options.contains(_dropdownValue)
        ? _dropdownValue!
        : options.first;
    return DropdownButtonFormField<String>(
      initialValue: v,
      decoration: _dialogInputDec('Select'),
      items: options
          .map(
            (e) => DropdownMenuItem(value: e, child: Text(e)),
          )
          .toList(),
      onChanged: (x) => setState(() => _dropdownValue = x),
    );
  }

  Widget _yesNo() {
    return _yesNoPill();
  }
}
