import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';

/// Primary CTA for the Log Reading form. Gradient surface, soft glow,
/// and tap scale-down for a premium pressable feel.
class SaveReadingButton extends StatefulWidget {
  const SaveReadingButton({
    super.key,
    required this.onPressed,
    required this.saving,
  });

  final VoidCallback? onPressed;
  final bool saving;

  @override
  State<SaveReadingButton> createState() => _SaveReadingButtonState();
}

class _SaveReadingButtonState extends State<SaveReadingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0,
    upperBound: 1,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => _press.forward(),
      onTapUp: disabled ? null : (_) => _press.reverse(),
      onTapCancel: disabled ? null : _press.reverse,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _press,
        builder: (context, _) {
          final scale = 1 - _press.value * 0.03;
          return Transform.scale(
            scale: scale,
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: disabled
                      ? [AppColors.neutral300, AppColors.neutral400]
                      : const [
                          AppColors.primary500,
                          AppColors.primary700,
                        ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: disabled
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primary500
                              .withValues(alpha: 0.45),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
              ),
              child: Center(
                child: widget.saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Save reading',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
