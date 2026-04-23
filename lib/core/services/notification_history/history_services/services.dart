import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/notification_history_item.dart';

/// Hive-backed log of notifications that were actually delivered to the user.
///
/// Responsibilities:
///  - Persist a rolling history of delivered notifications.
///  - Expose read / clear APIs for the UI.
///  - Cap storage to avoid unbounded growth.
///
/// NOTE: must be initialized once, after `Hive.initFlutter()`, before any
/// `NotificationService` call that may save to history.
class NotificationHistoryService {
  NotificationHistoryService._internal();
  static final NotificationHistoryService instance =
      NotificationHistoryService._internal();

  static const String _boxName = 'notification_history_box';

  /// Hard cap to prevent the Hive box from growing forever.
  /// Trimming keeps the most recent entries.
  static const int _maxEntries = 500;

  Box? _box;
  bool get isInitialized => _box != null && _box!.isOpen;

  /// Open the Hive box. Safe to call multiple times.
  Future<void> init() async {
    if (isInitialized) return;
    try {
      _box = await Hive.openBox(_boxName);
      debugPrint(
          '✅ NotificationHistoryService ready (entries=${_box?.length ?? 0})');
    } catch (e) {
      debugPrint('❌ NotificationHistoryService.init failed: $e');
      rethrow;
    }
  }

  /// Persist a delivered notification.
  /// Silently no-ops if not initialized, so the notification flow never crashes.
  Future<void> save({
    required String title,
    required String body,
    required String channelId,
    DateTime? timestamp,
  }) async {
    final box = _box;
    if (box == null || !box.isOpen) {
      debugPrint('⚠️ History not initialized — skipping save: "$title"');
      return;
    }

    try {
      final item = NotificationHistoryItem(
        title: title,
        body: body,
        channelId: channelId,
        timestamp: timestamp ?? DateTime.now(),
      );

      await box.add(item.toMap());

      // Trim oldest if we exceed the cap (Hive keys are insertion-ordered ints).
      if (box.length > _maxEntries) {
        final overflow = box.length - _maxEntries;
        final keysToDelete = box.keys.take(overflow).toList();
        await box.deleteAll(keysToDelete);
      }
    } catch (e) {
      debugPrint('⚠️ History save error: $e');
    }
  }

  /// Returns history sorted newest-first.
  List<NotificationHistoryItem> getAll() {
    final box = _box;
    if (box == null || !box.isOpen) return const [];

    try {
      final items = box.values
          .whereType<Map>()
          .map(NotificationHistoryItem.fromMap)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return items;
    } catch (e) {
      debugPrint('⚠️ History getAll error: $e');
      return const [];
    }
  }

  /// Filter by channel (e.g. meal_channel, hydration_channel).
  List<NotificationHistoryItem> getByChannel(String channelId) {
    return getAll().where((i) => i.channelId == channelId).toList();
  }

  /// Listenable for reactive UIs (e.g. `ValueListenableBuilder`).
  ValueListenable<Box>? listenable() => _box?.listenable();

  int get count => _box?.length ?? 0;

  Future<void> clear() async {
    final box = _box;
    if (box == null || !box.isOpen) return;
    try {
      await box.clear();
    } catch (e) {
      debugPrint('⚠️ History clear error: $e');
    }
  }

  Future<void> close() async {
    final box = _box;
    if (box != null && box.isOpen) {
      await box.close();
      _box = null;
    }
  }
}
