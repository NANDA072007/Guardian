// lib/screens/settings_screen.dart — fully functional settings with password gate
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardian/providers/password_gate_provider.dart';
import 'package:guardian/providers/config_provider.dart';
import 'package:guardian/providers/streak_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  bool _unlocked = false;
  bool _isLockedOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  // Auto-lock when app goes to background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      setState(() => _unlocked = false);
      ref.read(passwordGateProvider.notifier).reset();
    }
  }

  Future<void> _verify() async {
    final password = _controller.text.trim();
    await ref.read(passwordGateProvider.notifier).verify(password);
  }

  Future<void> _showRelapseDialog() async {
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log a Relapse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will reset your streak to Day 1.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Optional: what triggered this?',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset Streak'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await ref.read(streakProvider.notifier).reset(
            reasonController.text.trim().isEmpty
                ? null
                : reasonController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Streak reset. Day 1 starts now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gateState = ref.watch(passwordGateProvider);

    // React to password gate state
    gateState.when(
      data: (success) {
        if (success && !_unlocked) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _unlocked = true);
          });
        }
      },
      error: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          _controller.clear();
          if (mounted) setState(() => _isLockedOut = true);
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) setState(() => _isLockedOut = false);
        });
      },
      loading: () {},
    );

    if (!_unlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings — Password Required')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 56, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Enter your trusted person\'s password to access settings.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                obscureText: true,
                enabled: !_isLockedOut,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 16),
              if (_isLockedOut)
                const Text('Incorrect — wait 2 seconds',
                    style: TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLockedOut ? null : _verify,
                  child: gateState.isLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Unlock'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ==================== UNLOCKED SETTINGS ====================
    final configAsync = ref.watch(configProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Accountability person
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: configAsync.when(
                data: (state) {
                  if (state is! ConfigReady) return const Text('Config not loaded');
                  final config = state.config;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ACCOUNTABILITY PERSON',
                          style: TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Text(config.accountabilityName ?? 'Not set',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(config.accountabilityPhone ?? '',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Error loading config'),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Relapse logging
          ListTile(
            leading: const Icon(Icons.restart_alt, color: Colors.orange),
            title: const Text('Log a Relapse'),
            subtitle: const Text('Resets streak to Day 1'),
            onTap: _showRelapseDialog,
          ),

          const Divider(),

          // Danger zone
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text('DANGER ZONE',
                style: TextStyle(color: Colors.red, fontSize: 11, letterSpacing: 1.5)),
          ),
          ListTile(
            leading: const Icon(Icons.no_encryption, color: Colors.red),
            title: const Text('Disable Guardian'),
            subtitle: const Text('Requires your trusted person to agree'),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Disable Guardian?'),
                  content: const Text(
                    'To disable Guardian you must deactivate Device Admin in '
                    'Android Settings. Your trusted person must enter the password.\n\n'
                    'This removes ALL protection immediately.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
