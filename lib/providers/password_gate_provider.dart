// lib/providers/password_gate_provider.dart
// No changes — already correct
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardian/services/protection_service.dart';
import 'package:guardian/core/exceptions/password_gate_exception.dart';

final passwordGateProvider =
    AsyncNotifierProvider<PasswordGateNotifier, bool>(
  PasswordGateNotifier.new,
);

class PasswordGateNotifier extends AsyncNotifier<bool> {
  late final ProtectionService _service;

  @override
  Future<bool> build() async {
    _service = ref.read(protectionServiceProvider);
    return false; // locked by default
  }

  Future<void> verify(String password) async {
    if (password.isEmpty) {
      state = AsyncError(const PasswordGateException.empty(), StackTrace.current);
      return;
    }

    state = const AsyncLoading();

    try {
      final isValid = await _service.verifyPassword(password);
      if (!isValid) throw const PasswordGateException.invalid();
      state = const AsyncData(true);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  void reset() => state = const AsyncData(false);
}
