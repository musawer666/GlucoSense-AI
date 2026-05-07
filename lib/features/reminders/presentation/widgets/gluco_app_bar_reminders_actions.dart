import 'package:flutter/material.dart';

import '../pages/reminders_settings_screen.dart';

/// Same trailing control as the Log tab: opens reminder / notification settings.
///
/// Use as [GlucoSliverAppBar.actions] on primary shells for consistency.
List<Widget> glucoAppBarRemindersActions() => const [
      RemindersAppBarIconButton(),
      SizedBox(width: 4),
    ];

class RemindersAppBarIconButton extends StatelessWidget {
  const RemindersAppBarIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Reminders',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const RemindersSettingsScreen(),
          ),
        );
      },
      icon: const Icon(
        Icons.notifications_active_rounded,
        color: Colors.white,
      ),
    );
  }
}
