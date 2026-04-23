import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/meal_photo_analysis.dart';
import '../../domain/entities/saved_meal.dart';
import '../../domain/repositories/saved_meal_repository.dart';

part 'saved_meals_state.dart';

/// Owns the reactive list of the signed-in user's saved meals.
///
/// Each screen that needs the list instantiates its own cubit (and
/// each cubit opens its own Firestore listener). Firestore's
/// per-client SDK cache coalesces these listeners so this is
/// effectively free — and keeps feature screens fully decoupled.
///
/// Save / delete actions are optimistic only insofar as the snapshot
/// stream will refresh the list within a heartbeat of the server
/// acknowledging the write.
class SavedMealsCubit extends Cubit<SavedMealsState> {
  SavedMealsCubit({
    required SavedMealRepository savedMealRepository,
    required AuthRepository authRepository,
  })  : _repository = savedMealRepository,
        _authRepository = authRepository,
        super(const SavedMealsState());

  final SavedMealRepository _repository;
  final AuthRepository _authRepository;

  StreamSubscription<List<SavedMeal>>? _sub;
  String? _userId;

  /// Opens the Firestore listener for the current user. Safe to call
  /// multiple times — the previous subscription (if any) is cancelled
  /// first.
  Future<void> subscribe() async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      emit(state.copyWith(
        status: SavedMealsStatus.failure,
        errorMessage: 'You must be signed in to view your saved meals.',
      ));
      return;
    }
    _userId = user.uid;

    emit(state.copyWith(status: SavedMealsStatus.loading, clearError: true));

    await _sub?.cancel();
    _sub = _repository.watchSavedMeals(user.uid).listen(
      (items) {
        emit(state.copyWith(
          status: SavedMealsStatus.ready,
          items: items,
          clearError: true,
        ));
      },
      onError: (Object error) {
        final msg = error is Failure
            ? error.message
            : 'Could not load your saved meals.';
        emit(state.copyWith(
          status: SavedMealsStatus.failure,
          errorMessage: msg,
        ));
      },
    );
  }

  /// Persists [analysis]. Returns the saved entry on success and
  /// `null` if the write failed (the UI gets the error via state).
  Future<SavedMeal?> save({
    required MealPhotoAnalysis analysis,
    int? currentGlucoseMgDl,
    bool isAlternative = false,
  }) async {
    final userId = _userId ?? _authRepository.getCurrentUser()?.uid;
    if (userId == null || userId.isEmpty) {
      emit(state.copyWith(
        errorMessage: 'You must be signed in to save meals.',
      ));
      return null;
    }

    try {
      final entry = await _repository.save(
        userId: userId,
        analysis: analysis,
        currentGlucoseMgDl: currentGlucoseMgDl,
        isAlternative: isAlternative,
      );
      if (!isClosed) emit(state.copyWith(clearError: true));
      return entry;
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(errorMessage: f.message));
      return null;
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(
          errorMessage: 'Could not save this meal. Please try again.',
        ));
      }
      return null;
    }
  }

  Future<void> delete(String id) async {
    final userId = _userId ?? _authRepository.getCurrentUser()?.uid;
    if (userId == null || userId.isEmpty) return;
    try {
      await _repository.delete(userId: userId, id: id);
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(errorMessage: f.message));
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(
          errorMessage: 'Could not remove this meal. Please try again.',
        ));
      }
    }
  }

  /// Pure check — useful for "already saved?" UI affordances before
  /// the user confirms a save.
  bool isAlreadySaved(String mealName) {
    final needle = mealName.trim().toLowerCase();
    if (needle.isEmpty) return false;
    return state.items.any(
      (e) => e.analysis.mealName.trim().toLowerCase() == needle,
    );
  }

  /// Clears the last non-fatal error banner after the UI has shown it.
  void dismissError() {
    if (state.errorMessage == null) return;
    emit(state.copyWith(clearError: true));
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    return super.close();
  }
}
