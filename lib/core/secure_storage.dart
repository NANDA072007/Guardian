// lib/core/secure_storage.dart
// FIX: Import was 'package:guardian/%20models/guardian_config.dart'
// %20 is URL-encoded space — folder is lib/models/ with no space
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guardian/%20models/guardian_config.dart';
import 'constants.dart';

sealed class SecureStorageException implements Exception {
  final String message;
  const SecureStorageException(this.message);
}

class StorageWriteException extends SecureStorageException {
  const StorageWriteException() : super('Failed to write to secure storage');
}

class StorageReadException extends SecureStorageException {
  const StorageReadException() : super('Failed to read from secure storage');
}

class GuardianSecureStorage {
  static const _key = GuardianConstants.configStorageKey;

  final FlutterSecureStorage _storage;

  GuardianSecureStorage(this._storage);

  Future<void> saveConfig(GuardianConfig config) async {
    try {
      await _storage.write(key: _key, value: config.toJson());
    } catch (_) {
      throw const StorageWriteException();
    }
  }

  Future<GuardianConfig> getConfig() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return GuardianConfig.initial();
      return GuardianConfig.fromJson(raw);
    } catch (_) {
      throw const StorageReadException();
    }
  }

  Future<bool> isConfigured() async {
    final config = await getConfig();
    return config.isConfigured && config.passwordHash.isNotEmpty;
  }

  Future<String?> getPasswordHash() async {
    final config = await getConfig();
    return config.passwordHash.isEmpty ? null : config.passwordHash;
  }
}
