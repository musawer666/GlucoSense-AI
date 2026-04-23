import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../domain/glucose_log_entry.dart';
import '../models/glucose_log_model.dart';

/// Low-level contract for glucose-log persistence. Kept abstract so
/// it can be faked in unit tests without Firebase.
abstract class GlucoseLogRemoteDataSource {
  /// Realtime stream of the user's most recent logs, ordered by
  /// `createdAt` descending. Emits an empty list when the
  /// subcollection is empty.
  Stream<List<GlucoseLogEntry>> watchRecent(String uid, {int limit = 50});

  /// Persists [entry] under `users/{uid}/glucose_logs/{autoId}` and
  /// atomically patches the parent user doc's denormalized latest
  /// fields (`latestXxxMgDl`, `lastLogMgDl`, `lastLogType`,
  /// `lastLogAt`). Returns the entry with a resolved `id`.
  Future<GlucoseLogEntry> save(String uid, GlucoseLogEntry entry);
}

/// Firebase-backed implementation.
class GlucoseLogRemoteDataSourceImpl implements GlucoseLogRemoteDataSource {
  GlucoseLogRemoteDataSourceImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const _usersCollection = 'users';
  static const _logsSubcollection = 'glucose_logs';

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(_usersCollection).doc(uid);

  CollectionReference<Map<String, dynamic>> _logsCollection(String uid) =>
      _userDoc(uid).collection(_logsSubcollection);

  @override
  Stream<List<GlucoseLogEntry>> watchRecent(String uid, {int limit = 50}) {
    return _logsCollection(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => GlucoseLogModel.fromSnapshot(d, uid: uid))
              .toList(),
        );
  }

  @override
  Future<GlucoseLogEntry> save(String uid, GlucoseLogEntry entry) async {
    final current = _auth.currentUser;
    if (current == null) {
      throw const ServerException('You must be signed in to save a reading.');
    }

    final model = entry is GlucoseLogModel
        ? entry
        : GlucoseLogModel(
            id: entry.id,
            readingType: entry.readingType,
            glucoseMgDl: entry.glucoseMgDl,
            mealTag: entry.mealTag,
            mealName: entry.mealName,
            timestamp: entry.timestamp,
            userId: uid,
            createdAt: entry.createdAt,
          );

    final logRef = _logsCollection(uid).doc();
    final userRef = _userDoc(uid);

    // Atomic denormalization: append the log and update the user
    // doc's latest fields in a single transaction.
    final latestKey = _latestKeyFor(model.readingType);
    final batch = _firestore.batch()
      ..set(logRef, model.toCreateMap())
      ..set(userRef, {
        latestKey: model.glucoseMgDl,
        'lastLogMgDl': model.glucoseMgDl,
        'lastLogType': model.readingTypeKey,
        'lastLogAt': Timestamp.fromDate(model.timestamp),
      }, SetOptions(merge: true));

    await batch.commit();

    return GlucoseLogModel(
      id: logRef.id,
      userId: uid,
      glucoseMgDl: model.glucoseMgDl,
      readingType: model.readingType,
      mealTag: model.mealTag,
      mealName: model.mealName,
      timestamp: model.timestamp,
      createdAt: model.createdAt,
    );
  }

  String _latestKeyFor(GlucoseReadingType type) {
    switch (type) {
      case GlucoseReadingType.fasting:
        return 'latestFastingMgDl';
      case GlucoseReadingType.preMeal:
        return 'latestPreMealMgDl';
      case GlucoseReadingType.postMeal:
        return 'latestPostMealMgDl';
    }
  }
}
