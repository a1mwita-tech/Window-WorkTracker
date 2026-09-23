import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/task.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

class TaskCard extends ConsumerWidget {
  final Task task;
  final VoidCallback onTap;
  final int? urgencyScore;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.urgencyScore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final deadline = task.deadlineState(now);
    final isDone = task.status == TaskStatus.done;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color accent;
    String? tagLabel;
    if (isDone) {
      accent = Colors.grey;
    } else if (deadline == DeadlineState.overdue) {
      accent = AppColors.systemRed;
      tagLabel = 'Overdue';
    } else if (deadline == DeadlineState.dueToday) {
      accent = const Color(0xFFB8860B); // legible on both themes
      tagLabel = 'Due today';
    } else {
      accent = AppColors.accentBlue;
    }

    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final projects = ref.watch(projectsProvider).valueOrNull ?? [];
    final categoryName = categories
        .firstWhere(
          (c) => c.id == task.categoryId,
          orElse: () => Category(id: '', name: '—', sortOrder: 0),
        )
        .name;
    final projectName = projects
        .firstWhere(
          (p) => p.id == task.projectId,
          orElse: () => Project(id: '', name: '—', categoryId: ''),
        )
        .name;

    return Opacity(
      opacity: isDone ? 0.55 : 1,
      child: Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (urgencyScore != null && !isDone)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$urgencyScore',
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$categoryName · $projectName',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Pill(text: task.priority.label),
                          _Pill(text: task.owner),
                          if (task.dueDate != null)
                            _Pill(
                              text: DateFormat.MMMd().format(task.dueDate!),
                              color: tagLabel != null ? accent : null,
                            ),
                          if (tagLabel != null)
                            _Pill(text: tagLabel, color: accent, filled: true),
                          if (isDone) const _Pill(text: 'Done'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color? color;
  final bool filled;
  const _Pill({required this.text, this.color, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? c.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: filled ? null : Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.5, color: c, fontWeight: FontWeight.w600),
      ),
    );
  }
}
