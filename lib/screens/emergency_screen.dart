// lib/screens/emergency_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardian/providers/config_provider.dart';
import 'package:guardian/services/protection_service.dart';
import 'package:guardian/widgets/breathing_exercise.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  Timer? _movementTimer;
  int _remainingSeconds = 600;
  bool _isRunning = false;

  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }

  void _startMovementTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _movementTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() { _remainingSeconds = 0; _isRunning = false; });
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void _stopMovementTimer() {
    _movementTimer?.cancel();
    _movementTimer = null;
    if (mounted) setState(() => _isRunning = false);
  }

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave emergency mode?'),
        content: const Text(
          'You opened this because you were struggling. '
          'Are you sure you want to leave now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _callAccountability(String phone) async {
    try {
      final service = ref.read(protectionServiceProvider);
      await service.callNumber(phone);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not make call: $e')),
      );
    }
  }

  Future<void> _smsAccountability(String phone) async {
    try {
      final service = ref.read(protectionServiceProvider);
      await service.smsNumber(
        phone,
        message: "I need support right now. Please reach out to me.",
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send message: $e')),
      );
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(configProvider);

    return PopScope(
      canPop: false,
      // FIX: onPopInvoked is deprecated since Flutter 3.22 — use onPopInvokedWithResult
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmExit();
        if (shouldExit && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Emergency'),
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF1E293B),
        ),
        backgroundColor: const Color(0xFF0F172A),
        body: configAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (configState) {
            final phone = (configState is ConfigReady)
                ? configState.config.accountabilityPhone
                : null;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const BreathingExercise(),
                  const SizedBox(height: 32),

                  Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get up and move for 10 minutes',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _isRunning ? null : _startMovementTimer,
                        child: const Text('Start Timer'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _isRunning ? _stopMovementTimer : null,
                        child: const Text('Stop'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 16),

                  if (phone != null && phone.isNotEmpty) ...[
                    const Text(
                      'REACH OUT NOW',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 11, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _callAccountability(phone),
                            icon: const Icon(Icons.call),
                            label: const Text('Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _smsAccountability(phone),
                            icon: const Icon(Icons.sms),
                            label: const Text('Message'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F8EF7),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      'No accountability person set.\nGo to Settings to add one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        final exit = await _confirmExit();
                        if (exit && context.mounted) Navigator.of(context).pop();
                      },
                      child: const Text("I'm okay now — go back"),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
