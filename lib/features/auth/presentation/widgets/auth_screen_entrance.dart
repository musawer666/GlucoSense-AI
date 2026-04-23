import 'package:flutter/material.dart';

/// Staggered fade + slide + scale entrance for auth flows (login, signup,
/// forgot password). Keeps motion consistent app-wide.
class AuthScreenEntrance extends StatefulWidget {
  const AuthScreenEntrance({
    super.key,
    required this.brand,
    required this.card,
    required this.gapAfterBrand,
  });

  final Widget brand;
  final Widget card;
  final double gapAfterBrand;

  @override
  State<AuthScreenEntrance> createState() => _AuthScreenEntranceState();
}

class _AuthScreenEntranceState extends State<AuthScreenEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _brandOpacity;
  late final Animation<Offset> _brandSlide;
  late final Animation<double> _cardOpacity;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardScale;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _brandOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.0, 0.42, curve: Curves.easeOutCubic),
      ),
    );
    _brandSlide = Tween<Offset>(
      begin: const Offset(0, -0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.0, 0.42, curve: Curves.easeOutCubic),
      ),
    );

    _cardOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.18, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.18, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _cardScale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.18, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeTransition(
              opacity: _brandOpacity,
              child: SlideTransition(
                position: _brandSlide,
                child: widget.brand,
              ),
            ),
            SizedBox(height: widget.gapAfterBrand),
            FadeTransition(
              opacity: _cardOpacity,
              child: SlideTransition(
                position: _cardSlide,
                child: ScaleTransition(
                  scale: _cardScale,
                  alignment: Alignment.topCenter,
                  child: widget.card,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
