/// Base exception for all ReliefNet application errors.
/// Services throw typed [AppException] subclasses; Providers catch them
/// and expose them as human-readable messages via the [error] state field.
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() =>
      'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Thrown when a network/connectivity issue prevents a service call.
class NetworkException extends AppException {
  const NetworkException([String message = 'No internet connection.'])
      : super(message, code: 'network_error');
}

/// Thrown when user input fails validation (NIC format, family size, etc.).
class ValidationException extends AppException {
  const ValidationException(String message)
      : super(message, code: 'validation_error');
}

/// Thrown when an authentication operation fails.
class AuthException extends AppException {
  const AuthException([String message = 'Authentication failed.'])
      : super(message, code: 'auth_error');
}

/// Thrown when the app lacks a required device permission
/// (location, camera, notifications).
class PermissionException extends AppException {
  const PermissionException(String permission)
      : super('Permission denied: $permission', code: 'permission_denied');
}

/// Thrown when a Firestore Transaction cannot reserve enough parcels
/// for a victim's request (race condition — another volunteer got there first).
class NotEnoughParcelsException extends AppException {
  const NotEnoughParcelsException([
    String message = 'Not enough parcels available at this center. Please try another center.',
  ]) : super(message, code: 'not_enough_parcels');
}

/// Thrown when a victim tries to submit a second request while one is active.
class ActiveRequestExistsException extends AppException {
  const ActiveRequestExistsException()
      : super(
          'You already have an active relief request. '
          'Please wait for it to complete before submitting a new one.',
          code: 'active_request_exists',
        );
}

/// Thrown when a center doesn't have enough inventory stock to pack the
/// requested number of parcels according to the current blueprint.
/// [Added in Phase 2] — MockParcelService.packParcels never actually
/// checked inventory (it just fabricated new parcel docs unconditionally),
/// despite the ParcelService interface's own doc comment saying packing
/// should happen "after verifying sufficient inventory". FirebaseParcelService
/// is the first implementation that actually enforces this.
class InsufficientInventoryException extends AppException {
  const InsufficientInventoryException(String message)
      : super(message, code: 'insufficient_inventory');
}

/// Thrown when the requested document does not exist in Firestore.
class NotFoundException extends AppException {
  const NotFoundException([String message = 'The requested record was not found.'])
      : super(message, code: 'not_found');
}