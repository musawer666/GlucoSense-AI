import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../data/datasources/saved_meal_remote_data_source.dart';
import '../../data/repositories/saved_meal_repository_impl.dart';
import '../cubit/saved_meals_cubit.dart';
import '../pages/saved_meal_detail_page.dart';
import 'saved_meal_tile.dart';

/// Saved-meals strip for the Home screen.
///
/// Self-sufficient: owns its own [SavedMealsCubit] so Home doesn't need
/// to know how meal persistence works. The cubit opens a real-time
/// Firestore listener on `users/{uid}/saved_meals`, so the strip
/// updates live as the user saves / deletes meals from other tabs.
class HomeSavedMealsSection extends StatelessWidget {
  const HomeSavedMealsSection({super.key, this.maxItems = 5});

  /// Caps the list so the Home screen never grows unbounded; the full
  /// collection lives on the Meal Predictor tab.
  final int maxItems;

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
      child: _HomeSavedMealsView(maxItems: maxItems),
    );
  }
}

class _HomeSavedMealsView extends StatelessWidget {
  const _HomeSavedMealsView({required this.maxItems});

  final int maxItems;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SavedMealsCubit, SavedMealsState>(
      builder: (context, state) {
        final items = state.items;
        final cubit = context.read<SavedMealsCubit>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(count: items.length, isLoading: state.isLoading),
            const SizedBox(height: 12),
            if (state.isLoading && items.isEmpty)
              const _LoadingState()
            else if (items.isEmpty)
              const _EmptyState()
            else
              ...items.take(maxItems).map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SavedMealTile(
                        entry: e,
                        onView: () => _openDetail(context, e.id),
                        onDelete: () => cubit.delete(e.id),
                      ),
                    ),
                  ),
            if (items.length > maxItems) ...[
              const SizedBox(height: 4),
              Text(
                'Showing $maxItems of ${items.length} — see all in Meal Predictor.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _openDetail(BuildContext context, String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SavedMealDetailPage(entryId: id),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.isLoading});

  final int count;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
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
                'My Saved Meals',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                count == 0
                    ? (isLoading
                        ? 'Loading your saved meals…'
                        : 'Meals and alternatives you save will appear here')
                    : 'Tap any to see the full verdict and details',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary700,
              ),
            ),
          ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                  'Analyze a meal in Meal Predictor and save it or an '
                  'alternative to see it here.',
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
    );
  }
}
