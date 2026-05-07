import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// A user-defined snack reminder. Unlike main meals, snacks are ad-hoc:
/// the user may create 0..N of them with arbitrary times and labels.
///
/// IDs are deterministic (uuid) so notification IDs can be derived
/// consistently across reschedules.
class SnackReminder extends Equatable {
  const SnackReminder({
    required this.id,
    required this.label,
    required this.time,
    required this.enabled,
    this.daysOfWeek = const <int>{},
  });

  final String id;
  final String label;
  final TimeOfDay time;
  final bool enabled;

  /// ISO-8601 weekdays (1..7). Empty set = every day.
  final Set<int> daysOfWeek;

  bool isActiveOn(DateTime date) {
    if (daysOfWeek.isEmpty) return true;
    return daysOfWeek.contains(date.weekday);
  }

  SnackReminder copyWith({
    String? id,
    String? label,
    TimeOfDay? time,
    bool? enabled,
    Set<int>? daysOfWeek,
  }) {
    return SnackReminder(
      id: id ?? this.id,
      label: label ?? this.label,
      time: time ?? this.time,
      enabled: enabled ?? this.enabled,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    );
  }

  @override
  List<Object?> get props => [
        id,
        label,
        time.hour,
        time.minute,
        enabled,
        daysOfWeek,
      ];
}
