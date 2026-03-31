// lib/screens/onboarding/password_handoff_screen.dart
// FIX: Calls setWindowSecure(true) when screen opens so screenshots are blocked
// The plain-text password is visible here — must not appear in screenshots
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian/providers/config_provider.dart';
import 'package:guardian/services/protection_service.dart';
import 'package:guardian/core/constants.dart';

class PasswordHandoffScreen extends ConsumerStatefulWidget {
  // Plain text password — shown once, user must send to trusted person
  final String plainPassword;

  const PasswordHandoffScreen({
    super.key,
    required this.plainPassword,
  });

  @override
  ConsumerState<PasswordHandoffScreen> createState() =>
      _PasswordHandoffScreenState();
}

class _PasswordHandoffScreenState
    extends ConsumerState<PasswordHandoffScreen> {
  final _nameController  = TextEditingController();
  final _phoneController = TextEditingController();
  bool _confirmed = false;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // FIX: Prevent screenshots while plain-text password is visible
    // This is a security requirement — the password is the only disable key
    ref.read(protectionServiceProvider).setWindowSecure(true);
  }

  @override
  void dispose() {
    // Re-enable screenshots when leaving this screen
    ref.read(protectionServiceProvider).setWindowSecure(false);
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_saving) return;

    final name  = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      setState(() => _error = 'Please enter both name and phone number');
      return;
    }

    if (!_confirmed) {
      setState(() => _error = 'You must confirm you have sent the password');
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      await ref.read(configProvider.notifier).completeSetup(
        accountabilityName: name,
        accountabilityPhone: phone,
      );

      if (!mounted) return;
      // Setup is fully complete — go to Dashboard
      context.go(GuardianConstants.routeDashboard);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to save. Try again.';
        _saving = false;
      });
    }
  }

  void _copyPassword() {
    Clipboard.setData(ClipboardData(text: widget.plainPassword));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // No back button at this step
        title: const Text('Step 5 of 6 — Password Handoff'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ==================== WARNING ====================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade700),
              ),
              child: const Text(
                'This password controls ALL of Guardian.\n\n'
                'You will NOT keep it. Send it to someone you trust completely.\n'
                'Then delete it from your device.\n\n'
                'Without it, you cannot disable Guardian. That is the point.',
                style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
              ),
            ),

            const SizedBox(height: 24),

            // ==================== PASSWORD DISPLAY ====================
            // FLAG_SECURE is active — this screen cannot be screenshotted
            const Text(
              'YOUR GUARDIAN PASSWORD',
              style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF22C55E)),
              ),
              child: SelectableText(
                widget.plainPassword.isNotEmpty
                    ? widget.plainPassword
                    : '[Password not available — go back and set it again]',
                style: const TextStyle(
                  color: Color(0xFF22C55E),
                  fontSize: 22,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _copyPassword,
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy password'),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // ==================== TRUSTED PERSON ====================
            const Text(
              'Who are you sending this to?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Trusted person\'s name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Their phone number',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // ==================== CONFIRMATION ====================
            CheckboxListTile(
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v ?? false),
              title: const Text(
                'I have sent this password and deleted it from my messages',
                style: TextStyle(fontSize: 14),
              ),
              contentPadding: EdgeInsets.zero,
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _finish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Finish Setup — Start My Protection',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
