// lib/screens/splash_screen.dart — unchanged from your original, already correct
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian/providers/config_provider.dart';
import 'package:guardian/core/constants.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideRoute();
  }

  Future<void> _decideRoute() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final configState = await ref.read(configProvider.future);
    if (!mounted) return;

    switch (configState) {
      case ConfigReady():
        context.go(GuardianConstants.routeDashboard);
      case ConfigOnboarding():
        context.go(GuardianConstants.routeOnboarding);
      case ConfigError():
        context.go(GuardianConstants.routeOnboarding); // fail-safe
      default:
        context.go(GuardianConstants.routeOnboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield, size: 64, color: Color(0xFF4F8EF7)),
            SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F8EF7)),
            ),
          ],
        ),
      ),
    );
  }
}
