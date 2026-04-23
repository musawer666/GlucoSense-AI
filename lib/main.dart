import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glucosense_ai/features/splash/presentation/pages/splash_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/colors/app_colors.dart';
import 'core/services/firebase_options.dart';
import 'core/services/notification_history/history_services/services.dart';
import 'core/services/notification_service.dart';
import 'core/widgets/app_text_scale_scope.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();

  await _bootstrapNotifications();

  runApp(const GlucoSenseApp());
}

/// Safely boots the notification stack. Any failure is logged but never
/// propagates, so the splash screen always renders.
Future<void> _bootstrapNotifications() async {
  try {
    await NotificationHistoryService.instance.init();
    await NotificationService.instance.init();
  } catch (e, st) {
    debugPrint('❌ Notification bootstrap failed: $e');
    debugPrintStack(stackTrace: st);
  }
}

class GlucoSenseApp extends StatelessWidget {
  const GlucoSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Clamp system font-size / display scaling so text stays within
      // designed bounds and does not overflow rows, app bars, buttons.
      builder: (context, child) {
        return AppTextScaleScope(
          minScaleFactor: 0.88,
          maxScaleFactor: 1.15,
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.neutral50,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
