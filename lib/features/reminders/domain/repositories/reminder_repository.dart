import '../entities/reminder_settings.dart';

/// Contract for reading / writing the user's reminder configuration.
///
/// Implementations must convert underlying Firebase errors to typed
/// `Failure`s before rethrowing, so the Cubit / UI never see raw SDK
/// exceptions.
abstract class ReminderRepository {
  /// Reactive feed of the current user's reminder settings. Emits
  /// [ReminderSettings.defaults] when no document exists yet.
  Stream<ReminderSettings> watch(String uid);

  /// One-shot fetch (used by the scheduler on app open). Returns
  /// defaults when no document exists.
  Future<ReminderSettings> fetch(String uid);

  /// Persists the full settings document. We write the whole object
  /// rather than patching individual fields because reminder config
  /// is small and atomic-replace avoids partial-state bugs.
  Future<void> save(String uid, ReminderSettings settings);
}
