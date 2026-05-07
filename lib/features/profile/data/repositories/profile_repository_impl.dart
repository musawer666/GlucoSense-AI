import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/firebase_error_mapper.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
import '../models/user_profile_model.dart';

/// Bridges domain ⇄ data source. Its only responsibility is to call
/// the remote source and funnel any raised error through
/// [mapAnyError] so the Bloc / UI layers only ever see typed
/// [Failure]s.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required this.remoteDataSource});

  final ProfileRemoteDataSource remoteDataSource;

  @override
  Future<UserProfile> saveProfileSetup(UserProfile profile) async {
    try {
      final model = profile is UserProfileModel
          ? profile
          : UserProfileModel(
              uid: profile.uid,
              email: profile.email,
              fullName: profile.fullName,
              age: profile.age,
              biologicalSex: profile.biologicalSex,
              heightCm: profile.heightCm,
              weightKg: profile.weightKg,
              bmi: profile.bmi,
              diabetesTypeLabel: profile.diabetesTypeLabel,
              familyHistory: profile.familyHistory,
              hypertension: profile.hypertension,
              heartDisease: profile.heartDisease,
              smokingLabel: profile.smokingLabel,
              activityLabel: profile.activityLabel,
              hba1c: profile.hba1c,
              medication: profile.medication,
              targetGlucoseMinMgDl: profile.targetGlucoseMinMgDl,
              targetGlucoseMaxMgDl: profile.targetGlucoseMaxMgDl,
              latestFastingMgDl: profile.latestFastingMgDl,
              latestPreMealMgDl: profile.latestPreMealMgDl,
              latestPostMealMgDl: profile.latestPostMealMgDl,
              lastLogMgDl: profile.lastLogMgDl,
              lastLogType: profile.lastLogType,
              lastLogAt: profile.lastLogAt,
              avatarUrl: profile.avatarUrl,
              lastMlRiskCategory: profile.lastMlRiskCategory,
              lastMlRiskConfidence: profile.lastMlRiskConfidence,
              lastMlRiskAdvice: profile.lastMlRiskAdvice,
              lastMlRiskProbabilities: profile.lastMlRiskProbabilities,
              lastMlRiskAt: profile.lastMlRiskAt,
            );
      return await remoteDataSource.saveProfileSetup(model);
    } catch (error) {
      throw mapAnyError(error);
    }
  }

  @override
  Future<UserProfile?> getProfile(String uid) async {
    try {
      return await remoteDataSource.getProfile(uid);
    } catch (error) {
      throw mapAnyError(error);
    }
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    // Map Firebase errors into typed Failures so the Bloc can surface
    // them uniformly regardless of whether the error came from a
    // one-off read or a live subscription.
    return remoteDataSource
        .watchProfile(uid)
        .handleError((Object error, StackTrace _) => throw mapAnyError(error));
  }

  @override
  Future<void> updateProfileFields(
    String uid,
    Map<String, dynamic> fields,
  ) async {
    try {
      await remoteDataSource.updateProfileFields(uid, fields);
    } catch (error) {
      throw mapAnyError(error);
    }
  }

  @override
  Future<void> saveMlRiskAnalysis(
    String uid, {
    required String category,
    required int confidencePercent,
    required String advice,
    required Map<String, double> probabilitiesPercent,
  }) async {
    try {
      await remoteDataSource.updateProfileFields(uid, {
        'lastMlRiskCategory': category,
        'lastMlRiskConfidence': confidencePercent,
        'lastMlRiskAdvice': advice,
        'lastMlRiskProbabilities': probabilitiesPercent,
        'lastMlRiskAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw mapAnyError(error);
    }
  }

  @override
  Future<String> uploadAvatar({
    required String uid,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {
    try {
      return await remoteDataSource.uploadAvatar(
        uid: uid,
        bytes: bytes,
        contentType: contentType,
      );
    } catch (error) {
      throw mapAnyError(error);
    }
  }
}
