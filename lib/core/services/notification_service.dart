import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
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

  // ─────────────────────────────────────────────────────────
  // CHANNEL IDS
  //
  // ⚠️  NEVER reuse an old channel id after changing its
  // settings (importance / sound / vibration). Android FREEZES
  // channel config on first creation — the only way to ship
  // new settings is to use a new id and delete the old one.
  // Bump the `_v` suffix whenever you change channel config.
  // ─────────────────────────────────────────────────────────
  static const String remindersChannelId = 'glucosense_reminders_v2';
  static const String mealsChannelId = 'glucosense_meals_v2';
  static const String hydrationChannelId = 'glucosense_hydration_v2';
  static const String sleepChannelId = 'glucosense_sleep_v2';

  /// Legacy IDs we need to evict from the OS so their stale
  /// (silent) settings stop overriding notifications.
  static const List<String> _legacyChannelIds = [
    'reminders_channel',
    'meal_channel',
    'hydration_channel',
    'sleep_channel',
  ];

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  bool _alarmManagerReady = false;
  bool _exactAlarmGranted = false;

  bool get exactAlarmGranted => _exactAlarmGranted;
  bool get alarmManagerReady => _alarmManagerReady;

  /// Optional hook for higher-level code (e.g. [ReminderScheduler]) to
  /// intercept the raw payload on every foreground notification tap.
  /// Kept as a plain callback to avoid circular dependencies.
  void Function(NotificationResponse response)? onForegroundTap;

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
        await _setupAndroidChannels(android);

        try {
          final pluginGranted = await android.requestNotificationsPermission();
          debugPrint('🔔 plugin notification permission: $pluginGranted');
        } catch (e) {
          debugPrint('⚠️ plugin requestNotificationsPermission: $e');
        }

        // Double-up via permission_handler. On devices where the
        // plugin's request returns a stale `false` (e.g. already
        // denied once), this is the only reliable path to reach
        // the system dialog or to detect a permanent denial.
        try {
          final status = await Permission.notification.request();
          debugPrint('🔔 system notification permission: $status');
        } catch (e) {
          debugPrint('⚠️ permission_handler notification: $e');
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
    try {
      onForegroundTap?.call(response);
    } catch (e) {
      debugPrint('⚠️ onForegroundTap handler threw: $e');
    }
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

  /// Creates our current-version channels and removes any legacy
  /// channels whose frozen OS settings would otherwise silence us.
  ///
  /// Android locks a channel's behavior (importance, sound, vibration,
  /// visibility) the moment it's first created. Attempting to
  /// `createNotificationChannel()` again with new settings is a no-op.
  /// To ship new behavior we publish a brand-new id and evict the old
  /// one from the system settings so users see the new channel only.
  Future<void> _setupAndroidChannels(
    AndroidFlutterLocalNotificationsPlugin android,
  ) async {
    // 1) Delete legacy channels so notifications can never fall back
    //    onto their stale, silenced config.
    for (final legacyId in _legacyChannelIds) {
      try {
        await android.deleteNotificationChannel(legacyId);
      } catch (_) {
        // Deletion fails silently when the channel doesn't exist —
        // that's fine.
      }
    }

    // 2) Create fresh channels with the behavior we actually want.
    final channels = <AndroidNotificationChannel>[
      const AndroidNotificationChannel(
        remindersChannelId,
        'Reminders',
        description: 'Glucose logging and fasting reminders',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        mealsChannelId,
        'Meal Reminders',
        description: 'Pre- and post-meal glucose check-ins',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        hydrationChannelId,
        'Hydration',
        description: 'Reminders to drink water',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        sleepChannelId,
        'Sleep',
        description: 'Sleep and wake up reminders',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    ];

    for (final c in channels) {
      await android.createNotificationChannel(c);
    }

    debugPrint('🔔 Channels ready: ${channels.map((c) => c.id).join(', ')}');
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
  // OS-LEVEL NOTIFICATION PERMISSION (Android 13+)
  //
  // Without POST_NOTIFICATIONS granted, NOTHING shows up — not
  // heads-up, not shade, not sound. The plugin's
  // `requestNotificationsPermission` only shows the system dialog
  // the FIRST time; after a denial the OS silently returns false
  // forever. That's why we expose a forced-request + settings-
  // fallback path through permission_handler here.
  // ─────────────────────────────────────────────────────────

  /// `true` if the user has enabled notifications for this app at
  /// the OS level. On non-Android platforms assumes `true` — the
  /// plugin handles iOS permissions on its own.
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    try {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;
    } catch (_) {}

    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await android?.areNotificationsEnabled();
      return enabled ?? false;
    } catch (e) {
      debugPrint('⚠️ areNotificationsEnabled: $e');
      return false;
    }
  }

  /// Prompts the user for POST_NOTIFICATIONS. Returns the final
  /// granted state. If the user has already permanently denied,
  /// surfaces `false` — callers should then offer
  /// [openAppSettingsPage] as a fallback.
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final status = await Permission.notification.request();
      debugPrint('🔔 notification permission: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('⚠️ requestNotificationPermission: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // BATTERY OPTIMISATION — required for reliable delivery on
  // aggressive OEMs (Samsung One UI, Xiaomi MIUI, Oppo ColorOS,
  // Vivo FuntouchOS). Without this, scheduled alarms get silently
  // dropped when the app is backgrounded / screen off.
  // ─────────────────────────────────────────────────────────

  /// Returns `true` when the app is whitelisted from Doze / battery
  /// optimisation. On non-Android platforms always returns `true`.
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('⚠️ isIgnoringBatteryOptimizations: $e');
      return false;
    }
  }

  /// Requests the system dialog that lets the user whitelist the app
  /// from battery optimisation. Returns the granted state.
  ///
  /// IMPORTANT: the user can dismiss the dialog — in that case this
  /// returns `false` and the UI should offer a "Fix" affordance that
  /// leads to [openAppSettingsPage] instead.
  Future<bool> requestIgnoreBatteryOptimizations() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final status =
          await Permission.ignoreBatteryOptimizations.request();
      debugPrint('🔋 ignoreBatteryOptimizations: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('⚠️ requestIgnoreBatteryOptimizations: $e');
      return false;
    }
  }

  /// Opens the app's system settings so the user can manually adjust
  /// "Battery > Unrestricted" or (Samsung) "Battery > Don't put app
  /// to sleep". Useful as a fallback when the system dialog was
  /// declined.
  Future<bool> openAppSettingsPage() async {
    try {
      return await openAppSettings();
    } catch (e) {
      debugPrint('⚠️ openAppSettingsPage: $e');
      return false;
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
    String? payloadOverride,
  }) async {
    if (!_initialized) return;
    try {
      final payload = payloadOverride ??
          _buildPayload(
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
    String? payloadOverride,
  }) async {
    if (!_initialized) return false;

    final now = DateTime.now();
    final delay = when.difference(now);

    if (delay.inSeconds < 2) {
      debugPrint('⏭ id=$id in past/immediate — showing now');
      await showNow(
        id: id,
        title: title,
        body: body,
        channelId: channelId,
        payloadOverride: payloadOverride,
      );
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
        payloadOverride: payloadOverride,
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
    String? payloadOverride,
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

    final payload = payloadOverride ??
        _buildPayload(
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

  /// Returns the payload from the notification that cold-launched the
  /// app (tapped while the process was fully killed), or `null` if the
  /// app was opened normally.
  ///
  /// Must be called after [init] has completed. Returns `null` on
  /// platforms that don't surface launch details.
  Future<String?> consumeLaunchPayload() async {
    if (!_initialized) return null;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp != true) return null;
      return details?.notificationResponse?.payload;
    } catch (e) {
      debugPrint('⚠️ consumeLaunchPayload: $e');
      return null;
    }
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

  /// Dumps the full notification stack state to the console. Call
  /// this when a notification "should have fired" but didn't — the
  /// first failing line usually explains why.
  Future<void> diagnose() async {
    debugPrint('────────── 🔍 NOTIFICATION DIAGNOSTIC ──────────');
    debugPrint('initialized: $_initialized');
    debugPrint('alarmManagerReady: $_alarmManagerReady');
    debugPrint('exactAlarmGranted: $_exactAlarmGranted');

    final notifOn = await areNotificationsEnabled();
    debugPrint('OS notifications enabled: $notifOn');

    final batteryExempt = await isIgnoringBatteryOptimizations();
    debugPrint('battery optimisation disabled: $batteryExempt');

    if (!kIsWeb && Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      try {
        final channels = await android?.getNotificationChannels() ?? [];
        debugPrint('channels on device (${channels.length}):');
        for (final c in channels) {
          debugPrint(
            '  • id=${c.id} name="${c.name}" '
            'importance=${c.importance.value} '
            'sound=${c.playSound} vibration=${c.enableVibration}',
          );
        }
      } catch (e) {
        debugPrint('⚠️ getNotificationChannels failed: $e');
      }
    }

    await debugPrintPending();
    debugPrint('──────────────────────────────────────────────');
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
  /// Normalises any incoming channel id (including legacy ones) onto
  /// the current-version id so callers never have to be updated in
  /// lockstep with channel bumps.
  String _resolveChannelId(String incoming) {
    switch (incoming) {
      case 'reminders_channel':
      case remindersChannelId:
        return remindersChannelId;
      case 'meal_channel':
      case mealsChannelId:
        return mealsChannelId;
      case 'hydration_channel':
      case hydrationChannelId:
        return hydrationChannelId;
      case 'sleep_channel':
      case sleepChannelId:
        return sleepChannelId;
      default:
        return remindersChannelId;
    }
  }

  NotificationDetails _details(String channelId) {
    final resolved = _resolveChannelId(channelId);

    switch (resolved) {
      case hydrationChannelId:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            hydrationChannelId,
            'Hydration',
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

      case sleepChannelId:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            sleepChannelId,
            'Sleep',
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

      case mealsChannelId:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            mealsChannelId,
            'Meal Reminders',
            channelDescription: 'Pre- and post-meal glucose check-ins',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            autoCancel: true,
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.reminder,
            ticker: 'Reminder',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        );

      case remindersChannelId:
      default:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            remindersChannelId,
            'Reminders',
            channelDescription: 'Glucose logging and fasting reminders',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            autoCancel: true,
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.reminder,
            ticker: 'Reminder',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        );
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
