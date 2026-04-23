part of 'home_bloc.dart';

enum HomeStatus { initial, loading, ready, missingProfile, failure }

/// The freshest glucose reading the Home dashboard has on record for
/// the signed-in user. Derived from the flat `latestXxxMgDl` fields
/// on the user profile document.
class HomeCurrentGlucose extends Equatable {
  const HomeCurrentGlucose({required this.mgDl, required this.type});

  final int mgDl;
  final HomeReadingType type;

  @override
  List<Object?> get props => [mgDl, type];
}

/// Lightweight mirror of `GlucoseReadingType` that keeps the Home
/// feature independent from `log_reading`'s internal model.
enum HomeReadingType { fasting, preMeal, postMeal }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.profile,
    this.errorMessage,
    this.recentLogs = const [],
  });

  final HomeStatus status;
  final UserProfile? profile;
  final String? errorMessage;

  /// Last 14 rows from `glucose_logs` (newest first from Firestore). The
  /// chart sorts by [GlucoseLogEntry.timestamp] ascending.
  final List<GlucoseLogEntry> recentLogs;

  bool get isLoading => status == HomeStatus.loading;
  bool get hasFailure => status == HomeStatus.failure;
  bool get hasProfile => profile != null;

  /// First token of the user's full name, nicely capitalised, or
  /// `null` when we don't yet have a profile. UI decides on the
  /// fallback copy.
  String? get firstName {
    final full = profile?.fullName.trim();
    if (full == null || full.isEmpty) return null;
    return full.split(RegExp(r'\s+')).first;
  }

  /// The **most recently saved log**, regardless of reading type.
  ///
  /// Backed by the `lastLogMgDl` / `lastLogType` fields which the
  /// Log Reading screen writes atomically with every new entry. This
  /// is the single contract the UI relies on — "whatever the user
  /// last saved in Log Reading is what Home shows".
  ///
  /// Falls back to the per-type latest values so a user whose data
  /// predates this change still sees something.
  HomeCurrentGlucose? get currentGlucose {
    final p = profile;
    if (p == null) return null;

    if (p.lastLogMgDl != null) {
      return HomeCurrentGlucose(
        mgDl: p.lastLogMgDl!,
        type: _readingTypeFromKey(p.lastLogType),
      );
    }

    if (p.latestPostMealMgDl != null) {
      return HomeCurrentGlucose(
        mgDl: p.latestPostMealMgDl!,
        type: HomeReadingType.postMeal,
      );
    }
    if (p.latestPreMealMgDl != null) {
      return HomeCurrentGlucose(
        mgDl: p.latestPreMealMgDl!,
        type: HomeReadingType.preMeal,
      );
    }
    if (p.latestFastingMgDl != null) {
      return HomeCurrentGlucose(
        mgDl: p.latestFastingMgDl!,
        type: HomeReadingType.fasting,
      );
    }
    return null;
  }

  static HomeReadingType _readingTypeFromKey(String? key) {
    switch (key) {
      case 'preMeal':
        return HomeReadingType.preMeal;
      case 'postMeal':
        return HomeReadingType.postMeal;
      case 'fasting':
      default:
        return HomeReadingType.fasting;
    }
  }

  /// Latest value per reading type (fasting → pre → post). Used for
  /// fallbacks; the Home chart uses [chartLogs] from Firestore.
  List<int> get glucoseHistory {
    final p = profile;
    if (p == null) return const [];
    return [
      if (p.latestFastingMgDl != null) p.latestFastingMgDl!,
      if (p.latestPreMealMgDl != null) p.latestPreMealMgDl!,
      if (p.latestPostMealMgDl != null) p.latestPostMealMgDl!,
    ];
  }

  /// Up to 14 logs for the line chart, oldest → newest by timestamp.
  List<GlucoseLogEntry> get chartLogs {
    if (recentLogs.isEmpty) return const [];
    const maxPoints = 14;
    final sorted = List<GlucoseLogEntry>.from(recentLogs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (sorted.length <= maxPoints) return sorted;
    return sorted.sublist(sorted.length - maxPoints);
  }

  HomeState copyWith({
    HomeStatus? status,
    UserProfile? profile,
    String? errorMessage,
    List<GlucoseLogEntry>? recentLogs,
    bool clearProfile = false,
    bool clearError = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      recentLogs: recentLogs ?? this.recentLogs,
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage, recentLogs];
}
