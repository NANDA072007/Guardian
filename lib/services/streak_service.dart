// lib/services/streak_service.dart
// FIX: %20 import path + SharedPreferences persistence
// Old code created a fresh Day 1 streak on every cold start
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardian/%20models/streak_record.dart';
import 'package:guardian/core/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==================== PROVIDER ====================

final streakServiceProvider = Provider<StreakService>((ref) {
  return StreakService();
});

// ==================== SERVICE ====================

class StreakService {
  // Normalize DateTime to local midnight — RR-01: streaks in local timezone
  DateTime _normalize(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  int _daysBetween(DateTime a, DateTime b) {
    return _normalize(b).difference(_normalize(a)).inDays;
  }

  // ==================== PERSISTENCE ====================

  // FIX: Load from SharedPreferences on app start so streak survives restarts.
  // Old code called createInitial() every build() → always Day 1 after restart.
  Future<StreakRecord> loadOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final startMs = prefs.getInt(GuardianConstants.streakStartDateKey);
    final totalDays = prefs.getInt(GuardianConstants.streakTotalDaysKey);

    if (startMs == null || totalDays == null) {
      final fresh = createInitial();
      await save(fresh);
      return fresh;
    }

    return StreakRecord(
      id: 1,
      startDate: DateTime.fromMillisecondsSinceEpoch(startMs),
      endDate: null,
      totalDays: totalDays,
      relapseReason: null,
    );
  }

  Future<void> save(StreakRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      GuardianConstants.streakStartDateKey,
      record.startDate.millisecondsSinceEpoch,
    );
    await prefs.setInt(
      GuardianConstants.streakTotalDaysKey,
      record.totalDays,
    );
  }

  // ==================== STREAK LOGIC ====================

  StreakRecord createInitial() {
    return StreakRecord(
      id: 1,
      startDate: _normalize(DateTime.now()),
      endDate: null,
      totalDays: 1,
      relapseReason: null,
    );
  }

  StreakRecord updateDaily(StreakRecord current) {
    if (!current.isActive) {
      throw const StreakServiceFailure('Streak is not active');
    }

    final today = _normalize(DateTime.now());
    final lastRecordedDay = _normalize(
      current.startDate.add(Duration(days: current.totalDays - 1)),
    );

    final diff = _daysBetween(lastRecordedDay, today);

    if (diff == 0) return current;        // Same day — no change
    if (diff > 0) {                       // One or more new days passed — add them
      return current.copyWith(totalDays: current.totalDays + diff);
    }
    if (diff < 0) return current;         // Clock rollback — ignore

    return current;
  }

  // Only called by explicit user action (pressing "I relapsed")
  // A block attempt NEVER resets the streak — seeing the overlay = system working
  StreakRecord reset({
    required StreakRecord current,
    String? reason,
  }) {
    if (!current.isActive) {
      throw const StreakServiceFailure('Streak already ended');
    }
    return current.copyWith(
      endDate: _normalize(DateTime.now()),
      relapseReason: reason,
    );
  }
}

// ==================== EXCEPTIONS ====================

sealed class StreakServiceException implements Exception {
  final String message;
  const StreakServiceException(this.message);
}

class StreakServiceFailure extends StreakServiceException {
  const StreakServiceFailure(super.message);
}
