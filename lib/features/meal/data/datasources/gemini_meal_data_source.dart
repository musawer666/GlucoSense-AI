import 'dart:convert';
import 'dart:typed_data';

// The Gemini SDK also exports a `ServerException`; hide it to keep
// our core `ServerException` unambiguous at call sites.
import 'package:google_generative_ai/google_generative_ai.dart'
    hide ServerException;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../domain/entities/meal_photo_analysis.dart';

/// Low-level contract for talking to the Gemini API. Kept separate
/// from the repository so we can swap implementations (e.g. on-device
/// model, internal backend) without touching the rest of the feature.
abstract class GeminiMealDataSource {
  Future<MealPhotoAnalysis> analyze({
    required String mealName,
    required Uint8List imageBytes,
    int? currentGlucoseMgDl,
    UserProfile? profile,
  });
}

/// Concrete implementation backed by `google_generative_ai`.
///
/// Uses JSON mode with a strict [_responseSchema] so the parser can
/// trust the shape of the payload and fail loudly on malformed
/// responses (which the repository then maps to a typed `Failure`).
class GeminiMealDataSourceImpl implements GeminiMealDataSource {
  GeminiMealDataSourceImpl();

  GenerativeModel _buildModel() {
    AppConfig.requireGeminiApiKey();

    return GenerativeModel(
      model: AppConfig.geminiVisionModel,
      apiKey: AppConfig.geminiApiKey,
      systemInstruction: Content.text(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.3,
        topP: 0.95,
        // Gemini 2.5 models silently consume part of the token budget on
        // internal "thinking" tokens — 1.4k was too tight and caused
        // truncated / empty JSON. 4k gives headroom without being wasteful.
        maxOutputTokens: 4096,
        responseMimeType: 'application/json',
        responseSchema: _responseSchema,
      ),
      // Relaxed safety for food imagery. `SafetySetting` is NOT const
      // in the SDK, so the list itself cannot be const either.
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
    );
  }

  @override
  Future<MealPhotoAnalysis> analyze({
    required String mealName,
    required Uint8List imageBytes,
    int? currentGlucoseMgDl,
    UserProfile? profile,
  }) async {
    final model = _buildModel();

    final prompt = _buildUserPrompt(
      mealName: mealName,
      currentGlucoseMgDl: currentGlucoseMgDl,
      profile: profile,
    );

    final response = await model.generateContent([
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ]),
    ]);

    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      throw const ServerException(
        'The AI did not return any analysis. Please try again.',
      );
    }

    final json = _decodeJsonPayload(text);
    if (json == null) {
      // Show the first 120 chars of whatever the model did return so the
      // failure is actually diagnosable from the UI dialog.
      final snippet = text.length > 120 ? '${text.substring(0, 120)}…' : text;
      throw ServerException(
        'The AI returned an unexpected response. Please retry.\n'
        'Details: $snippet',
      );
    }

    return _mapJsonToAnalysis(json, fallbackName: mealName);
  }

  /// Tolerant JSON extractor.
  ///
  /// Gemini occasionally wraps the payload in markdown fences or prefixes
  /// a short disclaimer despite JSON mode. We therefore:
  ///   1. Try a direct `jsonDecode` on the trimmed text.
  ///   2. Strip ```json / ``` fences and retry.
  ///   3. Fall back to extracting the first top-level `{...}` block.
  ///
  /// Returns `null` only when no decodable JSON object can be recovered
  /// — the caller turns that into a user-facing error.
  Map<String, dynamic>? _decodeJsonPayload(String raw) {
    final candidates = <String>[];

    final trimmed = raw.trim();
    candidates.add(trimmed);

    var stripped = trimmed;
    if (stripped.startsWith('```')) {
      final firstNewline = stripped.indexOf('\n');
      if (firstNewline != -1) stripped = stripped.substring(firstNewline + 1);
      if (stripped.endsWith('```')) {
        stripped = stripped.substring(0, stripped.length - 3);
      }
      candidates.add(stripped.trim());
    }

    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      candidates.add(trimmed.substring(start, end + 1));
    }

    for (final c in candidates) {
      if (c.isEmpty) continue;
      try {
        final decoded = jsonDecode(c);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } catch (_) {
        // Try next candidate.
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Prompts
  // ---------------------------------------------------------------------------

  static const String _systemPrompt = '''
You are GlucoIQ, a clinical nutrition AI specialised in South-Asian
(Pakistani and North-Indian) cuisine and diabetic meal safety.

Your job is to look at a photo of a meal and return a strict JSON
object that tells the user whether the meal is safe to eat right now.

Hard rules:
1. Identify the dish from the image first. If the user-supplied name
   conflicts with what the image clearly shows, trust the image and
   name the dish accordingly (e.g. "Chicken Biryani", "Nihari",
   "Chapli Kabab with Naan", "Daal Chawal", "Aloo Paratha",
   "Chicken Karahi", "Haleem", "Chana Chaat", "Samosa", "Pakora",
   "Gulab Jamun", "Kheer", "Chai with sugar").
2. Assume realistic Pakistani/South-Asian portion sizes and cooking
   practices: generous ghee/oil, sugar in desserts and chai, white
   basmati rice, refined-flour naan/paratha.
3. Reason with the user's profile context: age, biological sex, BMI,
   HbA1c, diabetes type, hypertension, heart disease, smoking,
   activity, latest fasting / pre-meal / post-meal glucose, and
   target range. Also take the *current* glucose reading into
   account when it is provided.
4. Be direct and clinically honest. If a meal is risky for this user,
   say so plainly. Do not hedge verdicts to be polite.
5. Always provide 2-4 culturally-appropriate lower-impact swaps in
   `smarterAlternatives`. Each swap must be a realistic dish the user
   could actually eat (e.g. "Brown-rice Chicken Biryani", "Grilled
   Chicken with Salad", "Daal with half portion rice", "Masala oats").
   For every swap, produce: an estimated post-meal peak in mg/dL, a
   one-line headline reason, a 2-3 sentence `summary`, 2-4 short
   `benefits` chips, and a one-line `portionGuide` tailored to this
   user's BMI / activity level.
6. Confidence is an integer `0..100`. Keep it honest — use lower
   numbers when the image is blurry or the dish is ambiguous.
7. Never output anything outside the JSON schema. No prose, no
   markdown fences, no commentary.
''';

  String _buildUserPrompt({
    required String mealName,
    required int? currentGlucoseMgDl,
    required UserProfile? profile,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Meal label from user: "$mealName".');
    if (currentGlucoseMgDl != null) {
      buffer.writeln('Current glucose reading: $currentGlucoseMgDl mg/dL.');
    } else {
      buffer.writeln('Current glucose reading: not provided.');
    }

    if (profile != null) {
      buffer.writeln('');
      buffer.writeln('User profile:');
      buffer.writeln('- Sex: ${profile.biologicalSex}');
      buffer.writeln('- Age: ${profile.age}');
      buffer.writeln('- Height: ${profile.heightCm} cm');
      buffer.writeln('- Weight: ${profile.weightKg} kg');
      if (profile.bmi != null) {
        buffer.writeln('- BMI: ${profile.bmi!.toStringAsFixed(1)}');
      }
      buffer.writeln('- Diabetes type: ${profile.diabetesTypeLabel}');
      buffer.writeln('- Family history of diabetes: ${profile.familyHistory}');
      buffer.writeln('- Hypertension: ${profile.hypertension}');
      buffer.writeln('- Heart disease: ${profile.heartDisease}');
      buffer.writeln('- Smoking: ${profile.smokingLabel}');
      buffer.writeln('- Activity level: ${profile.activityLabel}');
      if (profile.hba1c != null) {
        buffer.writeln('- HbA1c: ${profile.hba1c!.toStringAsFixed(1)}%');
      }
      if (profile.medication != null && profile.medication!.trim().isNotEmpty) {
        buffer.writeln('- Medication: ${profile.medication}');
      }
      buffer.writeln(
        '- Target glucose range: '
        '${profile.targetGlucoseMinMgDl}-${profile.targetGlucoseMaxMgDl} mg/dL',
      );
      if (profile.latestFastingMgDl != null) {
        buffer.writeln(
          '- Latest fasting glucose: ${profile.latestFastingMgDl} mg/dL',
        );
      }
      if (profile.latestPreMealMgDl != null) {
        buffer.writeln(
          '- Latest pre-meal glucose: ${profile.latestPreMealMgDl} mg/dL',
        );
      }
      if (profile.latestPostMealMgDl != null) {
        buffer.writeln(
          '- Latest post-meal glucose: ${profile.latestPostMealMgDl} mg/dL',
        );
      }
    }

    buffer.writeln('');
    buffer.writeln(
      'Return ONLY the JSON object matching the response schema.',
    );
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Response schema + parser
  // ---------------------------------------------------------------------------

  static final Schema _responseSchema = Schema.object(
    properties: {
      'mealName': Schema.string(
        description: 'Canonical dish name as detected from the image.',
      ),
      'verdict': Schema.enumString(
        enumValues: ['safe', 'caution', 'risky'],
        description: 'Overall diabetic-safety verdict.',
      ),
      'headline': Schema.string(
        description: 'Short verdict line (max 40 chars).',
      ),
      'summary': Schema.string(
        description:
            'One- or two-sentence plain-language explanation for the user.',
      ),
      'confidence': Schema.integer(
        description: 'Confidence percentage 0..100.',
      ),
      'factors': Schema.array(
        description:
            'Short bullet chips summarising the reasoning inputs '
            '(e.g. "Fasting avg: 96 mg/dL").',
        items: Schema.string(),
      ),
      'problematicIngredients': Schema.array(
        description: 'Up to 5 unfavourable ingredients/nutrients.',
        items: Schema.object(
          properties: {
            'label': Schema.string(),
            'impact': Schema.number(
              description: 'Relative impact 0..1 (1 = worst).',
            ),
            'reason': Schema.string(),
          },
          requiredProperties: ['label', 'impact', 'reason'],
        ),
      ),
      'recommendations': Schema.array(
        description: '2-4 actionable, culturally-relevant suggestions.',
        items: Schema.string(),
      ),
      'smarterAlternatives': Schema.array(
        description:
            '2-4 culturally-appropriate lower-impact meal swaps, each '
            'with rich detail so the user can pick one to save.',
        items: Schema.object(
          properties: {
            'name': Schema.string(),
            'estPeakMgDl': Schema.integer(
              description:
                  'Estimated post-meal peak glucose in mg/dL for the swap.',
            ),
            'reason': Schema.string(
              description:
                  'One-line headline rationale (why this swap is better).',
            ),
            'summary': Schema.string(
              description:
                  '2-3 sentence explanation: what the dish is, why it suits '
                  "the user's profile, and when it is appropriate to eat.",
            ),
            'benefits': Schema.array(
              description:
                  '2-4 short benefit chips (e.g. "Higher fibre", '
                  '"Lower glycaemic index", "Lean protein").',
              items: Schema.string(),
            ),
            'portionGuide': Schema.string(
              description:
                  'One-line portion suggestion tailored to this user '
                  '(e.g. "½ cup brown rice + 1 bowl daal").',
            ),
          },
          requiredProperties: [
            'name',
            'estPeakMgDl',
            'reason',
            'summary',
            'benefits',
            'portionGuide',
          ],
        ),
      ),
    },
    requiredProperties: [
      'mealName',
      'verdict',
      'headline',
      'summary',
      'confidence',
      'factors',
      'problematicIngredients',
      'recommendations',
      'smarterAlternatives',
    ],
  );

  MealPhotoAnalysis _mapJsonToAnalysis(
    Map<String, dynamic> json, {
    required String fallbackName,
  }) {
    final rawName = (json['mealName'] as String?)?.trim() ?? '';
    final mealName = rawName.isNotEmpty ? rawName : fallbackName;

    final verdict = _parseVerdict(json['verdict'] as String?);

    final headline = (json['headline'] as String?)?.trim() ??
        _headlineForVerdict(verdict);

    final summary = (json['summary'] as String?)?.trim() ?? '';

    final confidence = _parseInt(json['confidence'], clampTo: [0, 100]) ?? 75;

    final factors = _parseStringList(json['factors']);
    final recommendations = _parseStringList(json['recommendations']);

    final problematic = <IngredientImpact>[];
    for (final entry in _parseMapList(json['problematicIngredients'])) {
      final label = (entry['label'] as String?)?.trim();
      if (label == null || label.isEmpty) continue;
      final impact = _parseDouble(entry['impact']) ?? 0.5;
      final reason = (entry['reason'] as String?)?.trim() ?? '';
      problematic.add(IngredientImpact(
        label: label,
        impact: impact.clamp(0.0, 1.0),
        reason: reason,
      ));
    }

    final alternatives = <SmarterAlternative>[];
    for (final entry in _parseMapList(json['smarterAlternatives'])) {
      final name = (entry['name'] as String?)?.trim();
      if (name == null || name.isEmpty) continue;
      final peak = _parseInt(entry['estPeakMgDl']) ?? 0;
      final reason = (entry['reason'] as String?)?.trim() ?? '';
      final summary = (entry['summary'] as String?)?.trim() ?? '';
      final portionGuide = (entry['portionGuide'] as String?)?.trim() ?? '';
      final benefits = _parseStringList(entry['benefits']);
      alternatives.add(SmarterAlternative(
        name: name,
        estPeakMgDl: peak,
        reason: reason,
        summary: summary,
        benefits: benefits,
        portionGuide: portionGuide,
      ));
    }

    return MealPhotoAnalysis(
      verdict: verdict,
      headline: headline,
      summary: summary,
      factors: factors,
      problematicIngredients: problematic,
      recommendations: recommendations,
      smarterAlternatives: alternatives,
      confidence: confidence,
      mealName: mealName,
    );
  }

  MealSafetyVerdict _parseVerdict(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'safe':
        return MealSafetyVerdict.safe;
      case 'risky':
      case 'danger':
      case 'avoid':
        return MealSafetyVerdict.risky;
      case 'caution':
      case 'moderate':
      default:
        return MealSafetyVerdict.caution;
    }
  }

  String _headlineForVerdict(MealSafetyVerdict verdict) {
    switch (verdict) {
      case MealSafetyVerdict.safe:
        return 'Safe to eat';
      case MealSafetyVerdict.caution:
        return 'Eat with caution';
      case MealSafetyVerdict.risky:
        return 'Better to avoid';
    }
  }

  List<String> _parseStringList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _parseMapList(Object? raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  int? _parseInt(Object? raw, {List<int>? clampTo}) {
    int? value;
    if (raw is int) {
      value = raw;
    } else if (raw is num) {
      value = raw.round();
    } else if (raw is String) {
      value = int.tryParse(raw);
    }
    if (value == null) return null;
    if (clampTo != null && clampTo.length == 2) {
      return value.clamp(clampTo[0], clampTo[1]);
    }
    return value;
  }

  double? _parseDouble(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }
}
