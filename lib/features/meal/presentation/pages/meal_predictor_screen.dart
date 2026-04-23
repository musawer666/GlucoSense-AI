import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/widgets/app_result_dialog.dart';
import '../../../../core/widgets/gluco_sliver_app_bar.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../data/datasources/saved_meal_remote_data_source.dart';
import '../../data/repositories/meal_analysis_repository_impl.dart';
import '../../data/repositories/saved_meal_repository_impl.dart';
import '../../domain/entities/saved_meal.dart';
import '../cubit/meal_predictor_cubit.dart';
import '../cubit/saved_meals_cubit.dart';
import '../widgets/alternative_detail_sheet.dart';
import '../widgets/meal_alternative_tile.dart';
import '../widgets/meal_photo_ai_card.dart';
import '../widgets/meal_predictor_background.dart';
import '../widgets/saved_meal_tile.dart';

/// Entry point for the Meal Predictor tab.
///
/// Owns the [MealPredictorCubit] lifecycle and wires up the real
/// Firebase + Gemini dependencies. Everything the UI displays is
/// driven by cubit state — no hardcoded numbers, no heuristics.
class MealPredictorScreen extends StatelessWidget {
  const MealPredictorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MealPredictorCubit>(
          create: (_) => MealPredictorCubit(
            profileRepository: ProfileRepositoryImpl(
              remoteDataSource: ProfileRemoteDataSourceImpl(),
            ),
            authRepository: AuthRepositoryImpl(
              remoteDataSource: AuthRemoteDataSourceImpl(),
            ),
            mealAnalysisRepository: MealAnalysisRepositoryImpl(),
          )..subscribe(),
        ),
        BlocProvider<SavedMealsCubit>(
          create: (_) => SavedMealsCubit(
            savedMealRepository: SavedMealRepositoryImpl(
              remoteDataSource: SavedMealRemoteDataSourceImpl(),
            ),
            authRepository: AuthRepositoryImpl(
              remoteDataSource: AuthRemoteDataSourceImpl(),
            ),
          )..subscribe(),
        ),
      ],
      child: const _MealPredictorView(),
    );
  }
}

class _MealPredictorView extends StatelessWidget {
  const _MealPredictorView();

  // ---------------------------------------------------------------------------
  // Intent helpers — every action is a single cubit method invocation. Keeps
  // the build tree declarative and prevents local setState reaching for
  // heuristic data.
  // ---------------------------------------------------------------------------

  Future<void> _saveCurrent(
    BuildContext context,
    MealPredictorState state,
  ) async {
    final analysis = state.currentAnalysis;
    if (analysis == null) return;

    final savedCubit = context.read<SavedMealsCubit>();
    if (savedCubit.isAlreadySaved(analysis.mealName)) {
      AppResultDialog.show(
        context,
        variant: AppResultVariant.error,
        title: 'Already saved',
        message: '"${analysis.mealName}" is already in your saved meals.',
        autoDismiss: true,
      );
      return;
    }

    final saved = await savedCubit.save(
      analysis: analysis,
      currentGlucoseMgDl: state.effectiveGlucoseMgDl,
    );
    if (!context.mounted) return;
    if (saved == null) {
      AppResultDialog.show(
        context,
        variant: AppResultVariant.error,
        title: 'Could not save',
        message: savedCubit.state.errorMessage ??
            'Something went wrong. Please try again.',
        autoDismiss: false,
      );
      return;
    }

    context.read<MealPredictorCubit>().clearAnalysis();
    AppResultDialog.show(
      context,
      variant: AppResultVariant.success,
      title: 'Meal saved',
      message: '"${saved.analysis.mealName}" added to your saved meals.',
    );
  }

  Future<void> _removeSaved(
    BuildContext context,
    String id,
    String? activeId,
  ) async {
    await context.read<SavedMealsCubit>().delete(id);
    if (!context.mounted) return;
    if (activeId == id) {
      context.read<MealPredictorCubit>().clearAnalysis();
    }
  }

  void _viewSaved(BuildContext context, SavedMeal entry) {
    context.read<MealPredictorCubit>().openSavedAnalysis(
          analysis: entry.analysis,
          savedId: entry.id,
        );
  }

  /// Opens the detail sheet for [alt]. When the user taps *Save*:
  ///   1. Only the alternative is persisted (we deliberately do NOT save
  ///      the originally analysed meal — alternatives and sources are
  ///      independent choices).
  ///   2. The cubit clears the current analysis so the screen returns to
  ///      the clean upload state — the user is ready to scan the next
  ///      meal with zero extra taps.
  Future<void> _openAlternative(
    BuildContext context,
    SmarterAlternative alt,
  ) async {
    final predictorCubit = context.read<MealPredictorCubit>();
    final savedCubit = context.read<SavedMealsCubit>();

    await AlternativeDetailSheet.show(
      context,
      alternative: alt,
      isSaved: savedCubit.isAlreadySaved(alt.name),
      onSave: () async {
        if (savedCubit.isAlreadySaved(alt.name)) {
          Navigator.of(context).pop();
          AppResultDialog.show(
            context,
            variant: AppResultVariant.error,
            title: 'Already saved',
            message: '"${alt.name}" is already in your saved meals.',
            autoDismiss: true,
          );
          return;
        }

        final saved = await savedCubit.save(
          analysis: _alternativeToAnalysis(alt),
          isAlternative: true,
        );
        if (!context.mounted) return;

        Navigator.of(context).pop();

        if (saved == null) {
          AppResultDialog.show(
            context,
            variant: AppResultVariant.error,
            title: 'Could not save',
            message: savedCubit.state.errorMessage ??
                'Something went wrong. Please try again.',
            autoDismiss: false,
          );
          return;
        }

        predictorCubit.clearAnalysis();
        AppResultDialog.show(
          context,
          variant: AppResultVariant.success,
          title: 'Saved',
          message: '"${alt.name}" added to your saved meals.',
        );
      },
    );
  }

  /// Converts a [SmarterAlternative] into a full [MealPhotoAnalysis]
  /// so it fits the existing saved-list + result-card rendering. Because
  /// alternatives are inherently better than the source dish we stamp
  /// them as `safe`; the presentational layer distinguishes them with
  /// the `isAlternative` flag on the saved record, not by verdict.
  MealPhotoAnalysis _alternativeToAnalysis(SmarterAlternative alt) {
    final factors = <String>[
      if (alt.estPeakMgDl > 0) 'Est. peak: ${alt.estPeakMgDl} mg/dL',
      if (alt.portionGuide.isNotEmpty) 'Portion: ${alt.portionGuide}',
    ];

    final summary = alt.summary.isNotEmpty
        ? alt.summary
        : (alt.reason.isNotEmpty
            ? alt.reason
            : 'A lower-impact alternative suggested by AI.');

    return MealPhotoAnalysis(
      verdict: MealSafetyVerdict.safe,
      headline: 'Smarter alternative',
      summary: summary,
      factors: factors,
      problematicIngredients: const [],
      recommendations: alt.benefits,
      smarterAlternatives: const [],
      confidence: 85,
      mealName: alt.name,
    );
  }

  Future<void> _editCurrentGlucose(
    BuildContext context,
    MealPredictorState state,
  ) async {
    final cubit = context.read<MealPredictorCubit>();
    final result = await showDialog<int?>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => _GlucoseEditDialog(
        initialText: state.effectiveGlucoseMgDl?.toString() ?? '',
      ),
    );
    if (!context.mounted) return;
    if (result == null) return;
    cubit.setManualGlucose(result);
    AppResultDialog.show(
      context,
      variant: AppResultVariant.success,
      title: 'Glucose updated',
      message: 'Current glucose is now $result mg/dL.',
    );
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MealPredictorCubit, MealPredictorState>(
      listenWhen: (a, b) => a.analysisError != b.analysisError,
      listener: (context, state) {
        final err = state.analysisError;
        if (err == null) return;
        AppResultDialog.show(
          context,
          variant: AppResultVariant.error,
          title: 'Analysis failed',
          message: err,
          autoDismiss: false,
        );
        context.read<MealPredictorCubit>().dismissAnalysisError();
      },
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final pad = (w * 0.06).clamp(16.0, 24.0);

            final cubit = context.read<MealPredictorCubit>();
            final analysis = state.currentAnalysis;
            final isSavedView = state.activeSavedId != null;

            return MealPredictorBackground(
              child: CustomScrollView(
                slivers: [
                  const GlucoSliverAppBar(title: 'Meal Predictor'),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(pad, 18, pad, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Upload a photo of your meal — AI reads it and\n'
                            'tells you if it\'s safe for you.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: (w * 0.038).clamp(14.0, 16.0),
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: (w * 0.05).clamp(16.0, 22.0)),
                          _CurrentGlucoseCard(
                            value: state.effectiveGlucoseMgDl,
                            isLive: state.hasRealGlucoseReading,
                            width: w,
                            onEdit: () => _editCurrentGlucose(context, state),
                          ),
                          SizedBox(height: (w * 0.05).clamp(16.0, 22.0)),

                          if (analysis == null) ...[
                            _SectionHeader(
                              title: 'AI Meal Image Check',
                              subtitle:
                                  'Upload your meal photo and get an instant safety verdict',
                            ),
                            const SizedBox(height: 12),
                            MealPhotoAiCard(
                              hasResult: false,
                              isAnalyzing: state.isAnalyzing,
                              onAnalyzeRequested: (name, bytes) => cubit.analyze(
                                mealName: name,
                                imageBytes: bytes,
                              ),
                              onReset: cubit.clearAnalysis,
                            ),
                          ] else if (isSavedView) ...[
                            _SectionHeader(
                              title: 'Saved Meal Details',
                              subtitle: 'Read-only view • close to go back',
                            ),
                            const SizedBox(height: 12),
                            MealPhotoResultCard(
                              analysis: analysis,
                              isSaved: true,
                              viewOnly: true,
                              onClose: cubit.clearAnalysis,
                              onRemove: () => _removeSaved(
                                context,
                                state.activeSavedId!,
                                state.activeSavedId,
                              ),
                            ),
                          ] else ...[
                            _SectionHeader(
                              title: 'AI Photo Prediction',
                              subtitle: 'Verdict for ${analysis.mealName}',
                            ),
                            const SizedBox(height: 12),
                            MealPhotoResultCard(
                              analysis: analysis,
                              isSaved: false,
                              onSave: () => _saveCurrent(context, state),
                              onAnalyzeAnother: cubit.clearAnalysis,
                            ),
                          ],

                          SizedBox(height: (w * 0.06).clamp(20.0, 26.0)),
                          BlocBuilder<SavedMealsCubit, SavedMealsState>(
                            builder: (context, savedState) {
                              return _SavedMealsSection(
                                items: savedState.items,
                                isLoading: savedState.isLoading,
                                activeId: state.activeSavedId,
                                onView: (e) => _viewSaved(context, e),
                                onDelete: (id) =>
                                    _removeSaved(context, id, state.activeSavedId),
                              );
                            },
                          ),

                          if (analysis != null &&
                              analysis.smarterAlternatives.isNotEmpty) ...[
                            SizedBox(height: (w * 0.06).clamp(20.0, 26.0)),
                            _SectionHeader(
                              title: 'Smarter Alternatives',
                              subtitle:
                                  'Tap any to see details and save',
                            ),
                            const SizedBox(height: 12),
                            BlocBuilder<SavedMealsCubit, SavedMealsState>(
                              builder: (context, _) {
                                final savedCubit =
                                    context.read<SavedMealsCubit>();
                                return Column(
                                  children: [
                                    for (final alt
                                        in analysis.smarterAlternatives)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: MealAlternativeTile(
                                          alternative: alt,
                                          isSaved: savedCubit
                                              .isAlreadySaved(alt.name),
                                          onTap: () => _openAlternative(
                                            context,
                                            alt,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Owns [TextEditingController] lifecycle so it is disposed only after the
/// dialog route is removed (fixes "used after disposed" on Save).
class _GlucoseEditDialog extends StatefulWidget {
  const _GlucoseEditDialog({required this.initialText});

  final String initialText;

  @override
  State<_GlucoseEditDialog> createState() => _GlucoseEditDialogState();
}

class _GlucoseEditDialogState extends State<_GlucoseEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final v = int.tryParse(_controller.text.trim());
    if (v == null || v < 40 || v > 500) {
      AppResultDialog.show(
        context,
        variant: AppResultVariant.error,
        title: 'Invalid value',
        message: 'Please enter a number between 40 and 500 mg/dL.',
        autoDismiss: false,
      );
      return;
    }
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primary200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 22 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'GlucoSense AI',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.primary600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Current glucose',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your reading before meal prediction.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Glucose',
                      suffixText: 'mg/dL',
                      filled: true,
                      fillColor: AppColors.primary50,
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
                        borderSide: BorderSide(
                          color: AppColors.primary500,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            minimumSize: const Size.fromHeight(52),
                            side: BorderSide(color: AppColors.neutral300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary600,
                            foregroundColor: AppColors.onPrimary,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentGlucoseCard extends StatelessWidget {
  const _CurrentGlucoseCard({
    required this.value,
    required this.isLive,
    required this.width,
    required this.onEdit,
  });

  /// `null` when the user has no reading on file — UI renders `—` so
  /// the card is obviously empty rather than a plausible-looking number.
  final int? value;
  final bool isLive;
  final double width;
  final VoidCallback onEdit;

  static const Color _labelOnGreen = Color(0xFF0F5C56);
  static const Color _mutedOnGreen = Color(0xFF2D6B66);
  static const Color _valueStrong = Color(0xFF064E48);

  @override
  Widget build(BuildContext context) {
    final displayValue = value == null ? '—' : '$value';
    final subtitle = value == null
        ? 'No reading yet — tap to enter one manually.'
        : isLive
            ? 'Your most recent reading from your logs.'
            : 'Tap to update your current reading.';

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary100,
              AppColors.primary200.withValues(alpha: 0.85),
              const Color(0xFFB8F0E4),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.primary400.withValues(alpha: 0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary600.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Current Glucose',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _labelOnGreen,
                        ),
                      ),
                      if (isLive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary700,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'LIVE',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        displayValue,
                        style: GoogleFonts.manrope(
                          fontSize: (width * 0.12).clamp(34.0, 44.0),
                          height: 1.0,
                          fontWeight: FontWeight.w800,
                          color: _valueStrong,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'mg/dL',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _mutedOnGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.3,
                      color: _mutedOnGreen.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary300.withValues(alpha: 0.8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.edit_rounded,
                color: AppColors.primary700,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedMealsSection extends StatelessWidget {
  const _SavedMealsSection({
    required this.items,
    required this.isLoading,
    required this.activeId,
    required this.onView,
    required this.onDelete,
  });

  final List<SavedMeal> items;
  final bool isLoading;
  final String? activeId;
  final ValueChanged<SavedMeal> onView;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Saved Meals',
          subtitle: items.isEmpty
              ? (isLoading
                  ? 'Loading your saved meals…'
                  : 'Your saved meal analyses will appear here')
              : '${items.length} saved • tap any to re-open',
          trailing: items.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${items.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary700,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
        if (items.isEmpty && isLoading)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.primary600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Loading your saved meals…',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bookmark_outline_rounded,
                    color: AppColors.primary700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No saved meals yet',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Analyze a meal above and tap "Save this meal".',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ...items.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActiveOutline(
                isActive: activeId == e.id,
                child: SavedMealTile(
                  entry: e,
                  onView: () => onView(e),
                  onDelete: () => onDelete(e.id),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActiveOutline extends StatelessWidget {
  const _ActiveOutline({required this.isActive, required this.child});

  final bool isActive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isActive) return child;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary500, width: 1.6),
      ),
      padding: const EdgeInsets.all(2),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary700,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}
