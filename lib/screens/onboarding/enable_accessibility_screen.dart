// lib/screens/onboarding/enable_accessibility_screen.dart
// FIX: GoRouter navigation instead of Navigator.pushReplacementNamed("/password-handoff")
// Also reads current password hash from secure storage to pass to handoff screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian/providers/protection_provider.dart';
import 'package:guardian/core/constants.dart';

class EnableAccessibilityScreen extends ConsumerStatefulWidget {
  const EnableAccessibilityScreen({super.key});

  @override
  ConsumerState<EnableAccessibilityScreen> createState() =>
      _EnableAccessibilityScreenState();
}

class _EnableAccessibilityScreenState
    extends ConsumerState<EnableAccessibilityScreen>
    with WidgetsBindingObserver {
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Auto-refresh status when user comes back from Accessibility Settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(protectionProvider.notifier).refresh();
    }
  }

  Future<void> _openSettings() async {
    try {
      await ref.read(protectionProvider.notifier).openAccessibilitySettings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Accessibility Settings')),
      );
    }
  }

  Future<void> _checkAndProceed() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(protectionProvider.notifier).refresh();
      final status = ref.read(protectionProvider).value;

      if (status?.accessibilityEnabled == true) {
        if (!mounted) return;

        // Get the plain password from secure storage to show in handoff screen
        // The password was stored as a hash, but we need the hash to verify
        // The handoff screen shows the plain text which was entered at step 1
        // Since we can't reverse SHA-256, we stored a temp flag or ask user to re-enter
        // Simple solution: navigate without password extra — handoff will prompt re-entry
        // FIX: Navigate using GoRouter, not old Navigator API
        final password = GoRouterState.of(context).extra as String?;

        context.go(
          GuardianConstants.routePasswordHandoff,
          extra: password ?? '',
        );
      } else {
        setState(() => _error = 'Accessibility not enabled yet. Open Settings and enable Guardian.');
      }
    } catch (e) {
      setState(() => _error = 'Could not check status: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final protectionAsync = ref.watch(protectionProvider);
    final isEnabled = protectionAsync.value?.accessibilityEnabled ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Step 4 of 6 — Accessibility'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            const Icon(Icons.visibility, size: 64, color: Color(0xFF4F8EF7)),
            const SizedBox(height: 24),
            const Text(
              'Enable Accessibility Service',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Guardian monitors URL bars and screen text to catch harmful '
              'content before it loads — even if you type an address directly.\n\n'
              'In the next screen: tap Guardian → turn it ON.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Live status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isEnabled
                    ? const Color(0xFF065F46)
                    : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isEnabled ? Icons.check_circle : Icons.cancel,
                    color: isEnabled ? Colors.green : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEnabled ? 'Accessibility ENABLED' : 'NOT enabled yet',
                    style: TextStyle(
                      color: isEnabled ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _openSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F8EF7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Open Accessibility Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: isEnabled && !_loading ? _checkAndProceed : null,
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("I've enabled it — Continue"),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
