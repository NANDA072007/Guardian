// lib/screens/challenge_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardian/%20models/streak_record.dart';
import 'package:guardian/providers/streak_provider.dart';

class ChallengeScreen extends ConsumerWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('21-Day Challenge')),
      body: streakAsync.when(
        // FIX: Explicit StreakRecord? type annotation — without it the type is
        // inferred as 'Object' when StreakRecord import is not resolved, making
        // .totalDays inaccessible. Explicit annotation ensures correct resolution.
        data: (StreakRecord? record) {
          final day = (record?.totalDays ?? 1).clamp(1, 21);
          final progress = day / 21;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day $day of 21',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                  backgroundColor: Colors.grey.shade800,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    day >= 21
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF4F8EF7),
                  ),
                ),
                const SizedBox(height: 24),

                if (day >= 21)
                  const _MilestoneCard(
                    icon: Icons.emoji_events,
                    title: '21 Days Complete!',
                    message:
                        'You rebuilt a pattern. This is who you are now.',
                    color: Color(0xFF22C55E),
                  )
                else if (day >= 14)
                  const _MilestoneCard(
                    icon: Icons.warning_amber,
                    title: 'Danger Zone: Days 14–21',
                    message:
                        'This is statistically the hardest window. Stay vigilant. Reach out if you need to.',
                    color: Color(0xFFF59E0B),
                  )
                else if (day >= 7)
                  const _MilestoneCard(
                    icon: Icons.celebration,
                    title: 'One Week Done',
                    message:
                        'Your brain is already rewiring. The first week is the hardest.',
                    color: Color(0xFF4F8EF7),
                  ),

                const SizedBox(height: 24),
                const Text(
                  'WEEK BREAKDOWN',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                _WeekCard(
                  week: 'Week 1 (Days 1–7)',
                  description:
                      'Withdrawal and discomfort. Your brain is demanding dopamine. This is the hardest week physically.',
                  isComplete: day > 7,
                  isCurrent: day <= 7,
                ),
                const SizedBox(height: 8),
                _WeekCard(
                  week: 'Week 2 (Days 8–14)',
                  description:
                      'Cravings become psychological. Triggers appear from stress, boredom, loneliness. Identify and plan.',
                  isComplete: day > 14,
                  isCurrent: day > 7 && day <= 14,
                ),
                const SizedBox(height: 8),
                _WeekCard(
                  week: 'Week 3 (Days 15–21)',
                  description:
                      'The final stretch. Many relapse here because it feels "safe." It is not. Stay protected.',
                  isComplete: day > 21,
                  isCurrent: day > 14,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Failed to load streak')),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _MilestoneCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text(message,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  final String week;
  final String description;
  final bool isComplete;
  final bool isCurrent;

  const _WeekCard({
    required this.week,
    required this.description,
    required this.isComplete,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.grey.shade800;
    if (isComplete) borderColor = const Color(0xFF22C55E);
    if (isCurrent) borderColor = const Color(0xFF4F8EF7);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isComplete
                ? Icons.check_circle
                : isCurrent
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
            color: isComplete
                ? const Color(0xFF22C55E)
                : isCurrent
                    ? const Color(0xFF4F8EF7)
                    : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(week,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(description,
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
