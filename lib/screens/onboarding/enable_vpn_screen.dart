// lib/screens/onboarding/enable_vpn_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian/core/constants.dart';
import 'package:guardian/providers/protection_provider.dart';

class EnableVpnScreen extends ConsumerWidget {
  const EnableVpnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protectionAsync = ref.watch(protectionProvider);
    final vpnActive = protectionAsync.value?.vpnEnabled ?? false;

    ref.listen(protectionProvider, (prev, next) {
      final active = next.value?.vpnEnabled ?? false;
      if (active) {
        final password = GoRouterState.of(context).extra as String?;

        context.go(
          GuardianConstants.routeEnableAccessibility,
          extra: password,
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Step 3 of 6 - Turn on Protection'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),

            const Icon(Icons.vpn_lock, size: 70, color: Color(0xFF4F8EF7)),

            const SizedBox(height: 24),

            const Text(
              'Turn On Protection',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Tap the button below.\n\n'
                  'When Android shows a popup,\n'
                  'tap OK or Allow.\n\n'
                  'That’s it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 30),

            if (vpnActive)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF065F46),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 10),
                    Text(
                      'Protection is ON',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: vpnActive
                    ? null
                    : () async {
                  try {
                    final started = await ref
                        .read(protectionProvider.notifier)
                        .startVpn();

                    if (!started) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tap OK on the popup to enable protection',
                          ),
                        ),
                      );
                    }

                    HapticFeedback.mediumImpact();
                  } catch (_) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to start protection'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: vpnActive
                      ? Colors.green
                      : const Color(0xFF4F8EF7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  vpnActive ? 'Protection Enabled' : 'Turn On Protection',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}