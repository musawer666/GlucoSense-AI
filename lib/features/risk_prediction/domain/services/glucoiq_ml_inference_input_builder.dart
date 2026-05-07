import '../../../../core/errors/failures.dart';
import '../../../profile/domain/entities/user_profile.dart';

/// Ordered feature keys expected by the Flask API / scaler (must stay in sync).
const glucoiqMlApiFeatureOrder = <String>[
  'gender',
  'age',
  'hypertension',
  'heart_disease',
  'smoking_history',
  'activity_level',
  'family_history',
  'bmi',
  'HbA1c_level',
  'fasting_glucose',
  'pre_meal_glucose',
  'post_meal_glucose',
];

/// Builds the JSON body for `POST /predict`.
///
/// **Training alignment:** numeric encodings below must match whatever was
/// used when fitting [scaler.pkl] and training the XGBoost model. If your
/// notebook used different codes, update this single place only.
abstract final class GlucoiqMlInferenceInputBuilder {
  GlucoiqMlInferenceInputBuilder._();

  /// Human-readable labels for missing inputs (consistent with risk heuristics).
  static List<String> missingFieldsForMl(UserProfile? profile) {
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

    final sexNorm = profile.biologicalSex.trim().toLowerCase();
    if (profile.biologicalSex.trim().isEmpty) {
      missing.add('Gender');
    } else if (sexNorm != 'male' && sexNorm != 'female') {
      missing.add('Gender (Male or Female — required by model)');
    }
    if (profile.age <= 0) missing.add('Age');
    if (_resolveBmi(profile) == null) missing.add('BMI');
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

  /// Returns a JSON-ready map with exact API keys and numeric values.
  ///
  /// Throws [ValidationFailure] when required profile data is absent.
  static Map<String, dynamic> buildPredictBody(UserProfile profile) {
    final missing = missingFieldsForMl(profile);
    if (missing.isNotEmpty) {
      throw ValidationFailure(
        'Missing data for prediction: ${missing.join(', ')}',
      );
    }

    final bmi = _resolveBmi(profile)!;
    final hba1c = profile.hba1c!;

    return {
      'gender': _encodeGender(profile.biologicalSex),
      'age': profile.age,
      'hypertension': profile.hypertension ? 1 : 0,
      'heart_disease': profile.heartDisease ? 1 : 0,
      'smoking_history': _encodeSmoking(profile.smokingLabel),
      'activity_level': _encodeActivity(profile.activityLabel),
      'family_history': profile.familyHistory ? 1 : 0,
      'bmi': bmi,
      'HbA1c_level': hba1c,
      'fasting_glucose': profile.latestFastingMgDl!,
      'pre_meal_glucose': profile.latestPreMealMgDl!,
      'post_meal_glucose': profile.latestPostMealMgDl!,
    };
  }

  static double? _resolveBmi(UserProfile profile) {
    if (profile.bmi != null && profile.bmi! > 0) return profile.bmi;
    final h = profile.heightCm;
    if (h <= 0) return null;
    final m = h / 100.0;
    if (m <= 0) return null;
    final w = profile.weightKg;
    if (w <= 0) return null;
    return w / (m * m);
  }

  /// Female = 0, Male = 1 (typical binary encoding).
  static int _encodeGender(String biologicalSex) {
    final s = biologicalSex.trim().toLowerCase();
    if (s == 'female') return 0;
    if (s == 'male') return 1;
    throw ValidationFailure(
      'Unsupported gender label for ML model: "$biologicalSex". '
      'Expected Male or Female.',
    );
  }

  /// Matches medical setup labels: Never / Former / Current.
  static int _encodeSmoking(String smokingLabel) {
    switch (smokingLabel.trim().toLowerCase()) {
      case 'never':
        return 0;
      case 'former':
        return 1;
      case 'current':
        return 2;
      default:
        throw ValidationFailure(
          'Unsupported smoking label for ML model: "$smokingLabel".',
        );
    }
  }

  /// Matches medical setup labels: Sedentary / Moderate / Active.
  static int _encodeActivity(String activityLabel) {
    switch (activityLabel.trim().toLowerCase()) {
      case 'sedentary':
        return 0;
      case 'moderate':
        return 1;
      case 'active':
        return 2;
      default:
        throw ValidationFailure(
          'Unsupported activity label for ML model: "$activityLabel".',
        );
    }
  }
}
