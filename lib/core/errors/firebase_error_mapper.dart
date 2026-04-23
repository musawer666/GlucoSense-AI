import 'package:firebase_auth/firebase_auth.dart';

import 'error_mapper.dart';
import 'failures.dart';

/// Converts any error thrown from the Firebase SDKs (or any
/// lower-level [AppException] / [DioException]) into a typed
/// [Failure] carrying a user-friendly message.
///
/// Repositories MUST call [mapAnyError] in their `catch` blocks so raw
/// SDK exceptions never leak into Bloc / UI layers.
///
/// Resolution order:
/// 1. Already-mapped [Failure]s pass through unchanged.
/// 2. Firebase Auth exceptions → user-friendly auth messages.
/// 3. Firestore / Storage exceptions → server / permission / not-found.
/// 4. Everything else is delegated to [mapErrorToFailure], which
///    handles [ServerException], [NetworkException], [CacheException]
///    and [DioException] from the core layer.
Failure mapAnyError(Object error) {
  if (error is Failure) return error;
  if (error is FirebaseAuthException) return _mapAuth(error);
  if (error is FirebaseException) return _mapFirebaseException(error);
  return mapErrorToFailure(error);
}

Failure _mapAuth(FirebaseAuthException e) {
  switch (e.code) {
    case 'email-already-in-use':
      return const AuthFailure('This email is already in use.');
    case 'invalid-email':
      return const AuthFailure('Please enter a valid email address.');
    case 'operation-not-allowed':
      return const AuthFailure('Sign-up is currently disabled. Try again later.');
    case 'weak-password':
      return const AuthFailure(
        'Password is too weak. Use at least 6 characters.',
      );
    case 'user-disabled':
      return const AuthFailure('This account has been disabled.');
    case 'user-not-found':
      return const NotFoundFailure('No account found with this email.');
    case 'wrong-password':
    case 'invalid-credential':
      return const AuthFailure('Incorrect email or password.');
    case 'too-many-requests':
      return const AuthFailure('Too many attempts. Please wait and try again.');
    case 'network-request-failed':
      return const NetworkFailure('Please check your internet connection.');
    default:
      return AuthFailure(e.message ?? 'Authentication failed. Please try again.');
  }
}

/// Handles both Firestore (`plugin: cloud_firestore`) and Firebase
/// Storage (`plugin: firebase_storage`) — they share the
/// [FirebaseException] hierarchy but ship different `code`s.
Failure _mapFirebaseException(FirebaseException e) {
  switch (e.code) {
    // Firestore
    case 'permission-denied':
      return const PermissionFailure('You do not have access to this resource.');
    case 'unavailable':
    case 'deadline-exceeded':
      return const NetworkFailure('Service temporarily unavailable.');
    case 'not-found':
      return const NotFoundFailure('Requested data was not found.');
    case 'already-exists':
      return const ServerFailure('This record already exists.');

    // Firebase Storage
    case 'unauthorized':
      return const PermissionFailure(
        'Upload blocked. Check Firebase Storage rules for avatars/{uid}.jpg.',
      );
    case 'unauthenticated':
      return const AuthFailure('Please sign in again to upload your photo.');
    case 'object-not-found':
      return const NotFoundFailure('The requested file was not found.');
    case 'quota-exceeded':
      return const ServerFailure(
        'Storage quota exceeded. Please contact support.',
      );
    case 'retry-limit-exceeded':
      return const NetworkFailure(
        'Upload timed out. Check your connection and try again.',
      );
    case 'canceled':
      return const ServerFailure('Upload was cancelled.');
    case 'invalid-argument':
      return const ServerFailure('Invalid image data.');

    default:
      return ServerFailure(e.message ?? 'Something went wrong on the server.');
  }
}
