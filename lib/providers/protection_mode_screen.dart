import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian/providers/config_provider.dart';

class ProtectionModeScreen extends ConsumerWidget {
  final String password;

  const ProtectionModeScreen({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Choose Protection Mode"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            _ModeCard(
              title: "Normal Mode (Recommended)",
              desc: "Fast internet\nBasic protection\nNo VPN",
              color: Colors.green,
              onTap: () async {
                await ref.read(configProvider.notifier)
                    .setProtectionMode("normal");

                if (!context.mounted) return;

                // ✅ PASS PASSWORD FORWARD
                context.go(
                  "/onboarding/enable-accessibility",
                  extra: password,
                );
              },
            ),

            const SizedBox(height: 20),

            _ModeCard(
              title: "Strict Mode",
              desc: "Maximum protection\nUses VPN\nMay slow internet",
              color: Colors.red,
              onTap: () async {
                await ref.read(configProvider.notifier)
                    .setProtectionMode("strict");

                if (!context.mounted) return;

                // ✅ PASS PASSWORD FORWARD
                context.go(
                  "/onboarding/enable-vpn",
                  extra: password,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String desc;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.desc,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(desc,
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}