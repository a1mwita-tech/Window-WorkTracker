import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        Text(
          'How to Use Workload',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        const _GuideSection(
          icon: Icons.wb_sunny_rounded,
          color: AppColors.accentBlue,
          title: 'Daily Review',
          body:
              'Your morning dashboard. Shows today\'s date, counts of open, '
              'overdue, and due-today tasks, and your Top 30 tasks ranked by '
              'urgency — most urgent first. Anything marked Done drops off '
              'automatically.',
        ),
        _GuideSection(
          icon: Icons.checklist_rounded,
          color: AppColors.systemGreen,
          title: 'Tasks',
          body: 'Your main work area. Add a task by choosing a Category, '
              'then a Project (the list filters to that category), plus a '
              'name, owner/team, priority, due date, and status. '
              'Overdue tasks show red, due-today shows yellow, and Done '
              'tasks are greyed out.',
        ),
        const _GuideSection(
          icon: Icons.folder_copy_rounded,
          color: Color(0xFFB8860B),
          title: 'Lists',
          body: 'Manage your Categories and Projects here. Add a new '
              'project or client directly under any category.',
        ),
        const _GuideSection(
          icon: Icons.bolt_rounded,
          color: AppColors.accentBlue,
          title: 'Urgency Scoring',
          body: 'Urgency = Priority points + Deadline points.\n'
              'Priority — High: 30, Medium: 20, Low: 10.\n'
              'Deadline — Overdue: +40, Due today: +35, Due within 3 days: +20.\n\n'
              'This means an overdue Low-priority task (10 + 40 = 50) can '
              'outrank a High-priority task with no deadline (30 + 0 = 30) — '
              'that\'s intentional, so nothing urgent slips through.',
        ),
        const _GuideSection(
          icon: Icons.archive_rounded,
          color: Colors.orange,
          title: 'Archive',
          body: 'Swipe a task left, or open it, to archive it manually. '
              'Tasks marked Done for 30+ days archive automatically. '
              'Archived tasks are hidden from Daily Review and Tasks, but '
              'you can view and Unarchive them from the Archive button on '
              'the Tasks screen.',
        ),
        const _GuideSection(
          icon: Icons.keyboard_rounded,
          color: Colors.purple,
          title: 'Shortcuts (desktop)',
          body: 'Cmd/Ctrl + N — new task\n'
              'Cmd/Ctrl + 1–4 — switch between Daily Review, Tasks, Lists, '
              'How to Use\n'
              'Cmd/Ctrl + F — focus search on the Tasks screen',
        ),
      ],
    );
  }
}

class _GuideSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _GuideSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.75),
                    height: 1.4,
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
