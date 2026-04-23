import '../../../profile/domain/entities/user_profile.dart';

/// Required inputs for the heuristic risk model. Returned as
/// human-readable labels so the UI can render them in an error card
/// without mapping field keys itself.
///
/// If the profile is `null`, every input is considered missing.
List<String> computeMissingRiskFields(UserProfile? profile) {
  final missing = <String>[];
  if (profile == null) {
    return const [
      'Gender',
      'Age',
      'BMI',
      'HbA1c',
      'Fasting glucose reading',
      'Pre-meal glucose reading',
      'Post-meal glucose reading',
    ];
  }

  if (profile.biologicalSex.trim().isEmpty) missing.add('Gender');
  if (profile.age <= 0) missing.add('Age');
  if (profile.bmi == null) missing.add('BMI');
  if (profile.hba1c == null) missing.add('HbA1c');
  if (profile.latestFastingMgDl == null) {
    missing.add('Fasting glucose reading');
  }
  if (profile.latestPreMealMgDl == null) {
    missing.add('Pre-meal glucose reading');
  }
  if (profile.latestPostMealMgDl == null) {
    missing.add('Post-meal glucose reading');
  }

  return missing;
}
