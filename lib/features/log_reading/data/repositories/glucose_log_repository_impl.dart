import '../../../../core/errors/firebase_error_mapper.dart';
import '../../domain/glucose_log_entry.dart';
import '../../domain/repositories/glucose_log_repository.dart';
import '../datasources/glucose_log_remote_data_source.dart';

/// Bridges domain ⇄ data source. Its only responsibility is to call
/// the remote source and funnel every raised error through
/// [mapAnyError] so the Cubit / UI only ever see typed `Failure`s.
class GlucoseLogRepositoryImpl implements GlucoseLogRepository {
  GlucoseLogRepositoryImpl({required this.remoteDataSource});

  final GlucoseLogRemoteDataSource remoteDataSource;

  @override
  Stream<List<GlucoseLogEntry>> watchRecent(String uid, {int limit = 50}) {
    return remoteDataSource
        .watchRecent(uid, limit: limit)
        .handleError((Object error, StackTrace _) => throw mapAnyError(error));
  }

  @override
  Future<GlucoseLogEntry> save(String uid, GlucoseLogEntry entry) async {
    try {
      return await remoteDataSource.save(uid, entry);
    } catch (error) {
      throw mapAnyError(error);
    }
  }
}
