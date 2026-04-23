/// User-facing or Bloc-layer error models (immutable, simple).
sealed class Failure {
  const Failure(this.message);

  final String message;
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong. Please try again.']);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});

  final int? statusCode;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Raised for authentication-specific problems (invalid credentials,
/// email already in use, weak password, disabled account, etc.).
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// The user is authenticated but does not have access to the resource.
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

/// The requested document or resource does not exist.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}
