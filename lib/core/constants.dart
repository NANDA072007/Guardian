// lib/core/constants.dart
// Central constants — import this everywhere instead of repeating strings

class GuardianConstants {
  // Platform channel
  static const String channelName = 'guardian/protection';

  // Secure storage key
  static const String configStorageKey = 'guardian_config';

  // SharedPreferences keys for streak persistence
  static const String streakStartDateKey = 'streak_start_date_ms';
  static const String streakTotalDaysKey  = 'streak_total_days';

  // GoRouter routes
  static const String routeSplash                     = '/splash';
  static const String routeDashboard                  = '/dashboard';
  static const String routeEmergency                  = '/emergency';
  static const String routeSettings                   = '/settings';
  static const String routeAnalytics                  = '/analytics';
  static const String routeChallenge                  = '/challenge';
  static const String routeBlockOverlay               = '/block-overlay';
  static const String routeOnboarding                 = '/onboarding';
  static const String routeSetPassword                = '/onboarding/set-password';
  static const String routeActivateAdmin              = '/onboarding/activate-admin';
  static const String routeEnableVpn                  = '/onboarding/enable-vpn';
  static const String routeEnableAccessibility        = '/onboarding/enable-accessibility';
  static const String routePasswordHandoff            = '/onboarding/password-handoff';

  // Platform channel methods
  static const String methodVerifyPassword            = 'verifyPassword';
  static const String methodActivateDeviceAdmin       = 'activateDeviceAdmin';
  static const String methodIsDeviceAdminActive       = 'isDeviceAdminActive';
  static const String methodStartVpn                  = 'startVpn';
  static const String methodStopVpn                   = 'stopVpn';
  static const String methodIsVpnRunning              = 'isVpnRunning';
  static const String methodOpenVpnSettings           = 'openVpnSettings';
  static const String methodIsAccessibilityEnabled    = 'isAccessibilityEnabled';
  static const String methodOpenAccessibilitySettings = 'openAccessibilitySettings';
  static const String methodGetBlockAttemptCount      = 'getBlockAttemptCount';
  static const String methodSetWindowSecure           = 'setWindowSecure';
  static const String methodCallNumber                = 'callNumber';
  static const String methodSmsNumber                 = 'smsNumber';
  static const String methodRequestScreenCapture      = 'requestScreenCapture';
}
