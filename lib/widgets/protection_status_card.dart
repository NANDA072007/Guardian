// lib/widgets/protection_status_card.dart
// FIX: withOpacity → withValues(alpha:)
import 'package:flutter/material.dart';
import 'package:guardian/services/protection_service.dart';

class ProtectionStatusCard extends StatelessWidget {
  final ProtectionStatus status;

  const ProtectionStatusCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final allActive = status.isFullyProtected;

    return Card(
      color: allActive
          ? const Color(0xFF065F46).withValues(alpha: 0.5)
          : const Color(0xFF7F1D1D).withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: allActive
              ? const Color(0xFF22C55E)
              : const Color(0xFFEF4444),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  allActive ? Icons.shield : Icons.shield_outlined,
                  color: allActive
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEF4444),
                ),
                const SizedBox(width: 8),
                Text(
                  allActive
                      ? 'FULLY PROTECTED'
                      : 'PROTECTION INCOMPLETE',
                  style: TextStyle(
                    color: allActive
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LayerRow(label: 'VPN (DNS Filter)',          active: status.vpnEnabled),
            const SizedBox(height: 6),
            _LayerRow(label: 'Accessibility (URL Monitor)', active: status.accessibilityEnabled),
            const SizedBox(height: 6),
            _LayerRow(label: 'Device Admin (Anti-Uninstall)', active: status.adminEnabled),
          ],
        ),
      ),
    );
  }
}

class _LayerRow extends StatelessWidget {
  final String label;
  final bool   active;

  const _LayerRow({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          active ? Icons.check_circle : Icons.cancel,
          color: active ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
          size: 18,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/widgets/streak_calendar.dart
// FIX: withOpacity → withValues(alpha:)
