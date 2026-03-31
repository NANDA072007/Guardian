// lib/widgets/motivational_quote.dart
import 'package:flutter/material.dart';

class MotivationalQuote extends StatelessWidget {
  const MotivationalQuote({super.key});

  static const _quotes = [
    "Every day you resist is a day you reclaim yourself.",
    "Willpower fails. Systems win. You built the system.",
    "The urge will pass. It always does.",
    "You are not your addiction. You are the person fighting it.",
    "Each day clean is proof of who you really are.",
    "Discipline is choosing between what you want now and what you want most.",
    "You set this up because you knew this moment would come. Trust that version of you.",
    "The strongest people aren't those who never struggle — they're those who built a wall.",
    "You don't have to be perfect. You just have to not quit today.",
    "Your future self is watching. Make them proud.",
  ];

  @override
  Widget build(BuildContext context) {
    // Pick quote based on day of year so it changes daily but is stable within a day
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    final quote = _quotes[dayOfYear % _quotes.length];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '"',
            style: TextStyle(
              color: Color(0xFF4F8EF7),
              fontSize: 32,
              height: 0.8,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              quote,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
