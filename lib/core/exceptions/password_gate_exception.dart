// lib/core/exceptions/password_gate_exception.dart — unchanged, correct
sealed class PasswordGateException implements Exception {
  const PasswordGateException();

  const factory PasswordGateException.invalid() = InvalidPasswordException;
  const factory PasswordGateException.empty()   = EmptyPasswordException;
}

class InvalidPasswordException extends PasswordGateException {
  const InvalidPasswordException();
}

class EmptyPasswordException extends PasswordGateException {
  const EmptyPasswordException();
}
