// lib/core/password_hasher.dart — unchanged from original, already correct
import 'dart:convert';
import 'package:crypto/crypto.dart';

sealed class PasswordHashException implements Exception {
  final String message;
  const PasswordHashException(this.message);
}

class EmptyPasswordException extends PasswordHashException {
  const EmptyPasswordException() : super('Password cannot be empty');
}

class WeakPasswordException extends PasswordHashException {
  const WeakPasswordException() : super('Password must be at least 6 characters');
}

class PasswordHasher {
  static const int _minLength = 6;

  static String hash(String password) {
    if (password.isEmpty) throw const EmptyPasswordException();
    if (password.length < _minLength) throw const WeakPasswordException();

    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verify({
    required String inputPassword,
    required String storedHash,
  }) {
    if (inputPassword.isEmpty || storedHash.isEmpty) return false;
    final inputHash = hash(inputPassword);
    return inputHash == storedHash;
  }
}
