// lib/widgets/breathing_exercise.dart
// FIX: withOpacity replaced with withValues(alpha:) throughout
import 'dart:async';
import 'package:flutter/material.dart';

enum BreathingPhase { inhale, hold, exhale }

class BreathingExercise extends StatefulWidget {
  const BreathingExercise({super.key});

  @override
  State<BreathingExercise> createState() => _BreathingExerciseState();
}

class _BreathingExerciseState extends State<BreathingExercise>
    with WidgetsBindingObserver {
  static const int _inhaleSeconds = 4;
  static const int _holdSeconds   = 7;
  static const int _exhaleSeconds = 8;

  Timer? _timer;
  BreathingPhase _phase     = BreathingPhase.inhale;
  int            _remaining = _inhaleSeconds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCycle();
  }

  void _startCycle() {
    _cancelTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining > 1) {
        setState(() => _remaining--);
        return;
      }
      switch (_phase) {
        case BreathingPhase.inhale:
          _phase = BreathingPhase.hold;
          _remaining = _holdSeconds;
        case BreathingPhase.hold:
          _phase = BreathingPhase.exhale;
          _remaining = _exhaleSeconds;
        case BreathingPhase.exhale:
          _phase = BreathingPhase.inhale;
          _remaining = _inhaleSeconds;
      }
      setState(() {});
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _cancelTimer();
    } else if (state == AppLifecycleState.resumed) {
      _startCycle();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimer();
    super.dispose();
  }

  String get _label => switch (_phase) {
        BreathingPhase.inhale => 'Inhale',
        BreathingPhase.hold   => 'Hold',
        BreathingPhase.exhale => 'Exhale',
      };

  double get _scale => switch (_phase) {
        BreathingPhase.inhale => 1.3,
        BreathingPhase.hold   => 1.3,
        BreathingPhase.exhale => 1.0,
      };

  Color get _color => switch (_phase) {
        BreathingPhase.inhale => const Color(0xFF4F8EF7),
        BreathingPhase.hold   => const Color(0xFF8B5CF6),
        BreathingPhase.exhale => const Color(0xFF22C55E),
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          '4-7-8 Breathing',
          style: TextStyle(
              color: Colors.grey, fontSize: 12, letterSpacing: 1.5),
        ),
        const SizedBox(height: 16),
        AnimatedContainer(
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
          width:  160 * _scale,
          height: 160 * _scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // FIX: withValues(alpha:) instead of deprecated withOpacity
            color:  _color.withValues(alpha: 0.15),
            border: Border.all(
                color: _color.withValues(alpha: 0.4), width: 2),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _label,
                  style: TextStyle(
                    color: _color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_remaining s',
                  style: const TextStyle(
                      fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
