// lib/models/block_attempt.dart — unchanged from original, already correct
import 'dart:convert';

class BlockAttempt {
  final int id;
  final DateTime timestamp;
  final String detectedUrl;
  final String detectionLayer;
  final bool userOverrode;

  const BlockAttempt({
    required this.id,
    required this.timestamp,
    required this.detectedUrl,
    required this.detectionLayer,
    required this.userOverrode,
  });

  factory BlockAttempt.fromMap(Map<String, dynamic>? map) {
    if (map == null) throw const BlockAttemptParseException('Null map');
    try {
      return BlockAttempt(
        id: (map['id'] as num?)?.toInt() ?? 0,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            (map['timestamp'] as num?)?.toInt() ?? 0),
        detectedUrl: (map['detectedUrl'] as String?)?.isNotEmpty == true
            ? map['detectedUrl'] as String
            : 'unknown',
        detectionLayer:
            (map['detectionLayer'] as String?)?.isNotEmpty == true
                ? map['detectionLayer'] as String
                : 'unknown',
        userOverrode: map['userOverrode'] as bool? ?? false,
      );
    } catch (e) {
      throw BlockAttemptParseException(e.toString());
    }
  }

  factory BlockAttempt.fromJson(String source) {
    if (source.isEmpty) throw const BlockAttemptParseException('Empty JSON');
    return BlockAttempt.fromMap(jsonDecode(source) as Map<String, dynamic>?);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'detectedUrl': detectedUrl,
        'detectionLayer': detectionLayer,
        'userOverrode': userOverrode,
      };

  String toJson() => jsonEncode(toMap());

  BlockAttempt copyWith({
    int? id,
    DateTime? timestamp,
    String? detectedUrl,
    String? detectionLayer,
    bool? userOverrode,
  }) {
    return BlockAttempt(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      detectedUrl: detectedUrl ?? this.detectedUrl,
      detectionLayer: detectionLayer ?? this.detectionLayer,
      userOverrode: userOverrode ?? this.userOverrode,
    );
  }
}

sealed class BlockAttemptException implements Exception {
  final String message;
  const BlockAttemptException(this.message);
}

class BlockAttemptParseException extends BlockAttemptException {
  const BlockAttemptParseException(super.message);
}

class BlockAttemptEmptyException extends BlockAttemptException {
  const BlockAttemptEmptyException(super.message);
}
