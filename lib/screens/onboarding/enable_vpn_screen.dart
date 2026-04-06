// lib/screens/onboarding/enable_vpn_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian/core/constants.dart';
import 'package:guardian/providers/protection_provider.dart';

class EnableVpnScreen extends ConsumerStatefulWidget {
  const EnableVpnScreen({super.key});

  @override
  ConsumerState<EnableVpnScreen> createState() => _EnableVpnScreenState();
}

class _EnableVpnScreenState extends ConsumerState<EnableVpnScreen>
    with WidgetsBindingObserver {
  bool _isStarting = false;
  bool _waitingForPermission = false; // system dialog likely visible
  bool _autoStartAttempted = false;
  bool _autoProceeded = false;
  bool _showTroubleshoot = false;
  String? _error;

  Timer? _pollTimer;
  Timer? _troubleshootTimer;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Reduce friction: try once automatically so the user only needs to tap OK.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoStart();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _troubleshootTimer?.cancel();
    _timeoutTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_refreshAndMaybeProceed());
  }

  Future<void> _refreshAndMaybeProceed() async {
    await ref.read(protectionProvider.notifier).refresh();
    final vpnActive = ref.read(protectionProvider).value?.vpnEnabled ?? false;
    if (vpnActive && mounted) {
      context.go(GuardianConstants.routeEnableAccessibility);
    }
  }

  void _maybeProceedIfActive(bool vpnActive) {
    if (_autoProceeded || !vpnActive) return;
    _autoProceeded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(GuardianConstants.routeEnableAccessibility);
    });
  }

  Future<void> _maybeAutoStart() async {
    if (_autoStartAttempted) return;
    _autoStartAttempted = true;

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    await ref.read(protectionProvider.notifier).refresh();
    final vpnActive = ref.read(protectionProvider).value?.vpnEnabled ?? false;
    if (vpnActive) return;

    await _startVpn(startedAutomatically: true);
  }

  Future<void> _openVpnSettings() async {
    try {
      await ref.read(protectionProvider.notifier).openVpnSettings();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open VPN settings')),
      );
    }
  }

  Future<void> _startVpn({required bool startedAutomatically}) async {
    if (_isStarting) return;

    setState(() {
      _isStarting = true;
      _waitingForPermission = false;
      _showTroubleshoot = false;
      _error = null;
    });

    try {
      final started = await ref.read(protectionProvider.notifier).startVpn();
      if (!mounted) return;

      if (!started) {
        setState(() {
          _waitingForPermission = true;
          // We are now waiting on the user to tap OK/Allow on the system dialog.
          _isStarting = false;
        });
        unawaited(HapticFeedback.mediumImpact());
      }

      _startPolling();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = startedAutomatically
            ? 'Could not start protection. Tap the button below.'
            : 'Could not start protection. Try again.';
        _isStarting = false;
        _waitingForPermission = false;
        _showTroubleshoot = true;
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _troubleshootTimer?.cancel();
    _timeoutTimer?.cancel();

    _pollTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await ref.read(protectionProvider.notifier).refresh();
      final vpnActive = ref.read(protectionProvider).value?.vpnEnabled ?? false;

      if (!vpnActive) return;

      timer.cancel();
      _troubleshootTimer?.cancel();
      _timeoutTimer?.cancel();

      if (!mounted) return;
      context.go(GuardianConstants.routeEnableAccessibility);
    });

    _troubleshootTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted) return;
      if (ref.read(protectionProvider).value?.vpnEnabled == true) return;
      setState(() => _showTroubleshoot = true);
    });

    _timeoutTimer = Timer(const Duration(seconds: 60), () {
      if (!mounted) return;
      if (ref.read(protectionProvider).value?.vpnEnabled == true) return;
      setState(() {
        _waitingForPermission = true;
        _showTroubleshoot = true;
        _error = 'Still waiting. If you see an Android popup, tap OK / Allow.';
        _isStarting = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final protectionAsync = ref.watch(protectionProvider);
    final vpnActive = protectionAsync.value?.vpnEnabled ?? false;
    _maybeProceedIfActive(vpnActive);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Step 3 of 6 - Turn on Protection'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                const Icon(Icons.vpn_lock, size: 64, color: Color(0xFF4F8EF7)),
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
                  'Guardian blocks adult sites on this phone.\n\n'
                  'Android will show a small popup.\n'
                  'When it appears, tap  OK  /  Allow.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                if (!vpnActive && !_waitingForPermission)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF000000)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EASY 2 STEPS:',
                          style: TextStyle(
                            color: Color(0xFF4F8EF7),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 12),
                        _Step(
                          number: '1',
                          text: 'Tap the blue button below',
                          highlight: true,
                        ),
                        SizedBox(height: 8),
                        _Step(
                          number: '2',
                          text: 'When Android asks, tap  OK  /  Allow',
                          highlight: true,
                        ),
                      ],
                    ),
                  ),
                if (vpnActive)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF065F46).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF22C55E)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF22C55E)),
                        SizedBox(width: 10),
                        Text(
                          'Protection is ON',
                          style: TextStyle(
                            color: Color(0xFF22C55E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
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
                    onPressed:
                        (_isStarting || vpnActive || _waitingForPermission)
                        ? null
                        : () => _startVpn(startedAutomatically: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: vpnActive
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF4F8EF7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isStarting && !_waitingForPermission
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            vpnActive
                                ? 'Protection is ON'
                                : 'Turn On Protection',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (!vpnActive &&
                    _showTroubleshoot &&
                    !_waitingForPermission) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _openVpnSettings,
                    child: const Text('Open VPN settings'),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (_waitingForPermission)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF4F8EF7), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_upward,
                      color: Color(0xFF4F8EF7),
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tap OK on the Android popup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A small popup is on your screen.\n'
                      'Tap  OK  /  Allow to continue.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F8EF7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    if (_showTroubleshoot) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isStarting
                                  ? null
                                  : () =>
                                        _startVpn(startedAutomatically: false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Color(0xFF4F8EF7),
                                ),
                              ),
                              child: const Text('Try again'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _openVpnSettings,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white24),
                              ),
                              child: const Text('Open settings'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  final bool highlight;

  const _Step({
    required this.number,
    required this.text,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlight
                ? const Color(0xFF22C55E)
                : const Color(0xFF4F8EF7).withValues(alpha: 0.3),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: highlight ? Colors.white : const Color(0xFF4F8EF7),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: highlight ? const Color(0xFF22C55E) : Colors.white70,
              fontSize: 14,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
