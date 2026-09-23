import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_dialog.dart';

class DailyReviewScreen extends ConsumerWidget {
  const DailyReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dailyReviewProvider);
    final now = DateTime.now();
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width > 900 ? 3 : (width > 560 ? 3 : 1);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Text(
          DateFormat('EEEE, MMMM d').format(now),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Here\'s what needs your attention today.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: crossAxisCount == 1 ? 3.2 : 1.7,
          children: [
            _StatCard(
              label: 'Open Tasks',
              value: data.openCount,
              icon: Icons.inbox_rounded,
              color: AppColors.accentBlue,
            ),
            _StatCard(
              label: 'Overdue',
              value: data.overdueCount,
              icon: Icons.error_rounded,
              color: AppColors.systemRed,
            ),
            _StatCard(
              label: 'Due Today',
              value: data.dueTodayCount,
              icon: Icons.today_rounded,
              color: const Color(0xFFB8860B),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Text(
              'Top ${data.top30.length} by Urgency',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            Text(
              'Most urgent first',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (data.top30.isEmpty)
          const _EmptyState()
        else
          for (final t in data.top30)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TaskCard(
                task: t,
                urgencyScore: t.urgency(now),
                onTap: () => showTaskFormDialog(context, ref, existing: t),
              ),
            ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.check_circle_rounded,
                size: 48,
                color: AppColors.systemGreen.withValues(alpha: 0.8)),
            const SizedBox(height: 12),
            Text(
              'All clear — nothing open right now.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
