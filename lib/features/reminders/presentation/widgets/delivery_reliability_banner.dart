import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/services/notification_service.dart';

/// Diagnostics card shown at the top of the Reminders settings screen.
///
/// On Android three OS-level settings routinely block notifications —
/// and if *any* of them are wrong, reminders silently fail:
///
///   1. POST_NOTIFICATIONS permission (Android 13+). Without it,
///      nothing ever shows up — not even an instant [showNow].
///   2. Exact-alarm permission (Android 12+). Without it, scheduled
///      reminders slip by minutes or get dropped during Doze.
///   3. Battery-optimisation exemption (OEM-aggressive phones:
///      Samsung One UI, Xiaomi MIUI, Oppo, Vivo). Without it,
///      scheduled alarms get cancelled when the app is backgrounded.
///
/// The banner surfaces all three live, offers one-tap fixes, and
/// provides **two** test buttons:
///   • "Test now" — fires an instant notification via `showNow`. If
///     this doesn't appear, the OS is blocking notifications entirely.
///   • "Test 15s" — schedules a notification 15 s in the future. If
///     "Test now" works but "Test 15s" doesn't, scheduling /
///     battery optimisation is at fault.
class DeliveryReliabilityBanner extends StatefulWidget {
  const DeliveryReliabilityBanner({super.key});

  @override
  State<DeliveryReliabilityBanner> createState() =>
      _DeliveryReliabilityBannerState();
}

class _DeliveryReliabilityBannerState extends State<DeliveryReliabilityBanner>
    with WidgetsBindingObserver {
  static const int _instantTestId = 999000;
  static const int _scheduledTestId = 999001;
  static const Color _errorColor = Color(0xFFDC2626);

  bool _loading = true;
  bool _notificationsEnabled = true;
  bool _exactAlarmGranted = true;
  bool _batteryExempt = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final service = NotificationService.instance;
    final notifEnabled = await service.areNotificationsEnabled();
    final exactAlarm = await service.recheckExactAlarmPermission();
    final batteryExempt = await service.isIgnoringBatteryOptimizations();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _notificationsEnabled = notifEnabled;
      _exactAlarmGranted = exactAlarm;
      _batteryExempt = batteryExempt;
    });
  }

  Future<void> _fix() async {
    if (_busy) return;
    setState(() => _busy = true);
    final service = NotificationService.instance;

    try {
      if (!_notificationsEnabled) {
        final granted = await service.requestNotificationPermission();
        if (!granted && mounted) {
          await service.openAppSettingsPage();
        }
      }
      if (!_exactAlarmGranted) {
        await service.recheckExactAlarmPermission();
      }
      if (!_batteryExempt) {
        final granted = await service.requestIgnoreBatteryOptimizations();
        if (!granted && mounted) {
          await service.openAppSettingsPage();
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      await _refresh();
    }
  }

  Future<void> _sendInstantTest() async {
    if (_busy) return;
    setState(() => _busy = true);

    final service = NotificationService.instance;
    await service.diagnose();
    await service.showNow(
      id: _instantTestId,
      title: '✅ Instant test',
      body:
          'If you can see this, the app can post notifications. Now try "Test 15s".',
      channelId: NotificationService.remindersChannelId,
    );

    if (!mounted) return;
    setState(() => _busy = false);
    _showSnack(
      'Instant notification sent. Pull down the shade if you don\'t see a pop-up.',
      success: true,
    );
  }

  Future<void> _sendScheduledTest() async {
    if (_busy) return;
    setState(() => _busy = true);

    final service = NotificationService.instance;
    await service.diagnose();
    final when = DateTime.now().add(const Duration(seconds: 15));
    final ok = await service.scheduleAt(
      id: _scheduledTestId,
      title: '⏰ Scheduled test',
      body:
          'If you see this on the lock screen with the app closed, scheduled delivery works.',
      when: when,
      channelId: NotificationService.remindersChannelId,
    );

    if (!mounted) return;
    setState(() => _busy = false);
    _showSnack(
      ok
          ? 'Scheduled for 15 s from now. Lock the phone and wait.'
          : 'Failed to schedule. Check the status rows above.',
      success: ok,
    );
  }

  void _showSnack(String message, {required bool success}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? AppColors.primary600 : _errorColor,
          content: Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final allGood =
        _notificationsEnabled && _exactAlarmGranted && _batteryExempt;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: allGood
              ? [AppColors.primary50, Colors.white]
              : [AppColors.tertiary100, AppColors.tertiary50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allGood ? AppColors.primary200 : AppColors.tertiary300,
        ),
        boxShadow: allGood
            ? const []
            : [
                BoxShadow(
                  color: AppColors.tertiary400.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _StatusIcon(allGood: allGood),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      allGood ? 'Delivery looks good' : 'Reminders may not fire',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: allGood
                            ? AppColors.primary900
                            : AppColors.tertiary900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      allGood
                          ? 'Reminders will fire on time, even with the screen off.'
                          : 'Your device is blocking notifications. Fix the items below.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        height: 1.35,
                        color: allGood
                            ? AppColors.primary900.withValues(alpha: 0.75)
                            : AppColors.tertiary800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CheckRow(
            label: 'Notifications allowed',
            granted: _notificationsEnabled,
          ),
          const SizedBox(height: 6),
          _CheckRow(
            label: 'Exact alarm permission',
            granted: _exactAlarmGranted,
          ),
          const SizedBox(height: 6),
          _CheckRow(
            label: 'Battery optimisation disabled',
            granted: _batteryExempt,
          ),
          const SizedBox(height: 12),
          if (!allGood) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _fix,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.tertiary600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _busy
                    ? const _Spinner()
                    : Text(
                        'Fix',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _sendInstantTest,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: allGood
                        ? AppColors.primary700
                        : AppColors.tertiary700,
                    side: BorderSide(
                      color: allGood
                          ? AppColors.primary300
                          : AppColors.tertiary400,
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Test now',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _sendScheduledTest,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: allGood
                        ? AppColors.primary700
                        : AppColors.tertiary700,
                    side: BorderSide(
                      color: allGood
                          ? AppColors.primary300
                          : AppColors.tertiary400,
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Test 15s',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.allGood});
  final bool allGood;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: allGood ? AppColors.primary600 : AppColors.tertiary500,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        allGood ? Icons.check_rounded : Icons.warning_amber_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.label, required this.granted});

  final String label;
  final bool granted;

  static const Color _errorColor = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          granted ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 16,
          color: granted ? AppColors.primary600 : _errorColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: granted
                  ? AppColors.textPrimary
                  : AppColors.textPrimary.withValues(alpha: 0.85),
            ),
          ),
        ),
        Text(
          granted ? 'Granted' : 'Blocked',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: granted ? AppColors.primary600 : _errorColor,
          ),
        ),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 14,
      height: 14,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}
