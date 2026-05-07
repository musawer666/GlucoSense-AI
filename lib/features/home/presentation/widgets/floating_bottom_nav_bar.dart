import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';

class FloatingBottomNavBar extends StatelessWidget {
  const FloatingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<_NavSpec> _items = [
    _NavSpec(icon: Icons.home_rounded, label: 'Home'),
    _NavSpec(icon: Icons.add_circle_outline_rounded, label: 'Log'),
    _NavSpec(icon: Icons.restaurant_rounded, label: 'Meal'),
    _NavSpec(icon: Icons.auto_graph_rounded, label: 'Risk'),
    _NavSpec(icon: Icons.insights_rounded, label: 'Trends'),
    _NavSpec(icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    // Tight pill: small vertical padding so bar sits low and feels docked.
    final hPadOuter = (w * 0.018).clamp(5.0, 8.0);
    final vPadOuter = (w * 0.012).clamp(4.0, 6.0);
    final labelSize = (w * 0.026).clamp(9.5, 11.0);
    final iconSize = (w * 0.055).clamp(19.0, 22.0);
    // Smaller radius on selection chip so it does not dominate the bar.
    final blobR = (w * 0.028).clamp(10.0, 12.0);
    final gapIconLabel = (w * 0.006).clamp(1.0, 3.0);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: hPadOuter,
          vertical: vPadOuter,
        ),
        decoration: BoxDecoration(
          color: AppColors.bottomNavBarSurface,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(_items.length, (i) {
              final spec = _items[i];
              final selected = currentIndex == i;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(blobR),
                  child: Align(
                    alignment: Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: selected
                            ? (w * 0.018).clamp(5.0, 8.0)
                            : (w * 0.012).clamp(4.0, 6.0),
                        vertical: selected
                            ? (w * 0.014).clamp(4.0, 6.0)
                            : (w * 0.018).clamp(5.0, 7.0),
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.bottomNavSelected
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(blobR),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            spec.icon,
                            size: iconSize,
                            color: selected
                                ? AppColors.onPrimary
                                : AppColors.bottomNavInactive,
                          ),
                          SizedBox(height: gapIconLabel),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              spec.label,
                              maxLines: 1,
                              style: GoogleFonts.inter(
                                fontSize: labelSize,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? AppColors.onPrimary
                                    : AppColors.bottomNavInactive,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
