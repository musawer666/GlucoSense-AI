import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Clamps the OS **text scaler** (Display size / font size / accessibility)
/// so very large or very small system settings do not blow up typography or
/// cause avoidable overflow in fixed-height UI.
///
/// Does **not** disable accessibility — it bounds the multiplier. Tune
/// [minScaleFactor] / [maxScaleFactor] if you need a wider range.
///
/// Uses a single [TextScaler.linear] after clamping the effective factor.
/// Nesting [TextScaler.clamp] (e.g. here + Material [DatePicker]) can produce
/// an empty intersection and trigger `maxScale > minScale` assertions.
class AppTextScaleScope extends StatelessWidget {
  const AppTextScaleScope({
    super.key,
    required this.child,
    this.minScaleFactor = 0.88,
    this.maxScaleFactor = 1.15,
  });

  final Widget child;

  /// Lower bound (e.g. user set “smallest” font). Keeps tap targets readable.
  final double minScaleFactor;

  /// Upper bound (e.g. user set “largest” font). Prevents layout overflow.
  final double maxScaleFactor;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    if (mq == null) return child;

    final lo = minScaleFactor < maxScaleFactor ? minScaleFactor : maxScaleFactor;
    final hi = minScaleFactor < maxScaleFactor ? maxScaleFactor : minScaleFactor;
    // Effective scale from scaler (avoids deprecated [TextScaler.textScaleFactor]).
    const refPx = 100.0;
    final factor = mq.textScaler.scale(refPx) / refPx;
    final clamped = clampDouble(factor, lo, hi);

    return MediaQuery(
      data: mq.copyWith(
        textScaler: TextScaler.linear(clamped),
      ),
      child: child,
    );
  }
}
