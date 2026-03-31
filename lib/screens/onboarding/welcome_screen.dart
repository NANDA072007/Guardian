// lib/screens/onboarding/welcome_screen.dart
// Proper welcome screen — was a stub with just Text('Welcome')
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian/core/constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(Icons.shield, size: 80, color: Color(0xFF4F8EF7)),
              const SizedBox(height: 24),
              const Text(
                'GUARDIAN',
                style: TextStyle(
                  color: Color(0xFF4F8EF7),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your mind. Protected. Forever.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              const Text(
                'Guardian blocks harmful content at 4 levels of your device — '
                'VPN, Accessibility, Screen Analysis, and Device Admin.\n\n'
                'Once set up, only your trusted person can disable it.\n\n'
                'Willpower fails. Systems win.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go(GuardianConstants.routeSetPassword),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F8EF7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "I'm ready to commit",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
