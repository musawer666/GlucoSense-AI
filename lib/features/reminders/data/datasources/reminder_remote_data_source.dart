import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/reminder_settings.dart';
import '../models/reminder_settings_model.dart';

/// Low-level Firestore access for reminder settings.
/// Kept abstract so unit tests can fake it without a Firebase stack.
abstract class ReminderRemoteDataSource {
  Stream<ReminderSettings> watch(String uid);
  Future<ReminderSettings> fetch(String uid);
  Future<void> save(String uid, ReminderSettings settings);
}

class ReminderRemoteDataSourceImpl implements ReminderRemoteDataSource {
  ReminderRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _usersCollection = 'users';
  static const _settingsSubcollection = 'settings';
  static const _remindersDoc = 'reminders';

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _firestore
      .collection(_usersCollection)
      .doc(uid)
      .collection(_settingsSubcollection)
      .doc(_remindersDoc);

  @override
  Stream<ReminderSettings> watch(String uid) {
    return _doc(uid)
        .snapshots()
        .map(ReminderSettingsModel.fromDocOrDefaults);
  }

  @override
  Future<ReminderSettings> fetch(String uid) async {
    final snap = await _doc(uid).get();
    return ReminderSettingsModel.fromDocOrDefaults(snap);
  }

  @override
  Future<void> save(String uid, ReminderSettings settings) async {
    await _doc(uid).set(
      ReminderSettingsModel.toMap(settings),
      SetOptions(merge: true),
    );
  }
}
