import 'app_exception.dart';

/// A value-type representation of an error, safe to expose directly
/// in Provider state fields. Unlike [AppException], [Failure] is never thrown.
///
/// Usage in Providers:
/// ```dart
/// Failure? _failure;
/// Failure? get failure => _failure;
///
/// try {
///   await _service.doSomething();
/// } on AppException catch (e) {
///   _failure = Failure.fromException(e);
/// } catch (e) {
///   _failure = Failure.unexpected(detail: e.toString());
/// }
/// notifyListeners();
/// ```
class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  factory Failure.fromException(AppException e) =>
      Failure(e.message, code: e.code);

  factory Failure.unexpected({String? detail}) => Failure(
        detail != null
            ? 'An unexpected error occurred: $detail'
            : 'An unexpected error occurred. Please try again.',
        code: 'unexpected',
      );

  @override
  String toString() => 'Failure($message)';

  @override
  bool operator ==(Object other) =>
      other is Failure && other.message == message && other.code == code;

  @override
  int get hashCode => Object.hash(message, code);
}