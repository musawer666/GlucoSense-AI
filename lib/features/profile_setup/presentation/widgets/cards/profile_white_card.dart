import 'package:flutter/material.dart';

/// Rounded white panel with soft shadow (shared by sections).
class ProfileWhiteCard extends StatelessWidget {
  const ProfileWhiteCard({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final radius = (w * 0.05).clamp(18.0, 22.0);
        return Container(
          width: double.infinity,
          padding: padding ??
              EdgeInsets.all((w * 0.045).clamp(16.0, 20.0)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}
