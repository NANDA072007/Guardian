// lib/providers/streak_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardian/%20models/streak_record.dart';
import 'package:guardian/services/streak_service.dart';

final streakProvider =
    AsyncNotifierProvider<StreakNotifier, StreakRecord?>(() {
  return StreakNotifier();
});

class StreakNotifier extends AsyncNotifier<StreakRecord?> {
  late final StreakService _service;

  @override
  Future<StreakRecord?> build() async {
    _service = ref.read(streakServiceProvider);
    final loaded = await _service.loadOrCreate();
    final updated = _service.updateDaily(loaded);
    if (updated.totalDays != loaded.totalDays) {
      await _service.save(updated);
    }
    return updated;
  }

  Future<void> refresh() async {
    final current = state.value;
    if (current == null) {
      state = AsyncData(await _service.loadOrCreate());
      return;
    }
    try {
      final updated = _service.updateDaily(current);
      if (updated.totalDays != current.totalDays) {
        await _service.save(updated);
      }
      state = AsyncData(updated);
    } catch (e, st) {
      state = AsyncError(StreakProviderFailure('Refresh failed: $e'), st);
    }
  }

  // Only called by explicit "I relapsed" — NEVER by block detection
  Future<void> reset(String? reason) async {
    final current = state.value;
    if (current == null) return;
    try {
      // FIX: 'ended' was assigned but never used — use result directly to save
      _service.reset(current: current, reason: reason);
      // Start fresh streak immediately after relapse
      final fresh = _service.createInitial();
      await _service.save(fresh);
      state = AsyncData(fresh);
    } catch (e, st) {
      state = AsyncError(StreakProviderFailure('Reset failed: $e'), st);
    }
  }
}

sealed class StreakProviderException implements Exception {
  final String message;
  const StreakProviderException(this.message);
}

class StreakProviderFailure extends StreakProviderException {
  const StreakProviderFailure(super.message);
}
