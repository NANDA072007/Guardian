// lib/widgets/streak_calendar.dart
// FIX: withOpacity → withValues(alpha:)
import 'package:flutter/material.dart';

class StreakCalendar extends StatelessWidget {
  final DateTime  startDate;
  final int       totalDays;
  final DateTime? relapseDate;

  const StreakCalendar({
    super.key,
    required this.startDate,
    required this.totalDays,
    this.relapseDate,
  });

  @override
  Widget build(BuildContext context) {
    final now            = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth    = DateUtils.getDaysInMonth(now.year, now.month);
    final firstWeekday   = firstDayOfMonth.weekday % 7;

    final streakDays = <DateTime>{};
    for (int i = 0; i < totalDays; i++) {
      final d = startDate.add(Duration(days: i));
      streakDays.add(DateTime(d.year, d.month, d.day));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            _monthLabel(now),
            style: const TextStyle(
                color: Colors.grey, fontSize: 12, letterSpacing: 1.2),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) {
            return SizedBox(
              width: 36,
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (context, index) {
            if (index < firstWeekday) return const SizedBox.shrink();
            final day     = index - firstWeekday + 1;
            final date    = DateTime(now.year, now.month, day);
            final isToday = day == now.day;
            final isClean = streakDays.contains(date);
            final isRelapse = relapseDate != null &&
                date.year  == relapseDate!.year &&
                date.month == relapseDate!.month &&
                date.day   == relapseDate!.day;
            final isFuture = date.isAfter(now);

            return Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRelapse
                    ? const Color(0xFFEF4444).withValues(alpha: 0.8)
                    : isClean
                        ? const Color(0xFF22C55E).withValues(alpha: 0.7)
                        : isToday
                            ? const Color(0xFF4F8EF7).withValues(alpha: 0.3)
                            : Colors.transparent,
                border: isToday
                    ? Border.all(
                        color: const Color(0xFF4F8EF7), width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    color: isFuture
                        ? Colors.grey.shade700
                        : isClean || isRelapse
                            ? Colors.white
                            : Colors.grey,
                    fontWeight: isToday
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: const Color(0xFF22C55E), label: 'Clean'),
            const SizedBox(width: 16),
            _LegendItem(color: const Color(0xFFEF4444), label: 'Relapse'),
            const SizedBox(width: 16),
            _LegendItem(color: const Color(0xFF4F8EF7), label: 'Today'),
          ],
        ),
      ],
    );
  }

  String _monthLabel(DateTime dt) {
    const months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

class _LegendItem extends StatelessWidget {
  final Color  color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
