import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../colors/app_colors.dart';

/// Centered success / error dialog with a large animated icon.
///
/// Uses app brand colors:
/// - success: [AppColors.primary400] / [AppColors.primary600]
/// - error:   [AppColors.destructive]
enum AppResultVariant { success, error }

abstract final class AppResultDialog {
  AppResultDialog._();

  /// Shows a centered result dialog with optional auto-dismiss.
  ///
  /// [autoDismiss] closes the dialog automatically after [autoDismissAfter].
  static Future<void> show(
    BuildContext context, {
    required AppResultVariant variant,
    String? title,
    String? message,
    String okLabel = 'OK',
    bool autoDismiss = true,
    Duration autoDismissAfter = const Duration(milliseconds: 1600),
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'result',
      barrierColor: Colors.black.withValues(alpha: 0.32),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, _) {
        return _ResultDialog(
          variant: variant,
          title: title ?? _defaultTitle(variant),
          message: message ?? _defaultMessage(variant),
          okLabel: okLabel,
          autoDismiss: autoDismiss,
          autoDismissAfter: autoDismissAfter,
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static String _defaultTitle(AppResultVariant v) =>
      v == AppResultVariant.success ? 'Success' : 'Something went wrong';

  static String _defaultMessage(AppResultVariant v) => v == AppResultVariant.success
      ? 'Your changes were saved successfully.'
      : 'We could not save your changes. Please try again.';
}

class _ResultDialog extends StatefulWidget {
  const _ResultDialog({
    required this.variant,
    required this.title,
    required this.message,
    required this.okLabel,
    required this.autoDismiss,
    required this.autoDismissAfter,
  });

  final AppResultVariant variant;
  final String title;
  final String message;
  final String okLabel;
  final bool autoDismiss;
  final Duration autoDismissAfter;

  @override
  State<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<_ResultDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  );

  late final Animation<double> _circlePop = CurvedAnimation(
    parent: _iconCtrl,
    curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
  );

  late final Animation<double> _stroke = CurvedAnimation(
    parent: _iconCtrl,
    curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    _iconCtrl.forward();
    if (widget.autoDismiss) {
      Future<void>.delayed(widget.autoDismissAfter, () {
        if (!mounted) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    super.dispose();
  }

  Color get _accent => widget.variant == AppResultVariant.success
      ? AppColors.primary500
      : AppColors.destructive;

  Color get _accentSoft => widget.variant == AppResultVariant.success
      ? AppColors.primary100
      : const Color(0xFFFEE2E2);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final maxW = w > 520 ? 420.0 : w - 40.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _iconCtrl,
                    builder: (context, _) {
                      return SizedBox(
                        width: 108,
                        height: 108,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: (0.85 + 0.4 * _circlePop.value).clamp(
                                0.0,
                                1.25,
                              ),
                              child: Opacity(
                                opacity: (0.38 * _circlePop.value).clamp(
                                  0.0,
                                  0.38,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _accentSoft,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: (0.2 + 0.8 * _circlePop.value).clamp(
                                0.0,
                                1.0,
                              ),
                              child: Container(
                                width: 86,
                                height: 86,
                                decoration: BoxDecoration(
                                  color: _accent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _accent.withValues(alpha: 0.36),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: CustomPaint(
                                    size: const Size(44, 44),
                                    painter: _IconPainter(
                                      progress: _stroke.value,
                                      isSuccess:
                                          widget.variant ==
                                          AppResultVariant.success,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(widget.okLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter({required this.progress, required this.isSuccess});

  final double progress;
  final bool isSuccess;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (isSuccess) {
      final p1 = Offset(size.width * 0.18, size.height * 0.52);
      final p2 = Offset(size.width * 0.42, size.height * 0.75);
      final p3 = Offset(size.width * 0.82, size.height * 0.32);

      final firstLen = (p2 - p1).distance;
      final secondLen = (p3 - p2).distance;
      final total = firstLen + secondLen;
      final traveled = total * progress;

      final path = Path()..moveTo(p1.dx, p1.dy);
      if (traveled <= firstLen) {
        final t = traveled / firstLen;
        final pt = Offset.lerp(p1, p2, t)!;
        path.lineTo(pt.dx, pt.dy);
      } else {
        path.lineTo(p2.dx, p2.dy);
        final t = ((traveled - firstLen) / secondLen).clamp(0.0, 1.0);
        final pt = Offset.lerp(p2, p3, t)!;
        path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, paint);
    } else {
      final a1 = Offset(size.width * 0.22, size.height * 0.22);
      final a2 = Offset(size.width * 0.78, size.height * 0.78);
      final b1 = Offset(size.width * 0.78, size.height * 0.22);
      final b2 = Offset(size.width * 0.22, size.height * 0.78);

      final firstLen = (a2 - a1).distance;
      final secondLen = (b2 - b1).distance;
      final total = firstLen + secondLen;
      final traveled = total * progress;

      if (traveled <= firstLen) {
        final t = traveled / firstLen;
        final pt = Offset.lerp(a1, a2, t)!;
        canvas.drawLine(a1, pt, paint);
      } else {
        canvas.drawLine(a1, a2, paint);
        final t = ((traveled - firstLen) / secondLen).clamp(0.0, 1.0);
        final pt = Offset.lerp(b1, b2, t)!;
        canvas.drawLine(b1, pt, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IconPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isSuccess != isSuccess;
}
