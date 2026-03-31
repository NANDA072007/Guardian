// lib/services/protection_service.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardian/core/constants.dart';
import 'package:guardian/core/secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ==================== EXCEPTIONS ====================

 class ProtectionException implements Exception {
  final String message;
  const ProtectionException(this.message);
}

class ProtectionUnavailableException extends ProtectionException {
  const ProtectionUnavailableException(super.message);
}

class ProtectionPermissionDeniedException extends ProtectionException {
  const ProtectionPermissionDeniedException(super.message);
}

class ProtectionPasswordInvalidException extends ProtectionException {
  const ProtectionPasswordInvalidException(super.message);
}

class ProtectionVpnStartFailedException extends ProtectionException {
  const ProtectionVpnStartFailedException(super.message);
}

class ProtectionUnknownException extends ProtectionException {
  const ProtectionUnknownException(super.message);
}

// ==================== MODEL ====================

class ProtectionStatus {
  final bool vpnEnabled;
  final bool adminEnabled;
  final bool accessibilityEnabled;
  final int blockCount;

  const ProtectionStatus({
    required this.vpnEnabled,
    required this.adminEnabled,
    required this.accessibilityEnabled,
    this.blockCount = 0,
  });

  bool get isFullyProtected => vpnEnabled && adminEnabled && accessibilityEnabled;

  ProtectionStatus copyWith({
    bool? vpnEnabled,
    bool? adminEnabled,
    bool? accessibilityEnabled,
    int? blockCount,
  }) {
    return ProtectionStatus(
      vpnEnabled: vpnEnabled ?? this.vpnEnabled,
      adminEnabled: adminEnabled ?? this.adminEnabled,
      accessibilityEnabled: accessibilityEnabled ?? this.accessibilityEnabled,
      blockCount: blockCount ?? this.blockCount,
    );
  }
}

// ==================== PROVIDER ====================

final protectionServiceProvider = Provider<ProtectionService>((ref) {
  final storage = GuardianSecureStorage(const FlutterSecureStorage());
  return ProtectionService(storage);
});

// ==================== SERVICE ====================

class ProtectionService {
  static const _channel = MethodChannel(GuardianConstants.channelName);
  final GuardianSecureStorage _secureStorage;

  ProtectionService(this._secureStorage);

  // ==================== STATUS ====================

  Future<ProtectionStatus> fetchStatus() async {
    try {
      final results = await Future.wait([
        _safeBoolCall(GuardianConstants.methodIsVpnRunning),
        _safeBoolCall(GuardianConstants.methodIsDeviceAdminActive),
        _safeBoolCall(GuardianConstants.methodIsAccessibilityEnabled),
      ]);

      final count = await _safeGetBlockCount();

      return ProtectionStatus(
        vpnEnabled: results[0],
        adminEnabled: results[1],
        accessibilityEnabled: results[2],
        blockCount: count,
      );
    } catch (e) {
      throw ProtectionUnknownException('Failed to fetch status: $e');
    }
  }

  Future<int> _safeGetBlockCount() async {
    try {
      final result = await _channel.invokeMethod<int>(
        GuardianConstants.methodGetBlockAttemptCount,
      );
      return result ?? 0;
    } catch (_) {
      return 0;
    }
  }
  Future<int> getBlockAttemptCount() async {
    try {
      final result = await _channel.invokeMethod<int>(
        GuardianConstants.methodGetBlockAttemptCount,
      );
      return result ?? 0;
    } catch (e) {
      throw ProtectionException('Failed to get block count: $e');
    }
  }

  // ==================== VPN ====================

  /// Returns true = VPN started, false = permission dialog shown (poll for result)
  Future<bool> startVpn() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        GuardianConstants.methodStartVpn,
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _mapAndThrow(e);
    }
  }

  /// Password verified on Dart side before calling Kotlin
  Future<void> stopVpn(String password) async {
    if (password.isEmpty) {
      throw const ProtectionPasswordInvalidException('Password cannot be empty');
    }
    final verified = await verifyPassword(password);
    if (!verified) {
      throw const ProtectionPasswordInvalidException('Incorrect password');
    }
    try {
      await _channel.invokeMethod(GuardianConstants.methodStopVpn);
    } on PlatformException catch (e) {
      _mapAndThrow(e);
    }
  }

  // ==================== DEVICE ADMIN ====================

  Future<void> activateDeviceAdmin() async {
    await _invokeVoid(GuardianConstants.methodActivateDeviceAdmin);
  }

  // ==================== SETTINGS NAVIGATION ====================

  Future<void> openAccessibilitySettings() async {
    await _invokeVoid(GuardianConstants.methodOpenAccessibilitySettings);
  }

  Future<void> openVpnSettings() async {
    await _invokeVoid(GuardianConstants.methodOpenVpnSettings);
  }

  // ==================== PASSWORD ====================

  // FIX: Old code read password hash from SharedPreferences via Kotlin.
  // flutter_secure_storage uses EncryptedSharedPreferences — Kotlin reads
  // encrypted keys and always gets null. Now we read on Dart side (where
  // the decryption context is available) and pass the hash to Kotlin for
  // the SHA-256 comparison.
  Future<bool> verifyPassword(String password) async {
    if (password.isEmpty) {
      throw const ProtectionPasswordInvalidException('Password cannot be empty');
    }

    final storedHash = await _secureStorage.getPasswordHash();
    if (storedHash == null || storedHash.isEmpty) {
      throw const ProtectionPasswordInvalidException('No password configured');
    }

    try {
      final result = await _channel.invokeMethod<bool>(
        GuardianConstants.methodVerifyPassword,
        {'password': password, 'storedHash': storedHash},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _mapAndThrow(e);
    }
  }

  // ==================== SECURITY ====================

  Future<void> setWindowSecure(bool secure) async {
    try {
      await _channel.invokeMethod(
        GuardianConstants.methodSetWindowSecure,
        {'secure': secure},
      );
    } catch (_) {
      // Non-critical — continue even if this fails
    }
  }

  // ==================== EMERGENCY ====================

  Future<void> callNumber(String phone) async {
    if (phone.isEmpty) return;
    try {
      await _channel.invokeMethod(
        GuardianConstants.methodCallNumber,
        {'phone': phone},
      );
    } on PlatformException catch (e) {
      throw ProtectionUnknownException(e.message ?? 'Call failed');
    }
  }

  Future<void> smsNumber(String phone, {String? message}) async {
    if (phone.isEmpty) return;
    try {
      await _channel.invokeMethod(
        GuardianConstants.methodSmsNumber,
        {
          'phone': phone,
          'message': message ?? "I need support right now. Please reach out.",
        },
      );
    } on PlatformException catch (e) {
      throw ProtectionUnknownException(e.message ?? 'SMS failed');
    }
  }

  Future<void> requestScreenCapture() async {
    await _invokeVoid(GuardianConstants.methodRequestScreenCapture);
  }

  // ==================== INTERNAL ====================

  Future<void> _invokeVoid(String method) async {
    try {
      await _channel.invokeMethod(method);
    } on PlatformException catch (e) {
      _mapAndThrow(e);
    }
  }

  Future<bool> _safeBoolCall(String method) async {
    try {
      final result = await _channel.invokeMethod<bool>(method);
      if (result == null) {
        throw ProtectionUnknownException('$method returned null');
      }
      return result;
    } on PlatformException catch (e) {
      _mapAndThrow(e);
    }
  }

  Never _mapAndThrow(PlatformException e) {
    switch (e.code) {
      case 'UNAVAILABLE':
        throw ProtectionUnavailableException(e.message ?? '');
      case 'PERMISSION_DENIED':
        throw ProtectionPermissionDeniedException(e.message ?? '');
      case 'AUTH_FAILED':
      case 'INVALID_PASSWORD':
        throw ProtectionPasswordInvalidException(e.message ?? '');
      case 'VPN_START_FAILED':
        throw ProtectionVpnStartFailedException(e.message ?? '');
      default:
        throw ProtectionUnknownException(e.message ?? '');
    }
  }
}