import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../domain/entities/meal_photo_analysis.dart';

/// Rich detail view for a single [SmarterAlternative].
///
/// Presented as a modal bottom sheet. Offers a single primary action —
/// **Save to my meals** — which is delegated to the parent via
/// [onSave] so the cubit / store layer stays in charge of persistence.
/// Once saved, [isSaved] flips to `true` from the parent's state and the
/// button swaps to an inert "Saved" badge, avoiding double-saves.
class AlternativeDetailSheet extends StatelessWidget {
  const AlternativeDetailSheet({
    super.key,
    required this.alternative,
    required this.onSave,
    required this.isSaved,
  });

  final SmarterAlternative alternative;

  /// Called when the user taps the Save button. Must not be `null`
  /// unless [isSaved] is already `true`.
  final VoidCallback onSave;

  /// Drives the button's visual state (CTA vs "Saved" pill).
  final bool isSaved;

  /// Convenience wrapper so call sites do not have to repeat the sheet
  /// configuration every time.
  static Future<void> show(
    BuildContext context, {
    required SmarterAlternative alternative,
    required VoidCallback onSave,
    required bool isSaved,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => AlternativeDetailSheet(
        alternative: alternative,
        onSave: onSave,
        isSaved: isSaved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(alternative: alternative),
                        const SizedBox(height: 18),
                        _PeakCard(estPeakMgDl: alternative.estPeakMgDl),
                        if (alternative.summary.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _SectionTitle('Why this is better'),
                          const SizedBox(height: 8),
                          Text(
                            alternative.summary,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (alternative.benefits.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _SectionTitle('Benefits'),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final b in alternative.benefits)
                                _BenefitChip(label: b),
                            ],
                          ),
                        ],
                        if (alternative.portionGuide.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _SectionTitle('Portion guide'),
                          const SizedBox(height: 8),
                          _PortionBanner(text: alternative.portionGuide),
                        ],
                        const SizedBox(height: 24),
                        _SaveButton(
                          isSaved: isSaved,
                          onSave: onSave,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.alternative});

  final SmarterAlternative alternative;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary300, AppColors.primary600],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary400.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.eco_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'SMARTER ALTERNATIVE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary700,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                alternative.name,
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              if (alternative.reason.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  alternative.reason,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PeakCard extends StatelessWidget {
  const _PeakCard({required this.estPeakMgDl});

  final int estPeakMgDl;

  @override
  Widget build(BuildContext context) {
    if (estPeakMgDl <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary50,
            AppColors.primary100.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.trending_down_rounded,
            color: AppColors.primary700,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated peak glucose',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary700,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$estPeakMgDl',
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary900,
                        ),
                      ),
                      TextSpan(
                        text: '  mg/dL',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded,
              size: 14, color: AppColors.primary700),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortionBanner extends StatelessWidget {
  const _PortionBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.tertiary50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.tertiary200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.restaurant_menu_rounded,
              size: 18, color: AppColors.tertiary700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: AppColors.tertiary900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaved, required this.onSave});

  final bool isSaved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    if (isSaved) {
      return Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.primary50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary300),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_added_rounded,
                color: AppColors.primary700, size: 20),
            const SizedBox(width: 8),
            Text(
              'Saved to your meals',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primary800,
              ),
            ),
          ],
        ),
      );
    }

    return FilledButton.icon(
      onPressed: onSave,
      icon: const Icon(Icons.bookmark_add_rounded, size: 20),
      label: const Text('Save this alternative'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary600,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
