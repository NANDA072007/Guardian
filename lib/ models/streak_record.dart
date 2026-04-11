// lib/models/streak_record.dart — unchanged from original, already correct
import 'package:flutter/foundation.dart';

@immutable
class StreakRecord {
  final int id;
  final DateTime startDate;
  final DateTime? endDate;
  final int totalDays;
  final String? relapseReason;

  const StreakRecord({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.relapseReason,
  });

  bool get isActive => endDate == null;

  StreakRecord copyWith({
    int? id,
    DateTime? startDate,
    DateTime? endDate,
    int? totalDays,
    String? relapseReason,
  }) {
    return StreakRecord(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDays: totalDays ?? this.totalDays,
      relapseReason: relapseReason ?? this.relapseReason,
    );
  }

  factory StreakRecord.fromMap(Map<String, dynamic> map) {
    try {
      return StreakRecord(
        id: map['id'] as int,
        startDate:
            DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int),
        endDate: map['endDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int)
            : null,
        totalDays: map['totalDays'] as int,
        relapseReason: map['relapseReason'] as String?,
      );
    } catch (e) {
      throw StreakModelException('Invalid StreakRecord map: $e');
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate?.millisecondsSinceEpoch,
        'totalDays': totalDays,
        'relapseReason': relapseReason,
      };
}

class StreakModelException implements Exception {
  final String message;
  const StreakModelException(this.message);
}

class StreakParsingException extends StreakModelException {
  const StreakParsingException(super.message);
}
