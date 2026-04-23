import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';

/// Top-of-home greeting: coloured time-of-day line + user name and a
/// dynamic status sentence reflecting today's glucose picture.
class HomeGreeting extends StatelessWidget {
  const HomeGreeting({
    super.key,
    required this.firstName,
    required this.statusLine,
  });

  final String firstName;
  final String statusLine;

  String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _timeGreeting(),
          style: GoogleFonts.manrope(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.primary700,
            height: 1.15,
          ),
        ),
        Text(
          '$firstName.',
          style: GoogleFonts.manrope(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          statusLine,
          style: GoogleFonts.inter(
            fontSize: 14.5,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
