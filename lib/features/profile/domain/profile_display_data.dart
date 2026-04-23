/// Display model for Profile tab — wire to persistence / setup flow later.
class ProfileDisplayData {
  const ProfileDisplayData({
    required this.fullName,
    required this.email,
    required this.age,
    required this.biologicalSex,
    required this.heightCm,
    required this.weightKg,
    required this.bmi,
    required this.diabetesTypeLabel,
    required this.familyHistory,
    required this.hypertension,
    required this.heartDisease,
    required this.smokingLabel,
    required this.activityLabel,
    required this.hba1cDisplay,
    required this.medicationDisplay,
    required this.targetGlucoseMinMgDl,
    required this.targetGlucoseMaxMgDl,
  });

  final String fullName;
  final String email;

  /// Profile setup — personal
  final int age;
  final String biologicalSex;
  final int heightCm;
  final double weightKg;
  final double? bmi;

  /// Metabolic
  final String diabetesTypeLabel;
  final bool familyHistory;

  /// Medical details
  final bool hypertension;
  final bool heartDisease;
  final String smokingLabel;
  final String activityLabel;
  final String? hba1cDisplay;
  final String? medicationDisplay;

  /// Targets
  final int targetGlucoseMinMgDl;
  final int targetGlucoseMaxMgDl;

  /// BMI from height (cm) and weight (kg); null if height invalid.
  static double? computeBmi({required int heightCm, required double weightKg}) {
    if (heightCm <= 0) return null;
    final m = heightCm / 100.0;
    final v = weightKg / (m * m);
    return double.parse(v.toStringAsFixed(1));
  }

  ProfileDisplayData copyWith({
    String? fullName,
    String? email,
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
    String? hba1cDisplay,
    String? medicationDisplay,
    int? targetGlucoseMinMgDl,
    int? targetGlucoseMaxMgDl,
    bool clearHba1c = false,
    bool clearMedication = false,
  }) {
    final nh = heightCm ?? this.heightCm;
    final nw = weightKg ?? this.weightKg;
    final newBmi = (heightCm != null || weightKg != null)
        ? computeBmi(heightCm: nh, weightKg: nw)
        : (bmi ?? this.bmi);

    return ProfileDisplayData(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      age: age ?? this.age,
      biologicalSex: biologicalSex ?? this.biologicalSex,
      heightCm: nh,
      weightKg: nw,
      bmi: newBmi,
      diabetesTypeLabel: diabetesTypeLabel ?? this.diabetesTypeLabel,
      familyHistory: familyHistory ?? this.familyHistory,
      hypertension: hypertension ?? this.hypertension,
      heartDisease: heartDisease ?? this.heartDisease,
      smokingLabel: smokingLabel ?? this.smokingLabel,
      activityLabel: activityLabel ?? this.activityLabel,
      hba1cDisplay: clearHba1c ? null : (hba1cDisplay ?? this.hba1cDisplay),
      medicationDisplay:
          clearMedication ? null : (medicationDisplay ?? this.medicationDisplay),
      targetGlucoseMinMgDl:
          targetGlucoseMinMgDl ?? this.targetGlucoseMinMgDl,
      targetGlucoseMaxMgDl:
          targetGlucoseMaxMgDl ?? this.targetGlucoseMaxMgDl,
    );
  }

  /// Demo payload — replace with repository when setup data is saved.
  static ProfileDisplayData sample() {
    return const ProfileDisplayData(
      fullName: 'Sarah Jenkins',
      email: 'sarah.j@example.com',
      age: 34,
      biologicalSex: 'Female',
      heightCm: 165,
      weightKg: 62,
      bmi: 22.8,
      diabetesTypeLabel: 'Type 2',
      familyHistory: true,
      hypertension: false,
      heartDisease: false,
      smokingLabel: 'Never',
      activityLabel: 'Moderate',
      hba1cDisplay: '5.6',
      medicationDisplay: 'Metformin',
      targetGlucoseMinMgDl: 70,
      targetGlucoseMaxMgDl: 140,
    );
  }
}
