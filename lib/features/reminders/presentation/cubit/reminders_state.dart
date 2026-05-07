import 'package:equatable/equatable.dart';

import '../../domain/entities/reminder_settings.dart';

enum RemindersStatus { initial, loading, ready, saving, error }

class RemindersState extends Equatable {
  const RemindersState({
    required this.status,
    required this.settings,
    this.errorMessage,
    this.saveSuccessNonce = 0,
  });

  final RemindersStatus status;

  /// Always non-null. We seed with [ReminderSettings.defaults] so the
  /// UI can render even before the first Firestore snapshot arrives.
  final ReminderSettings settings;

  final String? errorMessage;

  /// Bumped on every successful save so the UI can react exactly once
  /// (toast / dialog) without having to diff the whole state.
  final int saveSuccessNonce;

  factory RemindersState.initial() {
    return RemindersState(
      status: RemindersStatus.initial,
      settings: ReminderSettings.defaults(),
    );
  }

  RemindersState copyWith({
    RemindersStatus? status,
    ReminderSettings? settings,
    String? errorMessage,
    bool clearError = false,
    int? saveSuccessNonce,
  }) {
    return RemindersState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      saveSuccessNonce: saveSuccessNonce ?? this.saveSuccessNonce,
    );
  }

  @override
  List<Object?> get props =>
      [status, settings, errorMessage, saveSuccessNonce];
}
