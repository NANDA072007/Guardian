// lib/screens/onboarding/activate_admin_screen.dart
// FIXES:
// 1. Removed raw MethodChannel — all calls through protectionProvider
// 2. GoRouter navigation instead of Navigator.pushReplacementNamed('/enable-vpn')
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian/providers/protection_provider.dart';
import 'package:guardian/core/constants.dart';

class ActivateAdminScreen extends ConsumerStatefulWidget {
  const ActivateAdminScreen({super.key});

  @override
  ConsumerState<ActivateAdminScreen> createState() =>
      _ActivateAdminScreenState();
}

class _ActivateAdminScreenState extends ConsumerState<ActivateAdminScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _activate() async {
    setState(() { _loading = true; _error = null; });
    try {
      // FIX: Use protectionProvider — not a raw MethodChannel instance
      await ref.read(protectionProvider.notifier).activateAdmin();
    } catch (e) {
      setState(() => _error = 'Failed to open admin screen: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkAndProceed() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(protectionProvider.notifier).refresh();
      final status = ref.read(protectionProvider).value;

      if (status?.adminEnabled == true) {
        if (!mounted) return;
        // FIX: GoRouter, not Navigator.pushReplacementNamed('/enable-vpn')
        context.go(GuardianConstants.routeEnableVpn);
      } else {
        setState(() =>
          _error = 'Device Admin not activated yet. Tap "Activate" and grant permission.');
      }
    } catch (e) {
      setState(() => _error = 'Could not check status: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Step 2 of 6 — Device Admin'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            const Icon(Icons.admin_panel_settings, size: 64, color: Color(0xFF4F8EF7)),
            const SizedBox(height: 24),
            const Text(
              'Activate Device Admin',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Device Admin prevents Guardian from being uninstalled '
              'without your trusted person\'s password.\n\n'
              'On the next screen, tap "Activate" when Android asks.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _activate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F8EF7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Activate Device Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _loading ? null : _checkAndProceed,
                child: const Text("I've Activated — Continue"),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
