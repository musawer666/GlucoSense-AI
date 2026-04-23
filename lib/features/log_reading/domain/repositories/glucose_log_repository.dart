import '../glucose_log_entry.dart';

/// Abstract contract for reading / writing glucose logs.
///
/// Implementations must funnel every thrown error through the shared
/// `mapAnyError` so the Cubit / UI layers only ever see typed
/// `Failure`s, never raw Firebase exceptions.
abstract class GlucoseLogRepository {
  /// Realtime stream of the user's recent logs, newest first.
  /// Emits an empty list when the user has not logged anything yet.
  Stream<List<GlucoseLogEntry>> watchRecent(String uid, {int limit = 50});

  /// Persists [entry] and updates the user profile's denormalized
  /// latest fields atomically. Returns the persisted entry with a
  /// resolved `id`.
  Future<GlucoseLogEntry> save(String uid, GlucoseLogEntry entry);
}
