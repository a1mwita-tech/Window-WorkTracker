import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../providers/app_providers.dart';

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final projects = ref.watch(projectsProvider).valueOrNull ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Categories & Projects',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _addCategoryDialog(context, ref),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New Category'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final cat in categories)
          _CategoryTile(
            category: cat,
            projects: projects.where((p) => p.categoryId == cat.id).toList(),
          ),
      ],
    );
  }

  void _addCategoryDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Category name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(taskRepositoryProvider).addCategory(ctrl.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends ConsumerStatefulWidget {
  final Category category;
  final List<Project> projects;
  const _CategoryTile({required this.category, required this.projects});

  @override
  ConsumerState<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends ConsumerState<_CategoryTile> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.category.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${widget.projects.length} project(s)'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Add project',
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  onPressed: () => _addProjectDialog(context),
                ),
                IconButton(
                  icon: Icon(_expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            for (final p in widget.projects)
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 32, right: 16),
                leading: const Icon(Icons.folder_rounded, size: 18),
                title: Text(p.name),
              ),
          if (_expanded && widget.projects.isEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 32, bottom: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('No projects yet.'),
              ),
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  void _addProjectDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('New Project in ${widget.category.name}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Project or client name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref
                    .read(taskRepositoryProvider)
                    .addProject(ctrl.text.trim(), widget.category.id);
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
