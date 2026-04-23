import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/widgets/app_result_dialog.dart';
import '../../../../core/widgets/gluco_sliver_app_bar.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../data/datasources/saved_meal_remote_data_source.dart';
import '../../data/repositories/saved_meal_repository_impl.dart';
import '../../domain/entities/saved_meal.dart';
import '../cubit/saved_meals_cubit.dart';
import '../widgets/meal_photo_ai_card.dart';
import '../widgets/meal_predictor_background.dart';

/// Full-screen, read-only view of a single [SavedMeal].
///
/// Owns its own [SavedMealsCubit] so the page stays consistent even
/// when opened from a screen that doesn't already provide one. The
/// cubit keeps the list fresh, so deletions made elsewhere immediately
/// reflect here (we render a "no longer saved" fallback instead of a
/// stale card).
class SavedMealDetailPage extends StatelessWidget {
  const SavedMealDetailPage({super.key, required this.entryId});

  /// Looked up against the live cubit state — never cached locally so
  /// we cannot render stale data.
  final String entryId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SavedMealsCubit>(
      create: (_) => SavedMealsCubit(
        savedMealRepository: SavedMealRepositoryImpl(
          remoteDataSource: SavedMealRemoteDataSourceImpl(),
        ),
        authRepository: AuthRepositoryImpl(
          remoteDataSource: AuthRemoteDataSourceImpl(),
        ),
      )..subscribe(),
      child: _SavedMealDetailView(entryId: entryId),
    );
  }
}

class _SavedMealDetailView extends StatelessWidget {
  const _SavedMealDetailView({required this.entryId});

  final String entryId;

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<SavedMealsCubit>();
    await cubit.delete(entryId);
    if (!context.mounted) return;
    Navigator.of(context).maybePop();
    AppResultDialog.show(
      context,
      variant: AppResultVariant.success,
      title: 'Removed',
      message: 'Meal removed from your saved meals.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<SavedMealsCubit, SavedMealsState>(
        builder: (context, state) {
          final items = state.items;
          final entry = items.where((e) => e.id == entryId).firstOrNull;

          if (state.isLoading && entry == null) {
            return const _LoadingShell();
          }
          if (entry == null) {
            return const _DeletedState();
          }

          return MealPredictorBackground(
            child: CustomScrollView(
              slivers: [
                const GlucoSliverAppBar(title: 'Saved Meal'),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _MetaStrip(entry: entry),
                        const SizedBox(height: 16),
                        MealPhotoResultCard(
                          analysis: entry.analysis,
                          isSaved: true,
                          viewOnly: true,
                          onClose: () => Navigator.of(context).maybePop(),
                          onRemove: () => _delete(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetaStrip extends StatelessWidget {
  const _MetaStrip({required this.entry});

  final SavedMeal entry;

  String get _formattedSavedAt {
    final t = entry.savedAt;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final now = DateTime.now();
    final isToday =
        t.year == now.year && t.month == now.month && t.day == now.day;
    if (isToday) return 'Today, $hh:$mm';
    return '${t.day}/${t.month}/${t.year} $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          Icon(
            entry.isAlternative
                ? Icons.eco_rounded
                : Icons.restaurant_menu_rounded,
            color: entry.isAlternative
                ? AppColors.primary700
                : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isAlternative
                      ? 'Saved as smarter alternative'
                      : 'Saved from meal photo analysis',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formattedSavedAt,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (entry.currentGlucoseMgDl != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.primary200),
              ),
              child: Text(
                '${entry.currentGlucoseMgDl} mg/dL',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoadingShell extends StatelessWidget {
  const _LoadingShell();

  @override
  Widget build(BuildContext context) {
    return MealPredictorBackground(
      child: CustomScrollView(
        slivers: [
          const GlucoSliverAppBar(title: 'Saved Meal'),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeletedState extends StatelessWidget {
  const _DeletedState();

  @override
  Widget build(BuildContext context) {
    return MealPredictorBackground(
      child: CustomScrollView(
        slivers: [
          const GlucoSliverAppBar(title: 'Saved Meal'),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 60,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'This meal is no longer saved.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
