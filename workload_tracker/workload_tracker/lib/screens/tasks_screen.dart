import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/task.dart';
import '../providers/app_providers.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_dialog.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(taskFiltersProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final allProjects = ref.watch(projectsProvider).valueOrNull ?? [];
    final List<Project> projectsForCategory = filters.categoryId == null
        ? <Project>[]
        : allProjects.where((p) => p.categoryId == filters.categoryId).toList();
    final tasks = ref.watch(filteredTasksProvider);
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter row — kept as a compact horizontal bar under the header,
          // not a sidebar.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search tasks or owner',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                  ),
                  onChanged: (v) => ref
                      .read(taskFiltersProvider.notifier)
                      .state = filters.copyWith(search: v),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: filters.categoryId,
                  decoration: const InputDecoration(
                    hintText: 'All categories',
                    isDense: true,
                  ),
                  items: [
                    for (final c in categories)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => ref.read(taskFiltersProvider.notifier).state =
                      filters.copyWith(
                    categoryId: v,
                    clearCategory: v == null,
                    clearProject: true,
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: filters.projectId,
                  decoration: const InputDecoration(
                    hintText: 'All projects',
                    isDense: true,
                  ),
                  items: [
                    for (final p in projectsForCategory)
                      DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ],
                  onChanged: filters.categoryId == null
                      ? null
                      : (v) => ref.read(taskFiltersProvider.notifier).state =
                          filters.copyWith(projectId: v, clearProject: v == null),
                ),
              ),
              FilterChip(
                label: const Text('Show Done'),
                selected: filters.showDone,
                onSelected: (v) => ref.read(taskFiltersProvider.notifier).state =
                    filters.copyWith(showDone: v),
              ),
              TextButton.icon(
                onPressed: () => _showArchive(context, ref),
                icon: const Icon(Icons.archive_rounded, size: 18),
                label: const Text('Archive'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks match these filters.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: tasks.length,
                    itemBuilder: (context, i) {
                      final t = tasks[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Dismissible(
                          key: ValueKey(t.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.archive_rounded,
                                color: Colors.orange),
                          ),
                          confirmDismiss: (_) async {
                            await ref
                                .read(taskRepositoryProvider)
                                .setArchived(t, true);
                            return false; // list updates via provider
                          },
                          child: TaskCard(
                            task: t,
                            urgencyScore:
                                t.status == TaskStatus.done ? null : t.urgency(now),
                            onTap: () =>
                                showTaskFormDialog(context, ref, existing: t),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showArchive(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ArchiveSheet(),
    );
  }
}

class _ArchiveSheet extends ConsumerWidget {
  const _ArchiveSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archived = ref.watch(archivedTasksProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Archived Tasks',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '${archived.length} archived · hidden from Daily Review and Tasks',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: archived.isEmpty
                  ? const Center(child: Text('Nothing archived yet.'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: archived.length,
                      itemBuilder: (context, i) {
                        final t = archived[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(t.name),
                          subtitle: Text(t.owner),
                          trailing: OutlinedButton(
                            onPressed: () => ref
                                .read(taskRepositoryProvider)
                                .setArchived(t, false),
                            child: const Text('Unarchive'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
