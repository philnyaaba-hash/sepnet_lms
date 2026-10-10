/// Base class for all errors that the app surfaces to the UI.
///
/// Using a single hierarchy lets controllers map failures to friendly,
/// beginner-appropriate messages without leaking stack traces or, worse,
/// credentials into the UI or logs.
sealed class AppException implements Exception {
  const AppException(this.userMessage, {this.cause});

  /// Safe, human readable message shown to the learner.
  final String userMessage;

  /// Original error, kept for diagnostics. Never displayed verbatim.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $userMessage';
}

/// The device appears to be offline and the operation required the network.
class OfflineException extends AppException {
  const OfflineException([super.userMessage = "You're offline. Your work is saved and will sync later."]);
}

/// A network request failed or timed out.
class NetworkException extends AppException {
  const NetworkException(super.userMessage, {super.cause});
}

/// The LMS rejected our credentials / the session has expired.
class AuthenticationException extends AppException {
  const AuthenticationException([super.userMessage = 'Your session has expired. Please sign in again.']);
}

/// The LMS returned an error we could not classify.
class LmsException extends AppException {
  const LmsException(super.userMessage, {this.statusCode, super.cause});

  final int? statusCode;
}

/// The requested exercise / submission does not exist.
class NotFoundException extends AppException {
  const NotFoundException([super.userMessage = 'We could not find that item.']);
}

/// Local persistence failed.
class StorageException extends AppException {
  const StorageException(super.userMessage, {super.cause});
}

/// Python execution failed at the infrastructure level (not a learner error).
class RuntimeException extends AppException {
  const RuntimeException(super.userMessage, {super.cause});
}
