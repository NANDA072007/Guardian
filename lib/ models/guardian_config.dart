// lib/models/guardian_config.dart
// FIX applied: All 7 fields present (was missing 4 in original)
import 'dart:convert';

class GuardianConfig {
  final String passwordHash;
  final DateTime setupDate;
  final bool isConfigured;
  final String? accountabilityName;
  final String? accountabilityPhone;
  final bool deviceAdminActive;
  final bool vpnActive;
  final bool accessibilityActive;

  const GuardianConfig({
    required this.passwordHash,
    required this.setupDate,
    required this.isConfigured,
    this.accountabilityName,
    this.accountabilityPhone,
    this.deviceAdminActive = false,
    this.vpnActive = false,
    this.accessibilityActive = false,
  });

  factory GuardianConfig.initial() => GuardianConfig(
        passwordHash: '',
        setupDate: DateTime.fromMillisecondsSinceEpoch(0),
        isConfigured: false,
      );

  GuardianConfig copyWith({
    String? passwordHash,
    DateTime? setupDate,
    bool? isConfigured,
    String? accountabilityName,
    String? accountabilityPhone,
    bool? deviceAdminActive,
    bool? vpnActive,
    bool? accessibilityActive,
  }) {
    return GuardianConfig(
      passwordHash: passwordHash ?? this.passwordHash,
      setupDate: setupDate ?? this.setupDate,
      isConfigured: isConfigured ?? this.isConfigured,
      accountabilityName: accountabilityName ?? this.accountabilityName,
      accountabilityPhone: accountabilityPhone ?? this.accountabilityPhone,
      deviceAdminActive: deviceAdminActive ?? this.deviceAdminActive,
      vpnActive: vpnActive ?? this.vpnActive,
      accessibilityActive: accessibilityActive ?? this.accessibilityActive,
    );
  }

  Map<String, dynamic> toMap() => {
        'passwordHash': passwordHash,
        'setupDate': setupDate.toIso8601String(),
        'isConfigured': isConfigured,
        'accountabilityName': accountabilityName,
        'accountabilityPhone': accountabilityPhone,
        'deviceAdminActive': deviceAdminActive,
        'vpnActive': vpnActive,
        'accessibilityActive': accessibilityActive,
      };

  factory GuardianConfig.fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) return GuardianConfig.initial();
    return GuardianConfig(
      passwordHash: map['passwordHash'] as String? ?? '',
      setupDate: DateTime.tryParse(map['setupDate'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isConfigured: map['isConfigured'] as bool? ?? false,
      accountabilityName: map['accountabilityName'] as String?,
      accountabilityPhone: map['accountabilityPhone'] as String?,
      deviceAdminActive: map['deviceAdminActive'] as bool? ?? false,
      vpnActive: map['vpnActive'] as bool? ?? false,
      accessibilityActive: map['accessibilityActive'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory GuardianConfig.fromJson(String source) {
    try {
      return GuardianConfig.fromMap(jsonDecode(source) as Map<String, dynamic>);
    } catch (_) {
      return GuardianConfig.initial();
    }
  }
}
