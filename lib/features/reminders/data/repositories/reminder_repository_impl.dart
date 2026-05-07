import '../../../../core/errors/firebase_error_mapper.dart';
import '../../domain/entities/reminder_settings.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/reminder_remote_data_source.dart';

/// Bridges domain ⇄ data. Only responsibility: funnel all errors through
/// [mapAnyError] so the Cubit / UI see typed `Failure`s.
class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRepositoryImpl({required this.remoteDataSource});

  final ReminderRemoteDataSource remoteDataSource;

  @override
  Stream<ReminderSettings> watch(String uid) {
    return remoteDataSource
        .watch(uid)
        .handleError((Object error, StackTrace _) => throw mapAnyError(error));
  }

  @override
  Future<ReminderSettings> fetch(String uid) async {
    try {
      return await remoteDataSource.fetch(uid);
    } catch (error) {
      throw mapAnyError(error);
    }
  }

  @override
  Future<void> save(String uid, ReminderSettings settings) async {
    try {
      await remoteDataSource.save(uid, settings);
    } catch (error) {
      throw mapAnyError(error);
    }
  }
}
