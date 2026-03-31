// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:guardian/core/constants.dart';
import 'package:guardian/screens/splash_screen.dart';
import 'package:guardian/screens/dashboard_screen.dart';
import 'package:guardian/screens/emergency_screen.dart';
import 'package:guardian/screens/settings_screen.dart';
import 'package:guardian/screens/analytics_screen.dart';
import 'package:guardian/screens/challenge_screen.dart';
import 'package:guardian/screens/block_overlay_screen.dart';
import 'package:guardian/screens/onboarding/welcome_screen.dart';
import 'package:guardian/screens/onboarding/set_password_screen.dart';
import 'package:guardian/screens/onboarding/activate_admin_screen.dart';
import 'package:guardian/screens/onboarding/enable_vpn_screen.dart';
import 'package:guardian/screens/onboarding/enable_accessibility_screen.dart';
import 'package:guardian/screens/onboarding/password_handoff_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: GuardianConstants.routeSplash,
    routes: [
      // ==================== CORE ====================
      GoRoute(
        path: GuardianConstants.routeSplash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: GuardianConstants.routeDashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: GuardianConstants.routeEmergency,
        builder: (context, state) => const EmergencyScreen(),
      ),
      GoRoute(
        path: GuardianConstants.routeSettings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: GuardianConstants.routeAnalytics,
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: GuardianConstants.routeChallenge,
        builder: (context, state) => const ChallengeScreen(),
      ),

      // ==================== BLOCK OVERLAY ====================
      GoRoute(
        path: GuardianConstants.routeBlockOverlay,
        builder: (context, state) => const BlockOverlayScreen(),
      ),

      // ==================== ONBOARDING ====================
      GoRoute(
        path: GuardianConstants.routeOnboarding,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: GuardianConstants.routeSetPassword,
        builder: (context, state) => const SetPasswordScreen(),
      ),
      GoRoute(
        path: GuardianConstants.routeActivateAdmin,
        builder: (context, state) => const ActivateAdminScreen(),
      ),
      GoRoute(
        path: GuardianConstants.routeEnableVpn,
        builder: (context, state) => const EnableVpnScreen(),
      ),
      GoRoute(
        path: GuardianConstants.routeEnableAccessibility,
        builder: (context, state) => const EnableAccessibilityScreen(),
      ),
      GoRoute(
        path: GuardianConstants.routePasswordHandoff,
        builder: (context, state) {
          final password = state.extra as String? ?? '';
          return PasswordHandoffScreen(plainPassword: password);
        },
      ),
    ],
  );
});

class GuardianApp extends ConsumerWidget {
  const GuardianApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Guardian',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4F8EF7),
          secondary: Color(0xFF22C55E),
          error: Color(0xFFEF4444),
        ),
      ),
    );
  }
}
