import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/colors/app_colors.dart';

/// Wide gradient CTA: label + right arrow (profile setup).
///
/// Set [isLoading] to `true` to swap the label/arrow for a compact
/// progress indicator (the tap handler is ignored while loading).
class ProfileContinueGradientButton extends StatelessWidget {
  const ProfileContinueGradientButton({
    super.key,
    required this.onPressed,
    this.label = 'Continue Setup',
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final effectiveTap = isLoading ? null : onPressed;

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: effectiveTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: disabled
                    ? [
                        AppColors.primary800.withValues(alpha: 0.45),
                        AppColors.primary400.withValues(alpha: 0.45),
                      ]
                    : const [
                        AppColors.primary800,
                        AppColors.primary400,
                      ],
              ),
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.primary400.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: double.infinity,
                minHeight: 56,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: isLoading
                    ? const Center(
                        child: SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.onPrimary,
                            ),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: AppColors.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.onPrimary,
                            size: 22,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
