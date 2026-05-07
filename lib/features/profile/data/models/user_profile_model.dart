import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_profile.dart';

/// Firestore-aware mapping for `users/{uid}` profile fields.
///
/// Keeps serialization in one place so the rest of the app can work
/// with the pure [UserProfile] entity without touching Firestore.
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.uid,
    super.email,
    required super.fullName,
    required super.age,
    required super.biologicalSex,
    required super.heightCm,
    required super.weightKg,
    super.bmi,
    required super.diabetesTypeLabel,
    required super.familyHistory,
    required super.hypertension,
    required super.heartDisease,
    required super.smokingLabel,
    required super.activityLabel,
    super.hba1c,
    super.medication,
    required super.targetGlucoseMinMgDl,
    required super.targetGlucoseMaxMgDl,
    super.latestFastingMgDl,
    super.latestPreMealMgDl,
    super.latestPostMealMgDl,
    super.lastLogMgDl,
    super.lastLogType,
    super.lastLogAt,
    super.avatarUrl,
    super.profileComplete,
    super.profileCompletedAt,
    super.lastMlRiskCategory,
    super.lastMlRiskConfidence,
    super.lastMlRiskAdvice,
    super.lastMlRiskProbabilities,
    super.lastMlRiskAt,
  });

  /// Payload used with `set(..., SetOptions(merge: true))` so it does
  /// not stomp on auth fields (`uid`, `email`, `createdAt`).
  ///
  /// `profileCompletedAt` is assigned server-side via
  /// [FieldValue.serverTimestamp] to keep timestamps consistent.
  Map<String, dynamic> toSetupMap() => {
        // Personal
        'fullName': fullName,
        'age': age,
        'biologicalSex': biologicalSex,
        'heightCm': heightCm,
        'weightKg': weightKg,
        if (bmi != null) 'bmi': bmi,

        // Metabolic
        'diabetesTypeLabel': diabetesTypeLabel,
        'familyHistory': familyHistory,

        // Conditions
        'hypertension': hypertension,
        'heartDisease': heartDisease,

        // Lifestyle
        'smokingLabel': smokingLabel,
        'activityLabel': activityLabel,

        // Clinical (optional — stored only when provided)
        if (hba1c != null) 'hba1c': hba1c,
        if (medication != null && medication!.isNotEmpty)
          'medication': medication,

        // Targets
        'targetGlucoseMinMgDl': targetGlucoseMinMgDl,
        'targetGlucoseMaxMgDl': targetGlucoseMaxMgDl,

        // Avatar (set separately post-upload; included here only if
        // the caller has already resolved a URL).
        if (avatarUrl != null && avatarUrl!.isNotEmpty) 'avatarUrl': avatarUrl,

        // Flags
        'profileComplete': true,
        'profileCompletedAt': FieldValue.serverTimestamp(),
      };

  factory UserProfileModel.fromMap(Map<String, dynamic> map, String id) {
    final ts = map['profileCompletedAt'];
    final lastAt = map['lastLogAt'];
    final lastRiskAt = map['lastMlRiskAt'];
    return UserProfileModel(
      uid: (map['uid'] as String?) ?? id,
      email: map['email'] as String?,
      fullName: (map['fullName'] as String?) ?? '',
      age: _asInt(map['age']) ?? 0,
      biologicalSex: (map['biologicalSex'] as String?) ?? '',
      heightCm: _asInt(map['heightCm']) ?? 0,
      weightKg: _asDouble(map['weightKg']) ?? 0,
      bmi: _asDouble(map['bmi']),
      diabetesTypeLabel: (map['diabetesTypeLabel'] as String?) ?? 'None',
      familyHistory: (map['familyHistory'] as bool?) ?? false,
      hypertension: (map['hypertension'] as bool?) ?? false,
      heartDisease: (map['heartDisease'] as bool?) ?? false,
      smokingLabel: (map['smokingLabel'] as String?) ?? 'Never',
      activityLabel: (map['activityLabel'] as String?) ?? 'Moderate',
      hba1c: _asDouble(map['hba1c']),
      medication: map['medication'] as String?,
      targetGlucoseMinMgDl: _asInt(map['targetGlucoseMinMgDl']) ?? 70,
      targetGlucoseMaxMgDl: _asInt(map['targetGlucoseMaxMgDl']) ?? 140,
      latestFastingMgDl: _asInt(map['latestFastingMgDl']),
      latestPreMealMgDl: _asInt(map['latestPreMealMgDl']),
      latestPostMealMgDl: _asInt(map['latestPostMealMgDl']),
      lastLogMgDl: _asInt(map['lastLogMgDl']),
      lastLogType: map['lastLogType'] as String?,
      lastLogAt: lastAt is Timestamp ? lastAt.toDate() : null,
      avatarUrl: map['avatarUrl'] as String?,
      profileComplete: (map['profileComplete'] as bool?) ?? false,
      profileCompletedAt: ts is Timestamp ? ts.toDate() : null,
      lastMlRiskCategory: map['lastMlRiskCategory'] as String?,
      lastMlRiskConfidence: _asInt(map['lastMlRiskConfidence']),
      lastMlRiskAdvice: map['lastMlRiskAdvice'] as String?,
      lastMlRiskProbabilities: _probabilitiesFromMap(map['lastMlRiskProbabilities']),
      lastMlRiskAt:
          lastRiskAt is Timestamp ? lastRiskAt.toDate() : null,
    );
  }

  static Map<String, double>? _probabilitiesFromMap(Object? raw) {
    if (raw is! Map) return null;
    final out = <String, double>{};
    for (final e in raw.entries) {
      final v = e.value;
      if (v is num) {
        out[e.key.toString()] = v.toDouble();
      }
    }
    return out.isEmpty ? null : out;
  }

  static int? _asInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _asDouble(Object? v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
