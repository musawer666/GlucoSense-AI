part of 'saved_meals_cubit.dart';

/// Coarse lifecycle status used by screens to pick between spinners,
/// content and error placeholders. Transient save / delete errors are
/// carried on [SavedMealsState.errorMessage] without flipping this
/// back to `failure` so the list stays visible.
enum SavedMealsStatus { initial, loading, ready, failure }

class SavedMealsState extends Equatable {
  const SavedMealsState({
    this.status = SavedMealsStatus.initial,
    this.items = const <SavedMeal>[],
    this.errorMessage,
  });

  final SavedMealsStatus status;
  final List<SavedMeal> items;
  final String? errorMessage;

  bool get hasItems => items.isNotEmpty;
  bool get isLoading => status == SavedMealsStatus.loading;

  SavedMealsState copyWith({
    SavedMealsStatus? status,
    List<SavedMeal>? items,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SavedMealsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
