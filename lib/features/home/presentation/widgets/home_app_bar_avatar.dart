import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';

/// Circular profile avatar rendered on the **leading** side of the
/// home app bar.
///
/// * Shows a cached network image when [avatarUrl] is a non-empty URL.
/// * Falls back to a mint disc with the user's initial while the
///   image loads or when no avatar has been uploaded yet.
/// * Tapping the avatar calls [onTap] — the home shell uses this to
///   switch to the Profile tab.
class HomeAppBarAvatar extends StatelessWidget {
  const HomeAppBarAvatar({
    super.key,
    required this.avatarUrl,
    required this.initial,
    required this.onTap,
  });

  final String? avatarUrl;

  /// Single uppercase letter used as a fallback inside the disc.
  final String initial;
  final VoidCallback onTap;

  static const double _size = 38;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: 'Open profile',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: _AvatarImage(
                  url: avatarUrl,
                  initial: initial,
                  size: _size,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.url,
    required this.initial,
    required this.size,
  });

  final String? url;
  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.trim().isNotEmpty;
    if (!hasUrl) return _InitialDisc(initial: initial, size: size);

    return CachedNetworkImage(
      imageUrl: url!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (context, url) =>
          _InitialDisc(initial: initial, size: size),
      errorWidget: (context, url, error) =>
          _InitialDisc(initial: initial, size: size),
    );
  }
}

class _InitialDisc extends StatelessWidget {
  const _InitialDisc({required this.initial, required this.size});

  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary200, AppColors.primary400],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.manrope(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: AppColors.primary900,
        ),
      ),
    );
  }
}
