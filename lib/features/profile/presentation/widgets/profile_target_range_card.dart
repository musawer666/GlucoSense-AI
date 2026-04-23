import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';

/// Target Range card — large corner radius, mint curve top-right, compact layout.
class ProfileTargetRangeCard extends StatelessWidget {
  const ProfileTargetRangeCard({
    super.key,
    required this.minMgDl,
    required this.maxMgDl,
    this.onEdit,
  });

  final int minMgDl;
  final int maxMgDl;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final radius = (w * 0.11).clamp(36.0, 48.0);
    final padH = (w * 0.045).clamp(16.0, 20.0);
    final padV = (w * 0.04).clamp(14.0, 18.0);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TopRightMintAccentPainter(
                    mint: AppColors.primary100.withValues(alpha: 0.75),
                    mintDeep: AppColors.primary200.withValues(alpha: 0.35),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.adjust,
                          color: AppColors.primary700,
                          size: (w * 0.06).clamp(24.0, 28.0),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Target Range',
                            style: GoogleFonts.manrope(
                              fontSize: (w * 0.042).clamp(16.0, 18.0),
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: (w * 0.028).clamp(10.0, 12.0)),
                    Text(
                      'Current Goal',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: (w * 0.018).clamp(6.0, 8.0)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$minMgDl - $maxMgDl',
                          style: GoogleFonts.manrope(
                            fontSize: (w * 0.075).clamp(26.0, 32.0),
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            color: AppColors.primary700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'mg/dL',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: (w * 0.032).clamp(12.0, 16.0)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Edit',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 17,
                                color: AppColors.primary700,
                              ),
                            ],
                          ),
                        ),
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

/// Pale mint/teal arc in the top-right (large circle bleeding past the card edge).
class _TopRightMintAccentPainter extends CustomPainter {
  _TopRightMintAccentPainter({
    required this.mint,
    required this.mintDeep,
  });

  final Color mint;
  final Color mintDeep;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * 0.52;

    final center = Offset(w + r * 0.08, -r * 0.12);
    final paint = Paint()
      ..color = mint
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r, paint);

    final center2 = Offset(w + r * 0.02, -r * 0.08);
    canvas.drawCircle(
      center2,
      r * 0.72,
      Paint()
        ..color = mintDeep
        ..style = PaintingStyle.fill,
    );

    final gloss = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.78, h * 0.02), w * 0.08, gloss);
  }

  @override
  bool shouldRepaint(covariant _TopRightMintAccentPainter oldDelegate) {
    return oldDelegate.mint != mint || oldDelegate.mintDeep != mintDeep;
  }
}
