import 'package:equatable/equatable.dart';

/// Pure-Dart representation of the full post-signup profile.
///
/// Collected across two screens:
/// * **Profile Setup** — personal + metabolic basics + targets.
/// * **Medical Details** — conditions, lifestyle, clinical metrics.
///
/// Persisted as a flat merge on `users/{uid}` so both auth and
/// profile data live in a single document.
class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    this.email,

    // Personal
    required this.fullName,
    required this.age,
    required this.biologicalSex,
    required this.heightCm,
    required this.weightKg,
    this.bmi,

    // Metabolic
    required this.diabetesTypeLabel,
    required this.familyHistory,

    // Medical conditions
    required this.hypertension,
    required this.heartDisease,

    // Lifestyle
    required this.smokingLabel,
    required this.activityLabel,

    // Clinical (optional)
    this.hba1c,
    this.medication,

    // Targets (mg/dL)
    required this.targetGlucoseMinMgDl,
    required this.targetGlucoseMaxMgDl,

    // Denormalized latest-per-type used by the Risk screen and the
    // risk heuristic. Kept on the user doc so every risk-related
    // read is a single-document fetch.
    this.latestFastingMgDl,
    this.latestPreMealMgDl,
    this.latestPostMealMgDl,

    // Denormalized most-recent-overall log. Powers the Home tab's
    // "Current Glucose" card. Updated atomically whenever a log
    // is persisted to `users/{uid}/glucose_logs`.
    this.lastLogMgDl,
    this.lastLogType,
    this.lastLogAt,

    this.avatarUrl,
    this.profileComplete = false,
    this.profileCompletedAt,

    /// Last GlucoIQ `/predict` snapshot persisted on `users/{uid}`.
    this.lastMlRiskCategory,
    this.lastMlRiskConfidence,
    this.lastMlRiskAdvice,
    this.lastMlRiskProbabilities,
    this.lastMlRiskAt,
  });

  final String uid;
  final String? email;

  final String fullName;
  final int age;
  final String biologicalSex;
  final int heightCm;
  final double weightKg;
  final double? bmi;

  final String diabetesTypeLabel;
  final bool familyHistory;

  final bool hypertension;
  final bool heartDisease;

  final String smokingLabel;
  final String activityLabel;

  final double? hba1c;
  final String? medication;

  final int targetGlucoseMinMgDl;
  final int targetGlucoseMaxMgDl;

  final int? latestFastingMgDl;
  final int? latestPreMealMgDl;
  final int? latestPostMealMgDl;

  final int? lastLogMgDl;

  /// Canonical key of the most recent reading type — one of
  /// `fasting`, `preMeal`, `postMeal`.
  final String? lastLogType;
  final DateTime? lastLogAt;

  /// Public download URL for the user's avatar in Firebase Storage.
  /// `null` when the user has not uploaded one yet.
  final String? avatarUrl;

  final bool profileComplete;
  final DateTime? profileCompletedAt;

  final String? lastMlRiskCategory;
  final int? lastMlRiskConfidence;
  final String? lastMlRiskAdvice;
  final Map<String, double>? lastMlRiskProbabilities;
  final DateTime? lastMlRiskAt;

  /// Field-level copy. `null` on a named parameter keeps the
  /// existing value; use the `clearXxx` flags to explicitly drop a
  /// nullable field.
  UserProfile copyWith({
    String? uid,
    String? email,
    String? fullName,
    int? age,
    String? biologicalSex,
    int? heightCm,
    double? weightKg,
    double? bmi,
    String? diabetesTypeLabel,
    bool? familyHistory,
    bool? hypertension,
    bool? heartDisease,
    String? smokingLabel,
    String? activityLabel,
    double? hba1c,
    String? medication,
    int? targetGlucoseMinMgDl,
    int? targetGlucoseMaxMgDl,
    int? latestFastingMgDl,
    int? latestPreMealMgDl,
    int? latestPostMealMgDl,
    int? lastLogMgDl,
    String? lastLogType,
    DateTime? lastLogAt,
    String? avatarUrl,
    bool? profileComplete,
    DateTime? profileCompletedAt,
    String? lastMlRiskCategory,
    int? lastMlRiskConfidence,
    String? lastMlRiskAdvice,
    Map<String, double>? lastMlRiskProbabilities,
    DateTime? lastMlRiskAt,
    bool clearAvatarUrl = false,
    bool clearHba1c = false,
    bool clearMedication = false,
    bool clearLatestFastingMgDl = false,
    bool clearLatestPreMealMgDl = false,
    bool clearLatestPostMealMgDl = false,
    bool clearLastLogMgDl = false,
    bool clearLastLogType = false,
    bool clearLastLogAt = false,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      biologicalSex: biologicalSex ?? this.biologicalSex,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      bmi: bmi ?? this.bmi,
      diabetesTypeLabel: diabetesTypeLabel ?? this.diabetesTypeLabel,
      familyHistory: familyHistory ?? this.familyHistory,
      hypertension: hypertension ?? this.hypertension,
      heartDisease: heartDisease ?? this.heartDisease,
      smokingLabel: smokingLabel ?? this.smokingLabel,
      activityLabel: activityLabel ?? this.activityLabel,
      hba1c: clearHba1c ? null : (hba1c ?? this.hba1c),
      medication: clearMedication ? null : (medication ?? this.medication),
      targetGlucoseMinMgDl:
          targetGlucoseMinMgDl ?? this.targetGlucoseMinMgDl,
      targetGlucoseMaxMgDl:
          targetGlucoseMaxMgDl ?? this.targetGlucoseMaxMgDl,
      latestFastingMgDl: clearLatestFastingMgDl
          ? null
          : (latestFastingMgDl ?? this.latestFastingMgDl),
      latestPreMealMgDl: clearLatestPreMealMgDl
          ? null
          : (latestPreMealMgDl ?? this.latestPreMealMgDl),
      latestPostMealMgDl: clearLatestPostMealMgDl
          ? null
          : (latestPostMealMgDl ?? this.latestPostMealMgDl),
      lastLogMgDl: clearLastLogMgDl
          ? null
          : (lastLogMgDl ?? this.lastLogMgDl),
      lastLogType: clearLastLogType
          ? null
          : (lastLogType ?? this.lastLogType),
      lastLogAt: clearLastLogAt ? null : (lastLogAt ?? this.lastLogAt),
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      profileComplete: profileComplete ?? this.profileComplete,
      profileCompletedAt: profileCompletedAt ?? this.profileCompletedAt,
      lastMlRiskCategory: lastMlRiskCategory ?? this.lastMlRiskCategory,
      lastMlRiskConfidence:
          lastMlRiskConfidence ?? this.lastMlRiskConfidence,
      lastMlRiskAdvice: lastMlRiskAdvice ?? this.lastMlRiskAdvice,
      lastMlRiskProbabilities:
          lastMlRiskProbabilities ?? this.lastMlRiskProbabilities,
      lastMlRiskAt: lastMlRiskAt ?? this.lastMlRiskAt,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        fullName,
        age,
        biologicalSex,
        heightCm,
        weightKg,
        bmi,
        diabetesTypeLabel,
        familyHistory,
        hypertension,
        heartDisease,
        smokingLabel,
        activityLabel,
        hba1c,
        medication,
        targetGlucoseMinMgDl,
        targetGlucoseMaxMgDl,
        latestFastingMgDl,
        latestPreMealMgDl,
        latestPostMealMgDl,
        lastLogMgDl,
        lastLogType,
        lastLogAt,
        avatarUrl,
        profileComplete,
        profileCompletedAt,
        lastMlRiskCategory,
        lastMlRiskConfidence,
        lastMlRiskAdvice,
        lastMlRiskProbabilities,
        lastMlRiskAt,
      ];
}
