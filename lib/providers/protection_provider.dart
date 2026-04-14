// lib/providers/protection_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardian/providers/config_provider.dart';
import 'package:guardian/services/protection_service.dart' ;

final protectionProvider =
    AsyncNotifierProvider<ProtectionNotifier, ProtectionStatus>(
  ProtectionNotifier.new,
);

class ProtectionNotifier extends AsyncNotifier<ProtectionStatus> {
  late final ProtectionService _service;

  @override
  Future<ProtectionStatus> build() async {
    // FIX: Use protectionServiceProvider consistently throughout
    // Old code used ref.read(protectionServiceProvider) in startVpn()
    // but _service instance in all other methods — inconsistent
    _service = ref.read(protectionServiceProvider);
    return _service.fetchStatus();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.fetchStatus());
  }

  Future<bool> startVpn() async {
    try {
      final config = ref.read(configProvider).value;

      if (config is ConfigReady &&
          config.config.protectionMode == "strict") {
        final started = await _service.startVpn();
        await refresh();
        return started;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopVpn(String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _service.stopVpn(password);
      return _service.fetchStatus();
    });
  }

  Future<void> activateAdmin() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _service.activateDeviceAdmin();
      return _service.fetchStatus();
    });
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await _service.openAccessibilitySettings();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> openVpnSettings() async {
    try {
      await _service.openVpnSettings();
    } catch (_) {
      rethrow;
    }
  }
}
