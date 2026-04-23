import 'package:flutter/material.dart';

import '../../../../../core/widgets/soft_blob_background.dart';

/// Soft teal blob **top-right** + lavender/pink blob **bottom-left** on off-white.
class SplashBackground extends StatelessWidget {
  const SplashBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SoftBlobBackground(child: child);
  }
}
