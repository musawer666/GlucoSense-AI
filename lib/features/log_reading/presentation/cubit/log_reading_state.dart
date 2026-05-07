import 'package:equatable/equatable.dart';

import '../../../profile/domain/entities/user_profile.dart';
import '../../domain/glucose_log_entry.dart';

enum LogReadingUiStatus {
  idle,
  loadingList,
  saving,
  saved,
  error,
}

class LogReadingState extends Equatable {
  const LogReadingState({
    this.uiStatus = LogReadingUiStatus.idle,
    this.recentLogs = const [],
    this.profile,
    this.readingType = GlucoseReadingType.preMeal,
    this.mealTag = MealLogTag.lunch,
    this.glucoseText = '',
    this.mealName = '',
    required this.timestamp,
    this.userMessage,
    this.validationMessage,
  });

  final LogReadingUiStatus uiStatus;
  final List<GlucoseLogEntry> recentLogs;
  final UserProfile? profile;
  final GlucoseReadingType readingType;
  final MealLogTag mealTag;
  final String glucoseText;
  final String mealName;
  final DateTime timestamp;
  final String? userMessage;
  final String? validationMessage;

  LogReadingState copyWith({
    LogReadingUiStatus? uiStatus,
    List<GlucoseLogEntry>? recentLogs,
    UserProfile? profile,
    GlucoseReadingType? readingType,
    MealLogTag? mealTag,
    String? glucoseText,
    String? mealName,
    DateTime? timestamp,
    String? userMessage,
    String? validationMessage,
    bool clearMessage = false,
    bool clearValidation = false,
  }) {
    return LogReadingState(
      uiStatus: uiStatus ?? this.uiStatus,
      recentLogs: recentLogs ?? this.recentLogs,
      profile: profile ?? this.profile,
      readingType: readingType ?? this.readingType,
      mealTag: mealTag ?? this.mealTag,
      glucoseText: glucoseText ?? this.glucoseText,
      mealName: mealName ?? this.mealName,
      timestamp: timestamp ?? this.timestamp,
      userMessage: clearMessage ? null : (userMessage ?? this.userMessage),
      validationMessage:
          clearValidation ? null : (validationMessage ?? this.validationMessage),
    );
  }

  static LogReadingState initial() => LogReadingState(
        timestamp: DateTime.now(),
      );

  @override
  List<Object?> get props => [
        uiStatus,
        recentLogs,
        profile,
        readingType,
        mealTag,
        glucoseText,
        mealName,
        timestamp,
        userMessage,
        validationMessage,
      ];
}
