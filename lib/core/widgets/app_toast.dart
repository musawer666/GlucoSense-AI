import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../colors/app_colors.dart';

enum AppToastVariant { info, success, error }

/// Animated toast anchored to the **top center** of the screen.
abstract final class AppToast {
  AppToast._();

  static OverlayEntry? _current;

  static void show(
    BuildContext context, {
    required String message,
    Duration displayDuration = const Duration(seconds: 3),
    AppToastVariant variant = AppToastVariant.info,
  }) {
    _dismiss();

    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _ToastOverlay(
        message: message,
        variant: variant,
        displayDuration: displayDuration,
        onDisposed: () {
          if (_current == entry) {
            _current = null;
          }
        },
        onRemove: () {
          entry.remove();
        },
      ),
    );

    _current = entry;
    overlay.insert(entry);
  }

  static void dismiss() => _dismiss();

  static void _dismiss() {
    _current?.remove();
    _current = null;
  }
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({
    required this.message,
    required this.variant,
    required this.displayDuration,
    required this.onRemove,
    required this.onDisposed,
  });

  final String message;
  final AppToastVariant variant;
  final Duration displayDuration;
  final VoidCallback onRemove;
  final VoidCallback onDisposed;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 180),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -0.12),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  ));

  late final Animation<double> _tickScale = Tween<double>(
    begin: 0.78,
    end: 1.0,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.05, 0.55, curve: Curves.easeOutBack),
      reverseCurve: Curves.easeInCubic,
    ),
  );

  late final Animation<double> _tickRing = Tween<double>(
    begin: 0.85,
    end: 1.18,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.10, 0.85, curve: Curves.easeOutCubic),
      reverseCurve: Curves.easeInCubic,
    ),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(widget.displayDuration);
      if (!mounted) return;
      await _controller.reverse();
      if (!mounted) return;
      widget.onRemove();
      widget.onDisposed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _accent() {
    switch (widget.variant) {
      case AppToastVariant.info:
        return AppColors.primary600;
      case AppToastVariant.success:
        return const Color(0xFF10B981);
      case AppToastVariant.error:
        return AppColors.destructive;
    }
  }

  Widget _leadingIndicator() {
    if (widget.variant != AppToastVariant.success) {
      return Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: _accent(),
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final ringAlpha = (0.22 * _controller.value).clamp(0.0, 0.22);
        return SizedBox(
          width: 24,
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: _tickRing.value,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _accent().withValues(alpha: ringAlpha),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Transform.scale(
                scale: _tickScale.value,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _accent(),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Positioned(
      left: 0,
      right: 0,
      top: topInset + 12,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _accent().withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neutral900.withValues(alpha: 0.09),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _leadingIndicator(),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              widget.message,
                              textAlign: TextAlign.left,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                                color: AppColors.neutral900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
