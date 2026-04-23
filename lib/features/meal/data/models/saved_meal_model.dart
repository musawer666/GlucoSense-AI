import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/meal_photo_analysis.dart';
import '../../domain/entities/saved_meal.dart';

/// Firestore mapping for `users/{uid}/saved_meals/{id}`.
///
/// The meal-photo analysis is stored as a nested map (`analysis.*`)
/// so we can evolve individual fields without schema migrations, while
/// top-level fields (`savedAt`, `currentGlucoseMgDl`, `isAlternative`)
/// stay query-friendly for future filters / indexing.
class SavedMealModel {
  const SavedMealModel._();

  /// Builds the payload for an `add()` write. Uses a server timestamp
  /// so the list ordering is consistent across devices / clocks.
  static Map<String, dynamic> toCreateMap({
    required MealPhotoAnalysis analysis,
    int? currentGlucoseMgDl,
    bool isAlternative = false,
  }) {
    return {
      'savedAt': FieldValue.serverTimestamp(),
      'isAlternative': isAlternative,
      'currentGlucoseMgDl': ?currentGlucoseMgDl,
      'analysis': _analysisToMap(analysis),
    };
  }

  /// Reads a Firestore document back into a pure [SavedMeal] domain
  /// entity. Missing or malformed fields fall back to safe defaults so
  /// a single bad record cannot crash the list.
  static SavedMeal fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data() ?? const <String, dynamic>{};
    final savedAtRaw = data['savedAt'];
    final savedAt = savedAtRaw is Timestamp
        ? savedAtRaw.toDate()
        : DateTime.now();

    return SavedMeal(
      id: snap.id,
      savedAt: savedAt,
      currentGlucoseMgDl: _readInt(data['currentGlucoseMgDl']),
      isAlternative: (data['isAlternative'] as bool?) ?? false,
      analysis: _analysisFromMap(
        (data['analysis'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Analysis <-> Map
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _analysisToMap(MealPhotoAnalysis a) => {
        'mealName': a.mealName,
        'verdict': _verdictKey(a.verdict),
        'headline': a.headline,
        'summary': a.summary,
        'confidence': a.confidence,
        'factors': List<String>.from(a.factors),
        'recommendations': List<String>.from(a.recommendations),
        'problematicIngredients': a.problematicIngredients
            .map((i) => {
                  'label': i.label,
                  'impact': i.impact,
                  'reason': i.reason,
                })
            .toList(),
        'smarterAlternatives': a.smarterAlternatives
            .map((alt) => {
                  'name': alt.name,
                  'estPeakMgDl': alt.estPeakMgDl,
                  'reason': alt.reason,
                  'summary': alt.summary,
                  'benefits': List<String>.from(alt.benefits),
                  'portionGuide': alt.portionGuide,
                })
            .toList(),
      };

  static MealPhotoAnalysis _analysisFromMap(Map<String, dynamic> m) {
    return MealPhotoAnalysis(
      mealName: (m['mealName'] as String?) ?? '',
      verdict: _parseVerdict(m['verdict'] as String?),
      headline: (m['headline'] as String?) ?? '',
      summary: (m['summary'] as String?) ?? '',
      confidence: _readInt(m['confidence']) ?? 0,
      factors: _readStringList(m['factors']),
      recommendations: _readStringList(m['recommendations']),
      problematicIngredients: _readList(m['problematicIngredients'])
          .map((e) => IngredientImpact(
                label: (e['label'] as String?) ?? '',
                impact: _readDouble(e['impact']) ?? 0.5,
                reason: (e['reason'] as String?) ?? '',
              ))
          .where((i) => i.label.isNotEmpty)
          .toList(growable: false),
      smarterAlternatives: _readList(m['smarterAlternatives'])
          .map((e) => SmarterAlternative(
                name: (e['name'] as String?) ?? '',
                estPeakMgDl: _readInt(e['estPeakMgDl']) ?? 0,
                reason: (e['reason'] as String?) ?? '',
                summary: (e['summary'] as String?) ?? '',
                benefits: _readStringList(e['benefits']),
                portionGuide: (e['portionGuide'] as String?) ?? '',
              ))
          .where((a) => a.name.isNotEmpty)
          .toList(growable: false),
    );
  }

  // ---------------------------------------------------------------------------
  // Primitive helpers — defensive so a malformed document cannot crash
  // the app. Missing / wrong-type fields resolve to empty defaults.
  // ---------------------------------------------------------------------------

  static int? _readInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static double? _readDouble(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  static List<String> _readStringList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> _readList(Object? raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  static String _verdictKey(MealSafetyVerdict v) {
    switch (v) {
      case MealSafetyVerdict.safe:
        return 'safe';
      case MealSafetyVerdict.caution:
        return 'caution';
      case MealSafetyVerdict.risky:
        return 'risky';
    }
  }

  static MealSafetyVerdict _parseVerdict(String? raw) {
    switch (raw) {
      case 'safe':
        return MealSafetyVerdict.safe;
      case 'risky':
        return MealSafetyVerdict.risky;
      case 'caution':
      default:
        return MealSafetyVerdict.caution;
    }
  }
}
