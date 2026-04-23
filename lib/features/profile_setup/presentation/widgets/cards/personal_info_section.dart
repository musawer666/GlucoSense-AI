import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/colors/app_colors.dart';
import '../../../../auth/presentation/constants/login_ui.dart';
import 'profile_white_card.dart';

class PersonalInfoSection extends StatelessWidget {
  const PersonalInfoSection({
    super.key,
    required this.nameController,
    required this.ageController,
    required this.biologicalSex,
    required this.onSexChanged,
  });

  final TextEditingController nameController;
  final TextEditingController ageController;
  final String? biologicalSex;
  final ValueChanged<String?> onSexChanged;

  static const _sexOptions = <String>[
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  InputDecoration _fieldDec(BuildContext context, {String? hint, Widget? suffix}) {
    return InputDecoration(
      filled: true,
      fillColor: LoginUi.inputFill,
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 16,
        color: AppColors.neutral500,
      ),
      suffix: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = (constraints.maxWidth * 0.035).clamp(12.0, 16.0);
        return ProfileWhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('Full Name'),
              TextFormField(
                controller: nameController,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                decoration: _fieldDec(context, hint: 'e.g. Alex Morgan'),
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter your full name';
                  }
                  return null;
                },
              ),
              SizedBox(height: gap),
              _label('Age'),
              TextFormField(
                controller: ageController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                decoration: _fieldDec(context, hint: 'Years').copyWith(
                  suffixText: 'yrs',
                  suffixStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.neutral500,
                  ),
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Enter your age';
                  final n = int.tryParse(t);
                  if (n == null || n < 1 || n > 120) {
                    return 'Enter a valid age (1–120)';
                  }
                  return null;
                },
              ),
              SizedBox(height: gap),
              _label('Biological Sex'),
              DropdownButtonFormField<String>(
                value: biologicalSex, // ignore: deprecated_member_use
                isExpanded: true,
                hint: Text(
                  'Select',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.neutral500,
                  ),
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.neutral600,
                ),
                decoration: _fieldDec(context),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                items: _sexOptions
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onSexChanged,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Select an option' : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.neutral600,
        ),
      ),
    );
  }
}
