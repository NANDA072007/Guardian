// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian/%20models/streak_record.dart'; // ✅ FIXED
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final exit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit Guardian?'),
            content: const Text(
              'Protection is active. Are you sure you want to exit?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Stay'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );

        if (exit == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Guardian'),
          actions: [
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () => context.go(GuardianConstants.routeAnalytics),
            ),
            IconButton(
              icon: const Icon(Icons.emoji_events_outlined),
              onPressed: () => context.go(GuardianConstants.routeChallenge),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
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
                error: (_, __) =>
                const Text('Failed to load protection status'),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.go(GuardianConstants.routeEmergency),
                  icon: const Icon(Icons.emergency),
                  label: const Text("I'm Struggling — Get Help Now"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard(AsyncValue<StreakRecord?> streakAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: streakAsync.when(
          data: (record) {
            if (record == null) {
              return const Text('Start your streak today.');
            }
            return Text('Streak: ${record.totalDays} days');
          },
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Text('Error'),
        ),
      ),
    );
  }
}