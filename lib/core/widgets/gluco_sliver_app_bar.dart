import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../colors/app_colors.dart';

/// App-wide premium top bar used across primary screens (Home, Log,
/// Meal Predictor, Risk, Profile).
///
/// Visually:
///   * Vibrant, angled teal gradient (primary500 → primary700 →
///     primary900) that reads as *Luminous Vitality* rather than a
///     dull dark bar.
///   * Two soft mesh blobs — a bright teal glow top-right and a subtle
///     violet hint bottom-left — giving the brand palette depth
///     without clashing.
///   * Diagonal light sheen across the top for a premium, glass-like
///     finish.
///   * Sculpted bottom with a 28 px radius and a hairline white glow
///     underline to separate it from the content.
///   * Optional `subtitle` for screens that benefit from extra context
///     (e.g. "Your diabetes risk overview"). When provided, the bar
///     grows to 80 px and stacks title + subtitle centred.
///   * When `showBackButton: true`, a glass-pill back button is
///     rendered automatically; custom `leading` / `actions` take
///     precedence and can be anything the caller needs.
///
/// Technically:
///   * Returns a [SliverAppBar] so it can drop into any
///     [CustomScrollView.slivers] list unchanged.
///   * `pinned: true` keeps it visible during scroll.
///   * `scrolledUnderElevation: 0` avoids Material 3 tint shifts.
///
/// Every existing caller keeps working — the new surface is purely
/// additive via the optional `subtitle` parameter.
class GlucoSliverAppBar extends StatelessWidget {
  const GlucoSliverAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.showBackButton = false,
    this.onBack,
  });

  final String title;

  /// Optional second line of context shown below the title.
  /// When `null` the bar keeps its compact height (64 px).
  final String? subtitle;

  /// Overrides the auto-generated back button when supplied.
  final Widget? leading;

  /// Trailing widgets (right side). Keep them small — 40×40 at most.
  final List<Widget>? actions;

  /// When true and no [leading] is supplied, renders a glass-pill
  /// back button on the left.
  final bool showBackButton;

  /// Custom back handler (defaults to [Navigator.maybePop]).
  final VoidCallback? onBack;

  static const double _compactHeight = 64;
  static const double _tallHeight = 80;
  static const double _bottomRadius = 28;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = (subtitle?.trim().isNotEmpty ?? false);
    final resolvedLeading = leading ??
        (showBackButton
            ? _GlassIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              )
            : null);

    return SliverAppBar(
      pinned: true,
      floating: false,
      automaticallyImplyLeading: false,
      leading: resolvedLeading,
      actions: actions,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      toolbarHeight: hasSubtitle ? _tallHeight : _compactHeight,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(_bottomRadius)),
      ),
      flexibleSpace: const _BarSurface(),
      title: _TitleBlock(title: title, subtitle: subtitle),
    );
  }
}

// =============================================================================
// Title block — handles title and optional subtitle with a consistent
// centred layout.
// =============================================================================
class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.title, required this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = (subtitle?.trim().isNotEmpty ?? false);

    final titleText = Text(
      title,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.manrope(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 0.2,
        shadows: [
          Shadow(
            color: AppColors.primary900.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    if (!hasSubtitle) return titleText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        titleText,
        const SizedBox(height: 2),
        Text(
          subtitle!,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.82),
            letterSpacing: 0.15,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Bar surface — the painted gradient + glow mesh that sits inside the
// SliverAppBar's flexibleSpace. Kept separate so the SliverAppBar stays
// declarative and easy to read.
// =============================================================================
class _BarSurface extends StatelessWidget {
  const _BarSurface();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(GlucoSliverAppBar._bottomRadius),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Base angled gradient — teal vitality.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary500,
                  AppColors.primary700,
                  AppColors.primary900,
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // 2. Violet accent blob (bottom-left) — a whisper of the
          //    secondary brand colour to add depth without clashing.
          Positioned(
            bottom: -55,
            left: -35,
            child: _MeshBlob(
              size: 170,
              color: AppColors.secondary400.withValues(alpha: 0.18),
            ),
          ),

          // 3. Mint teal glow (top-right) — the signature "luminous"
          //    highlight.
          Positioned(
            top: -40,
            right: -30,
            child: _MeshBlob(
              size: 160,
              color: AppColors.primary300.withValues(alpha: 0.32),
            ),
          ),

          // 4. Diagonal light ray — subtle glass sheen.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.00),
                    Colors.white.withValues(alpha: 0.00),
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
            ),
          ),

          // 5. Bottom inner shadow — grounds the bar on the page.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 18,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.primary900.withValues(alpha: 0.22),
                  ],
                ),
              ),
            ),
          ),

          // 6. Hairline glow underline — 1 px of white at alpha ~0.10
          //    reading as a crisp separation against white content.
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.20),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Soft radial blob — the "mesh gradient" effect, implemented cheaply
// with a RadialGradient (no ImageFilter blur → stays smooth on mid-tier
// Android).
// =============================================================================
class _MeshBlob extends StatelessWidget {
  const _MeshBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, Colors.transparent],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Glass-pill icon button used for the auto-generated back button.
// Public-api-safe: not exported, callers that need a matching action
// icon can pass their own widgets via `actions`.
// =============================================================================
class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Ink(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, size: 20, color: Colors.white),
            ),
          ),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Public helper that matches the app bar's glass-pill aesthetic for
/// custom trailing [SliverAppBar.actions]. Use this when you want an
/// action icon that blends with the themed bar.
///
/// Example:
/// ```dart
/// GlucoSliverAppBar(
///   title: 'Profile',
///   actions: [
///     GlucoAppBarAction(icon: Icons.edit_rounded, onPressed: _openEdit),
///     GlucoAppBarAction(icon: Icons.logout_rounded, onPressed: _signOut),
///   ],
/// )
/// ```
class GlucoAppBarAction extends StatelessWidget {
  const GlucoAppBarAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return _GlassIconButton(
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}
