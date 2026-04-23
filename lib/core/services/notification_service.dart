import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_history/history_services/services.dart';

/// ─────────────────────────────────────────────────────────────────────
/// Background tap handler — must be top-level function
/// ─────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  debugPrint('🔔 BG tap: ${response.payload}');
  // Note: cannot save to Hive from background isolate reliably.
  // History is saved when notification fires (foreground) or on next app open.
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  bool _alarmManagerReady = false;
  bool _exactAlarmGranted = false;

  bool get exactAlarmGranted => _exactAlarmGranted;
  bool get alarmManagerReady => _alarmManagerReady;

  // ─────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;

    // ═══════════════════════════════════════════════════════
    // 1) TIMEZONE
    // ═══════════════════════════════════════════════════════
    try {
      tz.initializeTimeZones();

      final deviceOffsetMin = DateTime.now().timeZoneOffset.inMinutes;

      String tzName;
      try {
        tzName = await FlutterTimezone.getLocalTimezone();
      } catch (e) {
        tzName = _timezoneFromOffset(deviceOffsetMin);
      }

      tz.setLocalLocation(tz.getLocation(tzName));

      final tzOffsetMin = tz.local.currentTimeZone.offset ~/ 60000;
      final drift = (deviceOffsetMin - tzOffsetMin).abs();

      _alarmManagerReady = true;

      if (drift > 15) {
        debugPrint(
          '⚠️ TZ drift: $drift min (device=$deviceOffsetMin, tz=$tzOffsetMin). '
          'Scheduling may be slightly off but AlarmManager stays enabled.',
        );
      } else {
        debugPrint(
          '🌍 TZ ready: $tzName (device=$deviceOffsetMin, tz=$tzOffsetMin, drift=${drift}m)',
        );
      }
    } catch (e) {
      _alarmManagerReady = true;
      debugPrint(
          '⚠️ TZ init failed: $e — AlarmManager stays enabled (inexact fallback)');
    }

    // ═══════════════════════════════════════════════════════
    // 2) PLUGIN INIT
    // ═══════════════════════════════════════════════════════
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationFired,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // ═══════════════════════════════════════════════════════
    // 3) ANDROID — channels + permissions
    // ═══════════════════════════════════════════════════════
    if (!kIsWeb && Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            'hydration_channel',
            'Hydration Reminders',
            description: 'Reminders to drink water',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            'sleep_channel',
            'Sleep Reminders',
            description: 'Sleep and wake up reminders',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            'reminders_channel',
            'Reminders',
            description: 'General reminders',
            importance: Importance.high,
          ),
        );

        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            'meal_channel',
            'Meal Plan Reminders',
            description:
                'Meal plan generated + breakfast/lunch/dinner reminders',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        try {
          final notifGranted = await android.requestNotificationsPermission();
          debugPrint('🔔 Android notification permission: $notifGranted');
        } catch (e) {
          debugPrint('⚠️ requestNotificationsPermission: $e');
        }

        await _checkAndRequestExactAlarm(android);
      }
    }

    if (!kIsWeb && Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
      _alarmManagerReady = true;
      _exactAlarmGranted = true;
    }

    _initialized = true;
    debugPrint(
      '✅ NotificationService ready '
      '(time=${DateTime.now()}, offset=${DateTime.now().timeZoneOffset}, '
      'alarmBackup=$_alarmManagerReady, exactAlarm=$_exactAlarmGranted)',
    );
  }

  /// Called when a notification is tapped (foreground).
  /// This is our signal that the notification actually FIRED on the device.
  void _onNotificationFired(NotificationResponse response) {
    debugPrint('🔔 Tap: ${response.payload}');
    _saveDeliveredFromPayload(response.payload);
  }

  /// Parse payload and save to history — only for tapped/delivered notifications.
  Future<void> _saveDeliveredFromPayload(String? payload) async {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final title = (data['title'] ?? '').toString();
      final body = (data['body'] ?? '').toString();
      final channelId = (data['channelId'] ?? 'reminders_channel').toString();
      if (title.isEmpty) return;

      await NotificationHistoryService.instance.save(
        title: title,
        body: body,
        channelId: channelId,
      );
    } catch (e) {
      debugPrint('⚠️ Failed to parse notification payload for history: $e');
    }
  }

  Future<void> _checkAndRequestExactAlarm(
    AndroidFlutterLocalNotificationsPlugin android,
  ) async {
    try {
      final canSchedule = await android.canScheduleExactNotifications();
      _exactAlarmGranted = canSchedule ?? false;

      if (!_exactAlarmGranted) {
        try {
          await android.requestExactAlarmsPermission();
        } catch (_) {}

        final recheckResult = await android.canScheduleExactNotifications();
        _exactAlarmGranted = recheckResult ?? false;
      }

      debugPrint('🔔 Exact alarm permission: $_exactAlarmGranted');
    } catch (e) {
      _exactAlarmGranted = true;
      debugPrint('🔔 Exact alarm check not needed (pre-Android 12): $e');
    }
  }

  Future<bool> recheckExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;

    try {
      final result = await android.canScheduleExactNotifications();
      _exactAlarmGranted = result ?? false;
      debugPrint('🔔 Recheck exact alarm: $_exactAlarmGranted');
      return _exactAlarmGranted;
    } catch (_) {
      _exactAlarmGranted = true;
      return true;
    }
  }

  // ─────────────────────────────────────────────────────────
  // PAYLOAD BUILDER — encodes notification info for history
  // ─────────────────────────────────────────────────────────
  String _buildPayload({
    required String title,
    required String body,
    required String channelId,
  }) {
    return jsonEncode({
      'title': title,
      'body': body,
      'channelId': channelId,
      'scheduledAt': DateTime.now().toIso8601String(),
    });
  }

  // ─────────────────────────────────────────────────────────
  // SHOW INSTANT
  // ─────────────────────────────────────────────────────────
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String channelId = 'reminders_channel',
  }) async {
    if (!_initialized) return;
    try {
      final payload = _buildPayload(
        title: title,
        body: body,
        channelId: channelId,
      );

      await _plugin.show(id, title, body, _details(channelId),
          payload: payload);
      debugPrint('📢 NOW id=$id "$title"');

      // For instant notifications, save to history immediately
      // because they fire right now — no ambiguity about delivery.
      await _saveToHistory(title: title, body: body, channelId: channelId);
    } catch (e) {
      debugPrint('❌ showNow id=$id: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // SCHEDULE AT
  // ─────────────────────────────────────────────────────────
  Future<bool> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String channelId = 'reminders_channel',
  }) async {
    if (!_initialized) return false;

    final now = DateTime.now();
    final delay = when.difference(now);

    if (delay.inSeconds < 2) {
      debugPrint('⏭ id=$id in past/immediate — showing now');
      await showNow(id: id, title: title, body: body, channelId: channelId);
      return true;
    }

    await cancel(id);

    if (_alarmManagerReady) {
      await _scheduleZoned(
        id: id,
        title: title,
        body: body,
        when: when,
        channelId: channelId,
      );
    }

    // Scheduled notifications will be saved to history only when
    // they actually fire and the user taps them (via _onNotificationFired),
    // OR when the app verifies delivery on next open (via verifyAndRecordDelivered).

    debugPrint(
      '🕐 id=$id → ${_pad(when.hour)}:${_pad(when.minute)} '
      '(${delay.inMinutes}min) [AlarmManager ✓]',
    );

    return true;
  }

  /// Save notification to Hive history (only for instant / confirmed delivery).
  Future<void> _saveToHistory({
    required String title,
    required String body,
    required String channelId,
    DateTime? timestamp,
  }) async {
    try {
      await NotificationHistoryService.instance.save(
        title: title,
        body: body,
        channelId: channelId,
        timestamp: timestamp,
      );
    } catch (e) {
      debugPrint('⚠️ Failed to save notification to history: $e');
    }
  }

  /// Call on app startup to check which scheduled notifications
  /// have actually been delivered (their scheduled time has passed and
  /// they are no longer in the pending list).
  ///
  /// This catches notifications that fired while the app was closed
  /// (user didn't tap them, so [_onNotificationFired] never ran).
  Future<void> verifyAndRecordDelivered({
    required List<
            ({
              int id,
              String title,
              String body,
              String channelId,
              DateTime scheduledAt
            })>
        scheduled,
  }) async {
    if (!_initialized) return;

    try {
      final pending = await _plugin.pendingNotificationRequests();
      final pendingIds = pending.map((p) => p.id).toSet();
      final now = DateTime.now();

      int recorded = 0;

      for (final s in scheduled) {
        if (s.scheduledAt.isBefore(now) && !pendingIds.contains(s.id)) {
          await _saveToHistory(
            title: s.title,
            body: s.body,
            channelId: s.channelId,
            timestamp: s.scheduledAt,
          );
          recorded++;
        }
      }

      if (recorded > 0) {
        debugPrint('📋 Recorded $recorded delivered notifications to history');
      }
    } catch (e) {
      debugPrint('⚠️ verifyAndRecordDelivered error: $e');
    }
  }

  Future<void> _scheduleZoned({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required String channelId,
  }) async {
    final tzWhen = tz.TZDateTime(
      tz.local,
      when.year,
      when.month,
      when.day,
      when.hour,
      when.minute,
      when.second,
    );

    final now = tz.TZDateTime.now(tz.local);
    if (tzWhen.isBefore(now) || tzWhen.isAtSameMomentAs(now)) {
      debugPrint('  - AlarmManager skipped: tzWhen is in past');
      return;
    }

    final payload = _buildPayload(
      title: title,
      body: body,
      channelId: channelId,
    );

    if (_exactAlarmGranted) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzWhen,
          _details(channelId),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        debugPrint('  + AlarmManager backup (exact) ✓ ($tzWhen)');

        if (!kIsWeb && Platform.isAndroid) {
          try {
            final pending = await _plugin.pendingNotificationRequests();
            final found = pending.any((p) => p.id == id);
            if (!found) {
              debugPrint(
                  '  ⚠️ VERIFY FAILED: id=$id not in pending list after exact schedule!');
              // Fall through to inexact as backup
            } else {
              debugPrint(
                  '  ✅ VERIFY OK: id=$id registered (pending=${pending.length})');
              return;
            }
          } catch (e) {
            debugPrint('  ⚠️ VERIFY check failed: $e');
            return;
          }
        } else {
          return;
        }
      } catch (e) {
        debugPrint('  - AlarmManager exact failed: $e — trying inexact');
      }
    }

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzWhen,
        _details(channelId),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint('  + AlarmManager backup (inexact) ✓ ($tzWhen)');
    } catch (e) {
      debugPrint('  - AlarmManager backup failed entirely: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // CANCEL
  // ─────────────────────────────────────────────────────────
  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  Future<void> cancelRange(int start, int count) async {
    for (int i = 0; i < count; i++) {
      final id = start + i;
      try {
        await _plugin.cancel(id);
      } catch (_) {}
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (_) {
      return [];
    }
  }

  Future<void> debugPrintPending() async {
    try {
      final all = await _plugin.pendingNotificationRequests();
      debugPrint('📋 Pending: ${all.length} alarms');
      for (final p in all) {
        debugPrint('  → id=${p.id} "${p.title}"');
      }
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────
  // TIMEZONE FROM OFFSET — fallback
  // ─────────────────────────────────────────────────────────
  static String _timezoneFromOffset(int offsetMinutes) {
    const map = <int, String>{
      -600: 'Pacific/Honolulu',
      -540: 'America/Anchorage',
      -480: 'America/Los_Angeles',
      -420: 'America/Denver',
      -360: 'America/Chicago',
      -300: 'America/New_York',
      -240: 'America/Halifax',
      -180: 'America/Sao_Paulo',
      0: 'UTC',
      60: 'Europe/London',
      120: 'Europe/Berlin',
      180: 'Europe/Moscow',
      210: 'Asia/Tehran',
      240: 'Asia/Dubai',
      270: 'Asia/Kabul',
      300: 'Asia/Karachi',
      330: 'Asia/Kolkata',
      345: 'Asia/Kathmandu',
      360: 'Asia/Dhaka',
      420: 'Asia/Bangkok',
      480: 'Asia/Shanghai',
      540: 'Asia/Tokyo',
      570: 'Australia/Adelaide',
      600: 'Australia/Sydney',
      660: 'Pacific/Noumea',
      720: 'Pacific/Auckland',
    };
    return map[offsetMinutes] ?? 'UTC';
  }

  // ─────────────────────────────────────────────────────────
  // NOTIFICATION DETAILS
  // ─────────────────────────────────────────────────────────
  NotificationDetails _details(String channelId) {
    switch (channelId) {
      case 'hydration_channel':
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'hydration_channel',
            'Hydration Reminders',
            channelDescription: 'Reminders to drink water',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            autoCancel: true,
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        );

      case 'sleep_channel':
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'sleep_channel',
            'Sleep Reminders',
            channelDescription: 'Sleep and wake up reminders',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            autoCancel: true,
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        );

      case 'meal_channel':
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'meal_channel',
            'Meal Plan Reminders',
            channelDescription:
                'Meal plan generated + breakfast/lunch/dinner reminders',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            autoCancel: true,
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        );

      default:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminders_channel',
            'Reminders',
            channelDescription: 'General reminders',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
          ),
        );
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
