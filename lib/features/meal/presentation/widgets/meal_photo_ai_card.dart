import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/widgets/app_result_dialog.dart';
import '../../domain/entities/meal_photo_analysis.dart';

// Re-export domain entities so existing imports keep working without
// having to touch every call site.
export '../../domain/entities/meal_photo_analysis.dart'
    show MealPhotoAnalysis, MealSafetyVerdict, IngredientImpact, SmarterAlternative;

/// Upload + meal name + analyse card. All actual analysis is delegated
/// to the parent cubit via [onAnalyzeRequested]; this widget is purely
/// about capturing user input.
///
/// Intentionally dumb on purpose — no heuristics live here. Every
/// number the user ever sees is produced by the Gemini data source.
class MealPhotoAiCard extends StatefulWidget {
  const MealPhotoAiCard({
    super.key,
    required this.onAnalyzeRequested,
    required this.onReset,
    required this.hasResult,
    required this.isAnalyzing,
  });

  /// Fires once the user taps **Analyze with AI** with a non-empty
  /// meal name and an attached photo.
  final void Function(String mealName, Uint8List imageBytes)
      onAnalyzeRequested;

  /// Called when the user taps the reset icon on the header.
  final VoidCallback onReset;

  /// Whether a result is currently displayed elsewhere on the screen.
  /// Used to decide whether to show the reset button.
  final bool hasResult;

  /// Driven by the parent cubit. Disables the submit button and swaps
  /// its label for a spinner.
  final bool isAnalyzing;

  @override
  State<MealPhotoAiCard> createState() => _MealPhotoAiCardState();
}

class _MealPhotoAiCardState extends State<MealPhotoAiCard> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();

  Uint8List? _imageBytes;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 86,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      AppResultDialog.show(
        context,
        variant: AppResultVariant.error,
        title: 'Could not open gallery',
        message: '$e',
        autoDismiss: false,
      );
    }
  }

  void _analyze() {
    if (widget.isAnalyzing) return;
    final name = _nameController.text.trim();
    final bytes = _imageBytes;
    if (bytes == null) {
      AppResultDialog.show(
        context,
        variant: AppResultVariant.error,
        title: 'Photo missing',
        message: 'Please upload a meal photo first.',
        autoDismiss: false,
      );
      return;
    }
    if (name.isEmpty) {
      AppResultDialog.show(
        context,
        variant: AppResultVariant.error,
        title: 'Meal name missing',
        message: 'Add the meal name so AI can identify it accurately.',
        autoDismiss: false,
      );
      return;
    }
    widget.onAnalyzeRequested(name, bytes);
  }

  void _reset() {
    setState(() {
      _imageBytes = null;
      _nameController.clear();
    });
    widget.onReset();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final hasName = _nameController.text.trim().isNotEmpty;
        final hasImage = _imageBytes != null;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppColors.primary50.withValues(alpha: 0.7),
                AppColors.secondary50.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.primary200),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary200.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  onReset: (widget.hasResult || hasImage || hasName)
                      ? _reset
                      : null,
                ),
                const SizedBox(height: 12),
                _StepStrip(
                  currentStep: !hasImage
                      ? 1
                      : !hasName
                      ? 2
                      : 3,
                ),
                const SizedBox(height: 14),
                _StepLabel(number: 1, text: 'Upload meal photo'),
                const SizedBox(height: 8),
                _PhotoPicker(
                  imageBytes: _imageBytes,
                  onPick: _pickImage,
                  width: w,
                ),
                const SizedBox(height: 14),
                _StepLabel(number: 2, text: 'Add the meal name'),
                const SizedBox(height: 8),
                _MealNameField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                _AnalyzeButton(
                  isAnalyzing: widget.isAnalyzing,
                  onPressed: widget.isAnalyzing ? null : _analyze,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StepStrip extends StatelessWidget {
  const _StepStrip({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StepDot(index: 1, current: currentStep, label: 'Photo'),
          ),
          _StepConnector(active: currentStep > 1),
          Expanded(
            child: _StepDot(index: 2, current: currentStep, label: 'Name'),
          ),
          _StepConnector(active: currentStep > 2),
          Expanded(
            child: _StepDot(index: 3, current: currentStep, label: 'Analyze'),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.current,
    required this.label,
  });

  final int index;
  final int current;
  final String label;

  @override
  Widget build(BuildContext context) {
    final done = current > index;
    final active = current == index;
    final color = done
        ? AppColors.primary600
        : active
        ? AppColors.primary700
        : AppColors.neutral500;
    final bg = done
        ? AppColors.primary600
        : active
        ? AppColors.primary100
        : Colors.white;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(
              color: done ? AppColors.primary600 : color.withValues(alpha: 0.6),
              width: 1.4,
            ),
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : Center(
                  child: Text(
                    '$index',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 2,
      decoration: BoxDecoration(
        color: active ? AppColors.primary500 : AppColors.neutral200,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary100,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            '$number',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.manrope(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Premium result card shown in the Prediction area with ingredient chart.
class MealPhotoResultCard extends StatelessWidget {
  const MealPhotoResultCard({
    super.key,
    required this.analysis,
    this.onSave,
    this.onRemove,
    this.onAnalyzeAnother,
    this.onClose,
    this.isSaved = false,
    this.viewOnly = false,
  });

  final MealPhotoAnalysis analysis;
  final VoidCallback? onSave;
  final VoidCallback? onRemove;
  final VoidCallback? onAnalyzeAnother;
  final VoidCallback? onClose;
  final bool isSaved;

  /// When true, the card renders as a read-only saved-meal preview:
  /// no Save / Analyze-Another buttons. Only Close + Delete actions.
  final bool viewOnly;

  Color get _accent => switch (analysis.verdict) {
    MealSafetyVerdict.safe => AppColors.primary600,
    MealSafetyVerdict.caution => AppColors.tertiary500,
    MealSafetyVerdict.risky => AppColors.destructive,
  };

  Color get _accentSoft => switch (analysis.verdict) {
    MealSafetyVerdict.safe => AppColors.primary100,
    MealSafetyVerdict.caution => AppColors.tertiary100,
    MealSafetyVerdict.risky => const Color(0xFFFEE2E2),
  };

  IconData get _verdictIcon => switch (analysis.verdict) {
    MealSafetyVerdict.safe => Icons.verified_rounded,
    MealSafetyVerdict.caution => Icons.warning_amber_rounded,
    MealSafetyVerdict.risky => Icons.dangerous_outlined,
  };

  String get _verdictLabel => switch (analysis.verdict) {
    MealSafetyVerdict.safe => 'SAFE',
    MealSafetyVerdict.caution => 'CAUTION',
    MealSafetyVerdict.risky => 'RISKY',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _accent.withValues(alpha: 0.4), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _accent,
                  Color.lerp(_accent, Colors.black, 0.22) ?? _accent,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_verdictIcon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI PHOTO PREDICTION',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        analysis.mealName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        analysis.headline,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _verdictLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _accent,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology_alt_rounded,
                      size: 16,
                      color: _accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI Summary',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _accentSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${analysis.confidence}% confidence',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (analysis.summary.isNotEmpty)
                  Text(
                    analysis.summary,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      height: 1.5,
                      color: AppColors.neutral700,
                    ),
                  ),
                if (analysis.problematicIngredients.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionLabel(
                    icon: Icons.bar_chart_rounded,
                    text: 'Not Suitable For You',
                  ),
                  const SizedBox(height: 10),
                  _IngredientImpactChart(
                    items: analysis.problematicIngredients,
                    accent: _accent,
                    accentSoft: _accentSoft,
                  ),
                ],
                if (analysis.factors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionLabel(
                    icon: Icons.analytics_outlined,
                    text: 'Factors Considered',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: analysis.factors
                        .map(
                          (f) => _Chip(
                            label: f,
                            color: _accent,
                            background: _accentSoft,
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (analysis.recommendations.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _SectionLabel(
                    icon: Icons.tips_and_updates_outlined,
                    text: 'Recommendations',
                  ),
                  const SizedBox(height: 8),
                  ...analysis.recommendations.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                height: 1.4,
                                color: AppColors.neutral700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (viewOnly) ...[
                  if (onClose != null || onRemove != null) ...[
                    const SizedBox(height: 16),
                    _ViewOnlyActions(onClose: onClose, onRemove: onRemove),
                  ],
                ] else if (onSave != null ||
                    onRemove != null ||
                    onAnalyzeAnother != null) ...[
                  const SizedBox(height: 16),
                  _SaveAction(
                    isSaved: isSaved,
                    accent: _accent,
                    onSave: onSave,
                    onRemove: onRemove,
                    onAnalyzeAnother: onAnalyzeAnother,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewOnlyActions extends StatelessWidget {
  const _ViewOnlyActions({this.onClose, this.onRemove});

  final VoidCallback? onClose;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onClose != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary700,
                minimumSize: const Size.fromHeight(50),
                side: BorderSide(color: AppColors.primary300, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Close'),
            ),
          ),
        if (onClose != null && onRemove != null) const SizedBox(width: 10),
        if (onRemove != null)
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.destructive.withValues(alpha: 0.45),
                ),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.destructive,
              ),
            ),
          ),
      ],
    );
  }
}

class _SaveAction extends StatelessWidget {
  const _SaveAction({
    required this.isSaved,
    required this.accent,
    this.onSave,
    this.onRemove,
    this.onAnalyzeAnother,
  });

  final bool isSaved;
  final Color accent;
  final VoidCallback? onSave;
  final VoidCallback? onRemove;
  final VoidCallback? onAnalyzeAnother;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isSaved)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppColors.primary700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Saved to your meals',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 10),
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.destructive.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.destructive,
                    ),
                  ),
                ),
              ],
            ],
          )
        else if (onSave != null)
          FilledButton.icon(
            onPressed: onSave,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.bookmark_add_rounded),
            label: const Text('Save this meal'),
          ),
        if (onAnalyzeAnother != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onAnalyzeAnother,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary700,
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(color: AppColors.primary300, width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Analyze another meal'),
          ),
        ],
      ],
    );
  }
}

class _IngredientImpactChart extends StatefulWidget {
  const _IngredientImpactChart({
    required this.items,
    required this.accent,
    required this.accentSoft,
  });

  final List<IngredientImpact> items;
  final Color accent;
  final Color accentSoft;

  @override
  State<_IngredientImpactChart> createState() => _IngredientImpactChartState();
}

class _IngredientImpactChartState extends State<_IngredientImpactChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.items.asMap().entries.map((entry) {
            final item = entry.value;
            final factor = (_ctrl.value).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${(item.impact * 100).round()}%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: widget.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      children: [
                        Container(height: 10, color: widget.accentSoft),
                        FractionallySizedBox(
                          widthFactor: (item.impact * factor).clamp(0.0, 1.0),
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.accent.withValues(alpha: 0.85),
                                  widget.accent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (item.reason.isNotEmpty)
                    Text(
                      item.reason,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.onReset});

  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.secondary500, AppColors.secondary700],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary500.withValues(alpha: 0.45),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'AI Meal Image Check',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary100,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'AI',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Photo + name → instant safety verdict from AI.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        if (onReset != null)
          InkWell(
            onTap: onReset,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary200),
              ),
              child: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: AppColors.primary700,
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.imageBytes,
    required this.onPick,
    required this.width,
  });

  final Uint8List? imageBytes;
  final VoidCallback onPick;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = (width * 0.52).clamp(160.0, 230.0);
    final hasImage = imageBytes != null;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: hasImage
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary50.withValues(alpha: 0.9),
                    Colors.white,
                  ],
                ),
          color: hasImage ? Colors.white : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasImage ? AppColors.primary400 : AppColors.primary300,
            width: hasImage ? 1.6 : 1.4,
          ),
          boxShadow: hasImage
              ? [
                  BoxShadow(
                    color: AppColors.primary300.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      imageBytes!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.42),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Change',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: AppColors.primary700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Photo ready',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.primary100.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary500,
                              AppColors.primary700,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary400.withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to upload meal photo',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JPG / PNG  •  bright, top-down works best',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MealNameField extends StatelessWidget {
  const _MealNameField({required this.controller, this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.done,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Meal name (e.g. Chicken Biryani)',
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        prefixIcon: Icon(
          Icons.restaurant_menu_rounded,
          color: AppColors.primary700,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary500, width: 1.4),
        ),
      ),
    );
  }
}

class _AnalyzeButton extends StatelessWidget {
  const _AnalyzeButton({required this.isAnalyzing, required this.onPressed});

  final bool isAnalyzing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: disabled
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary600, AppColors.primary700],
              ),
        color: disabled ? AppColors.primary300 : null,
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary600.withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            height: 54,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isAnalyzing)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  isAnalyzing ? 'Analyzing...' : 'Analyze with AI',
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary700),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
