import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian/%20models/streak_record.dart';
import 'package:guardian/providers/config_provider.dart';
import 'package:guardian/providers/protection_provider.dart';
import 'package:guardian/providers/streak_provider.dart';
import 'package:guardian/core/constants.dart';
import 'package:guardian/widgets/protection_status_card.dart';
import 'package:guardian/widgets/motivational_quote.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protectionAsync = ref.watch(protectionProvider);
    final streakAsync = ref.watch(streakProvider);
    final configState = ref.watch(configProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Analytics',
            onPressed: () => context.go(GuardianConstants.routeAnalytics),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: '21-Day Challenge',
            onPressed: () => context.go(GuardianConstants.routeChallenge),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.go(GuardianConstants.routeSettings),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(protectionProvider.notifier).refresh(),
            ref.read(streakProvider.notifier).refresh(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ✅ MODE DISPLAY (FIXED CORRECTLY)
            configState.when(
              data: (state) {
                if (state is ConfigReady) {
                  final isStrict =
                      state.config.protectionMode == "strict";

                  return Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isStrict
                          ? Colors.red.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Mode: ${state.config.protectionMode.toUpperCase()}",
                      style: TextStyle(
                        color: isStrict ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),

            _buildStreakCard(streakAsync),
            const SizedBox(height: 16),

            const MotivationalQuote(),
            const SizedBox(height: 16),

            protectionAsync.when(
              data: (status) => ProtectionStatusCard(status: status),
              loading: () => const LinearProgressIndicator(),
              error: (e, st) =>
              const Text('Failed to load protection status'),
            ),

            const SizedBox(height: 16),

            protectionAsync.when(
              data: (status) =>
                  _buildBlockCountCard(status.blockCount),
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () =>
                    context.go(GuardianConstants.routeEmergency),
                icon: const Icon(Icons.emergency, color: Colors.white),
                label: const Text(
                  "I'm Struggling — Get Help Now",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(AsyncValue<StreakRecord?> streakAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: streakAsync.when(
          data: (StreakRecord? record) {
            if (record == null) {
              return const Text('Start your streak today.');
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT STREAK',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${record.totalDays}',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF22C55E),
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'days',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  'Since ${_formatDate(record.startDate)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            );
          },
          loading: () =>
          const Center(child: CircularProgressIndicator()),
          error: (e, st) =>
          const Text('Streak data unavailable'),
        ),
      ),
    );
  }

  Widget _buildBlockCountCard(int count) {
    return Card(
      child: Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              color: Color(0xFF4F8EF7),
              size: 32,
            ),
            const SizedBox(width: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BLOCKED ATTEMPTS',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F8EF7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}