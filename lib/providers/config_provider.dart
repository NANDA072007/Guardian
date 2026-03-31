// lib/providers/config_provider.dart
// FIX: %20 import path corrected
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardian/%20models/guardian_config.dart';
import 'package:guardian/core/secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ==================== STORAGE PROVIDER ====================

final secureStorageProvider = Provider<GuardianSecureStorage>((ref) {
  return GuardianSecureStorage(const FlutterSecureStorage());
});

// ==================== STATE ====================

sealed class ConfigState {}

class ConfigLoading extends ConfigState {}

class ConfigReady extends ConfigState {
  final GuardianConfig config;
  ConfigReady(this.config);
}

class ConfigOnboarding extends ConfigState {}

class ConfigError extends ConfigState {
  final String message;
  ConfigError(this.message);
}

// ==================== PROVIDER ====================

final configProvider = AsyncNotifierProvider<ConfigController, ConfigState>(
  ConfigController.new,
);

class ConfigController extends AsyncNotifier<ConfigState> {
  late final GuardianSecureStorage _storage;

  @override
  Future<ConfigState> build() async {
    _storage = ref.read(secureStorageProvider);
    try {
      final config = await _storage.getConfig();
      if (!config.isConfigured) return ConfigOnboarding();
      return ConfigReady(config);
    } catch (e) {
      return ConfigError(e.toString());
    }
  }

  GuardianConfig? get currentConfig {
    final s = state.value;
    return s is ConfigReady ? s.config : null;
  }

  // Called at the final onboarding step (PasswordHandoffScreen)
  // This is the ONLY place isConfigured is set to true
  Future<void> completeSetup({
    required String accountabilityName,
    required String accountabilityPhone,
  }) async {
    final currentState = state.value;
    if (currentState is! ConfigReady) {
      throw Exception('Config not ready — cannot complete setup');
    }

    final updated = currentState.config.copyWith(
      accountabilityName: accountabilityName,
      accountabilityPhone: accountabilityPhone,
      isConfigured: true,
    );

    await _storage.saveConfig(updated);
    state = AsyncData(ConfigReady(updated));
  }

  // Refresh config from secure storage (e.g. after settings change)
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final config = await _storage.getConfig();
      if (!config.isConfigured) return ConfigOnboarding();
      return ConfigReady(config);
    });
  }
}
