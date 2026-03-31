// lib/screens/block_overlay_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardian/%20models/streak_record.dart';
import 'package:guardian/providers/streak_provider.dart';

final overlayTimerProvider =
    AsyncNotifierProvider<OverlayTimerNotifier, int>(OverlayTimerNotifier.new);

class OverlayTimerNotifier extends AsyncNotifier<int> {
  static const int _initialSeconds = 10;
  Timer? _timer;

  @override
  Future<int> build() async {
    int remaining = _initialSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remaining <= 1) {
        t.cancel();
        state = const AsyncData(0);
      } else {
        remaining--;
        state = AsyncData(remaining);
      }
    });
    ref.onDispose(() => _timer?.cancel());
    return _initialSeconds;
  }
}

class BlockOverlayScreen extends ConsumerStatefulWidget {
  const BlockOverlayScreen({super.key});

  @override
  ConsumerState<BlockOverlayScreen> createState() => _BlockOverlayScreenState();
}

class _BlockOverlayScreenState extends ConsumerState<BlockOverlayScreen> {
  bool _canExit = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _handleExit() {
    if (!_canExit) return;
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final timerAsync = ref.watch(overlayTimerProvider);
    final streakAsync = ref.watch(streakProvider);

    ref.listen(overlayTimerProvider, (prev, next) {
      if (next.value == 0 && !_canExit) {
        setState(() => _canExit = true);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: timerAsync.when(
            data: (seconds) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield, size: 90, color: Colors.white),
                const SizedBox(height: 32),
                const Text(
                  "You're stronger than this.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Go for a walk.",
                  style: TextStyle(color: Colors.white70, fontSize: 17),
                ),
                const SizedBox(height: 36),

                // FIX: Explicit StreakRecord? type on .when data callback
                // avoids 'Object' inferred type which has no .totalDays getter
                streakAsync.when(
                  data: (StreakRecord? record) => Text(
                    "Day ${record?.totalDays ?? 0} — Don't lose it.",
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 52),
                _buildButton(seconds),
              ],
            ),
            loading: () => const CircularProgressIndicator(color: Colors.white),
            error: (e, st) => const Text(
              'System protection active',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(int seconds) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton(
        key: ValueKey(_canExit),
        onPressed: _canExit ? _handleExit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _canExit ? const Color(0xFF22C55E) : Colors.grey.shade800,
          minimumSize: const Size(220, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          _canExit ? "I'm okay now" : "Wait  $seconds s",
          style: const TextStyle(fontSize: 17, color: Colors.white),
        ),
      ),
    );
  }
}
