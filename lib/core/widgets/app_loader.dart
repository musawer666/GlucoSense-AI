import 'package:flutter/material.dart';

import '../colors/app_colors.dart';

/// Full-screen blocking loader using the root navigator.
abstract final class AppLoader {
  AppLoader._();

  static bool _isShowing = false;

  static Future<void> show(BuildContext context) async {
    if (_isShowing) return;
    _isShowing = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (ctx) => const _LoaderDialog(),
    );
    _isShowing = false;
  }

  static void hide(BuildContext context) {
    if (!_isShowing) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
    _isShowing = false;
  }
}

class _LoaderDialog extends StatelessWidget {
  const _LoaderDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary400.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.all(22),
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary600),
          ),
        ),
      ),
    );
  }
}

/// Inline loader for buttons/cards (non-blocking).
class AppInlineLoader extends StatelessWidget {
  const AppInlineLoader({
    super.key,
    this.size = 24,
    this.strokeWidth = 2.5,
  });

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary600),
      ),
    );
  }
}
