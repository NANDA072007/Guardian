// lib/models/guardian_config.dart
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
  final String protectionMode; // "normal" or "strict"

  const GuardianConfig({
    required this.passwordHash,
    required this.setupDate,
    required this.isConfigured,
    this.accountabilityName,
    this.accountabilityPhone,
    this.deviceAdminActive = false,
    this.vpnActive = false,
    this.accessibilityActive = false,
    required this.protectionMode,
  });

  factory GuardianConfig.initial() => GuardianConfig(
    passwordHash: '',
    setupDate: DateTime.fromMillisecondsSinceEpoch(0),
    isConfigured: false,
    protectionMode: 'normal', // ✅ FIX
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
    String? protectionMode, // ✅ FIX
  }) {
    return GuardianConfig(
      passwordHash: passwordHash ?? this.passwordHash,
      setupDate: setupDate ?? this.setupDate,
      isConfigured: isConfigured ?? this.isConfigured,
      accountabilityName: accountabilityName ?? this.accountabilityName,
      accountabilityPhone: accountabilityPhone ?? this.accountabilityPhone,
      deviceAdminActive: deviceAdminActive ?? this.deviceAdminActive,
      vpnActive: vpnActive ?? this.vpnActive,
      accessibilityActive:
      accessibilityActive ?? this.accessibilityActive,
      protectionMode: protectionMode ?? this.protectionMode, // ✅ FIX
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
    'protectionMode': protectionMode, // ✅ FIX
  };

  factory GuardianConfig.fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) return GuardianConfig.initial();

    return GuardianConfig(
      passwordHash: map['passwordHash'] ?? '',
      setupDate: DateTime.tryParse(map['setupDate'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isConfigured: map['isConfigured'] ?? false,
      accountabilityName: map['accountabilityName'],
      accountabilityPhone: map['accountabilityPhone'],
      deviceAdminActive: map['deviceAdminActive'] ?? false,
      vpnActive: map['vpnActive'] ?? false,
      accessibilityActive: map['accessibilityActive'] ?? false,
      protectionMode: map['protectionMode'] ?? 'normal', // ✅ FIX
    );
  }

  String toJson() => jsonEncode(toMap());

  factory GuardianConfig.fromJson(String source) {
    try {
      return GuardianConfig.fromMap(jsonDecode(source));
    } catch (_) {
      return GuardianConfig.initial();
    }
  }
}