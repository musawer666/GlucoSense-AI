import '../domain/glucose_log_entry.dart';

/// In-memory store for glucose logs (demo data + session saves).
abstract final class GlucoseLogStore {
  GlucoseLogStore._();

  static final List<GlucoseLogEntry> _logs = <GlucoseLogEntry>[];
  static bool _useDemoData = true;
  static final List<GlucoseLogEntry> _demoLogs = <GlucoseLogEntry>[
    GlucoseLogEntry(
      readingType: GlucoseReadingType.fasting,
      glucoseMgDl: 96,
      mealTag: MealLogTag.breakfast,
      mealName: 'Morning baseline',
      timestamp: DateTime(2026, 4, 18, 7, 10),
    ),
    GlucoseLogEntry(
      readingType: GlucoseReadingType.preMeal,
      glucoseMgDl: 108,
      mealTag: MealLogTag.lunch,
      mealName: 'Chicken quinoa bowl',
      timestamp: DateTime(2026, 4, 18, 12, 40),
    ),
    GlucoseLogEntry(
      readingType: GlucoseReadingType.postMeal,
      glucoseMgDl: 142,
      mealTag: MealLogTag.lunch,
      mealName: 'Chicken quinoa bowl',
      timestamp: DateTime(2026, 4, 18, 14, 15),
    ),
    GlucoseLogEntry(
      readingType: GlucoseReadingType.preMeal,
      glucoseMgDl: 102,
      mealTag: MealLogTag.dinner,
      mealName: 'Salmon salad',
      timestamp: DateTime(2026, 4, 17, 19, 5),
    ),
    GlucoseLogEntry(
      readingType: GlucoseReadingType.postMeal,
      glucoseMgDl: 134,
      mealTag: MealLogTag.dinner,
      mealName: 'Salmon salad',
      timestamp: DateTime(2026, 4, 17, 20, 30),
    ),
  ];

  static List<GlucoseLogEntry> all() {
    final source = _useDemoData && _logs.isEmpty ? _demoLogs : _logs;
    final copy = List<GlucoseLogEntry>.of(source);
    copy.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return copy;
  }

  static bool get isUsingDemoData => _useDemoData && _logs.isEmpty;

  static void add(GlucoseLogEntry entry) {
    _logs.add(entry);
    _useDemoData = false;
  }

  /// Replaces session logs (e.g. after a future remote sync).
  static void replaceWithRemote(List<GlucoseLogEntry> entries) {
    _logs
      ..clear()
      ..addAll(entries);
    _useDemoData = false;
  }

  static void upsertLatestOfType({
    required GlucoseReadingType type,
    required int glucoseMgDl,
    MealLogTag? mealTag,
    String? mealName,
  }) {
    final existing = latestOfType(type);
    if (existing != null) {
      _logs.remove(existing);
      _logs.add(
        GlucoseLogEntry(
          readingType: type,
          glucoseMgDl: glucoseMgDl,
          mealTag: mealTag ?? existing.mealTag,
          mealName: mealName ?? existing.mealName,
          timestamp: DateTime.now(),
          userId: existing.userId,
        ),
      );
      _useDemoData = false;
      return;
    }
    _logs.add(
      GlucoseLogEntry(
        readingType: type,
        glucoseMgDl: glucoseMgDl,
        mealTag: mealTag ?? MealLogTag.snack,
        mealName: mealName ?? 'Manual update',
        timestamp: DateTime.now(),
      ),
    );
    _useDemoData = false;
  }

  static GlucoseLogEntry? latestOfType(GlucoseReadingType type) {
    for (final e in all()) {
      if (e.readingType == type) return e;
    }
    return null;
  }

  static double? averageOfType(GlucoseReadingType type) {
    final list = all().where((e) => e.readingType == type).toList();
    if (list.isEmpty) return null;
    final sum = list.fold<int>(0, (acc, e) => acc + e.glucoseMgDl);
    return sum / list.length;
  }

  static double? overallAverage() {
    final list = all();
    if (list.isEmpty) return null;
    final sum = list.fold<int>(0, (acc, e) => acc + e.glucoseMgDl);
    return sum / list.length;
  }
}
