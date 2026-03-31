// lib/screens/onboarding/enable_vpn_screen.dart
// No changes from original — already uses GoRouter and protectionProvider correctly
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian/providers/protection_provider.dart';
import 'package:guardian/core/constants.dart';

class EnableVpnScreen extends ConsumerStatefulWidget {
  const EnableVpnScreen({super.key});

  @override
  ConsumerState<EnableVpnScreen> createState() => _EnableVpnScreenState();
}

class _EnableVpnScreenState extends ConsumerState<EnableVpnScreen> {
  bool _isStarting = false;
  String? _error;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startVpn() async {
    if (_isStarting) return;
    setState(() { _isStarting = true; _error = null; });

    try {
      final started = await ref.read(protectionProvider.notifier).startVpn();
      // false = permission dialog shown — poll until VPN is confirmed active
      if (!started) {
        _startPolling();
        return;
      }
      _startPolling();
    } catch (_) {
      setState(() {
        _error = 'Failed to start VPN. Try again.';
        _isStarting = false;
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await ref.read(protectionProvider.notifier).refresh();
      final status = ref.read(protectionProvider).value;

      if (status?.vpnEnabled == true) {
        timer.cancel();
        if (!mounted) return;
        context.go(GuardianConstants.routeEnableAccessibility);
      }
    });

    // Timeout after 15 seconds
    Future.delayed(const Duration(seconds: 15), () {
      if (!mounted) return;
      if (ref.read(protectionProvider).value?.vpnEnabled != true) {
        _pollTimer?.cancel();
        setState(() {
          _error = 'VPN did not start. Please accept the VPN permission dialog.';
          _isStarting = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final protectionAsync = ref.watch(protectionProvider);
    final vpnActive = protectionAsync.value?.vpnEnabled ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Step 3 of 6 — Enable VPN'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            const Icon(Icons.vpn_lock, size: 64, color: Color(0xFF4F8EF7)),
            const SizedBox(height: 24),
            const Text(
              'Start VPN Protection',
              style: TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Guardian\'s VPN filters DNS queries against 100,000+ adult domains '
              'before any content loads.\n\n'
              'Your traffic stays on your device — nothing is sent to any server.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Live VPN status
            protectionAsync.when(
              data: (s) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    s.vpnEnabled ? Icons.check_circle : Icons.cancel,
                    color: s.vpnEnabled ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.vpnEnabled ? 'VPN Active' : 'VPN Not Active',
                    style: TextStyle(
                      color: s.vpnEnabled ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Status unknown',
                  style: TextStyle(color: Colors.grey)),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center),
              ),
            ],

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_isStarting || vpnActive) ? null : _startVpn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F8EF7),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isStarting
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        vpnActive ? 'VPN Active ✓' : 'Start VPN',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () {
                ref.read(protectionProvider.notifier).openVpnSettings();
              },
              child: const Text('Open VPN Settings (for Always-On mode)'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
