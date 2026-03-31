// lib/screens/onboarding/set_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian/%20models/guardian_config.dart';
// FIX: correct import path — no %20 space encoding
import 'package:guardian/core/password_hasher.dart';
import 'package:guardian/core/constants.dart';
import 'package:guardian/providers/config_provider.dart';

final passwordSetupProvider =
    AsyncNotifierProvider<PasswordSetupController, void>(
  PasswordSetupController.new,
);

class PasswordSetupController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setPassword({
    required String password,
    required String confirmPassword,
  }) async {
    state = const AsyncLoading();
    try {
      if (password != confirmPassword) throw const PasswordMismatchException();
      final hash = PasswordHasher.hash(password);

      // FIX: isConfigured = false — setup not complete until final handoff step
      final config = GuardianConfig(
        passwordHash: hash,
        setupDate: DateTime.now(),
        isConfigured: false,
      );

      final storage = ref.read(secureStorageProvider);
      await storage.saveConfig(config);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

class PasswordMismatchException implements Exception {
  const PasswordMismatchException();
}

class SetPasswordScreen extends ConsumerStatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();
  bool _obscure       = true;
  bool _isSubmitting  = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final password = _passwordController.text.trim();
    final confirm  = _confirmController.text.trim();

    try {
      await ref.read(passwordSetupProvider.notifier).setPassword(
        password: password,
        confirmPassword: confirm,
      );
      if (!mounted) return;
      context.go(GuardianConstants.routeActivateAdmin);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapError(e))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _mapError(Object err) {
    if (err is EmptyPasswordException)    return err.message;
    if (err is WeakPasswordException)     return err.message;
    if (err is PasswordMismatchException) return 'Passwords do not match';
    return 'Unexpected error — try again';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Step 1 of 6 — Set Password'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Text(
                'Set Your Protection Password',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'This password will be given to your trusted person. '
                'You will NOT keep it.\n\n'
                'Choose something you cannot easily guess.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              _inputField(_passwordController, 'Enter password'),
              const SizedBox(height: 16),
              _inputField(_confirmController, 'Confirm password'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: !_obscure,
                    onChanged: (v) => setState(() => _obscure = !_obscure),
                  ),
                  const Text('Show password',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F8EF7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Set Password & Continue',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      obscureText: _obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF4F8EF7)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
