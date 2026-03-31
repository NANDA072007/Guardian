// lib/models/daily_checkin.dart
// Was empty — now complete. Used by ChallengeScreen for daily habit tracking.
import 'dart:convert';

class DailyCheckIn {
  final int id;
  final DateTime date;           // normalized to local midnight
  final bool morningRoutineDone;
  final bool exerciseDone;
  final bool phoneOutOfRoom;     // phone kept out of bedroom at night
  final String journalEntry;
  final int moodScore;           // 1–10

  const DailyCheckIn({
    required this.id,
    required this.date,
    this.morningRoutineDone = false,
    this.exerciseDone = false,
    this.phoneOutOfRoom = false,
    this.journalEntry = '',
    this.moodScore = 5,
  });

  factory DailyCheckIn.forToday() => DailyCheckIn(
        id: 0,
        date: _midnight(DateTime.now()),
      );

  static DateTime _midnight(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  bool get isComplete =>
      morningRoutineDone && exerciseDone && phoneOutOfRoom;

  DailyCheckIn copyWith({
    int? id,
    DateTime? date,
    bool? morningRoutineDone,
    bool? exerciseDone,
    bool? phoneOutOfRoom,
    String? journalEntry,
    int? moodScore,
  }) {
    return DailyCheckIn(
      id: id ?? this.id,
      date: date ?? this.date,
      morningRoutineDone: morningRoutineDone ?? this.morningRoutineDone,
      exerciseDone: exerciseDone ?? this.exerciseDone,
      phoneOutOfRoom: phoneOutOfRoom ?? this.phoneOutOfRoom,
      journalEntry: journalEntry ?? this.journalEntry,
      moodScore: (moodScore ?? this.moodScore).clamp(1, 10),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.millisecondsSinceEpoch,
        'morningRoutineDone': morningRoutineDone,
        'exerciseDone': exerciseDone,
        'phoneOutOfRoom': phoneOutOfRoom,
        'journalEntry': journalEntry,
        'moodScore': moodScore,
      };

  factory DailyCheckIn.fromMap(Map<String, dynamic> map) => DailyCheckIn(
        id: (map['id'] as num?)?.toInt() ?? 0,
        date: DateTime.fromMillisecondsSinceEpoch(
            (map['date'] as num?)?.toInt() ?? 0),
        morningRoutineDone: map['morningRoutineDone'] as bool? ?? false,
        exerciseDone: map['exerciseDone'] as bool? ?? false,
        phoneOutOfRoom: map['phoneOutOfRoom'] as bool? ?? false,
        journalEntry: map['journalEntry'] as String? ?? '',
        moodScore: (map['moodScore'] as num?)?.toInt() ?? 5,
      );

  String toJson() => jsonEncode(toMap());

  factory DailyCheckIn.fromJson(String source) =>
      DailyCheckIn.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
