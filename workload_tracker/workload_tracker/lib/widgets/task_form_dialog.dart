import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/task.dart';
import '../providers/app_providers.dart';

/// Shows the add/edit task dialog. Pass [existing] to edit.
Future<void> showTaskFormDialog(
  BuildContext context,
  WidgetRef ref, {
  Task? existing,
  String? initialCategoryId,
}) async {
  final categories = ref.read(categoriesProvider).valueOrNull ?? [];
  if (categories.isEmpty) return;

  await showDialog(
    context: context,
    builder: (_) => _TaskFormDialog(
      existing: existing,
      initialCategoryId: initialCategoryId,
    ),
  );
}

class _TaskFormDialog extends ConsumerStatefulWidget {
  final Task? existing;
  final String? initialCategoryId;
  const _TaskFormDialog({this.existing, this.initialCategoryId});

  @override
  ConsumerState<_TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends ConsumerState<_TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ownerCtrl;
  String? _categoryId;
  String? _projectId;
  Priority _priority = Priority.medium;
  TaskStatus _status = TaskStatus.notStarted;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _ownerCtrl = TextEditingController(text: t?.owner ?? '');
    _categoryId = t?.categoryId ?? widget.initialCategoryId;
    _projectId = t?.projectId;
    _priority = t?.priority ?? Priority.medium;
    _status = t?.status ?? TaskStatus.notStarted;
    _dueDate = t?.dueDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final allProjects = ref.watch(projectsProvider).valueOrNull ?? [];
    final projectsForCategory =
        allProjects.where((p) => p.categoryId == _categoryId).toList();

    if (_categoryId != null &&
        _projectId != null &&
        !projectsForCategory.any((p) => p.id == _projectId)) {
      _projectId = null;
    }

    final isEditing = widget.existing != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEditing ? 'Edit Task' : 'New Task',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Task name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                    autofocus: true,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _categoryId,
                          decoration:
                              const InputDecoration(labelText: 'Category'),
                          items: [
                            for (final c in categories)
                              DropdownMenuItem(value: c.id, child: Text(c.name)),
                          ],
                          onChanged: (v) => setState(() {
                            _categoryId = v;
                            _projectId = null;
                          }),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _projectId,
                          decoration:
                              const InputDecoration(labelText: 'Project'),
                          items: [
                            for (final p in projectsForCategory)
                              DropdownMenuItem(value: p.id, child: Text(p.name)),
                          ],
                          onChanged: _categoryId == null
                              ? null
                              : (v) => setState(() => _projectId = v),
                          validator: (v) => v == null ? 'Required' : null,
                          hint: Text(_categoryId == null
                              ? 'Pick category first'
                              : 'Select'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _ownerCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Owner / team'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Priority>(
                          initialValue: _priority,
                          decoration:
                              const InputDecoration(labelText: 'Priority'),
                          items: [
                            for (final p in Priority.values)
                              DropdownMenuItem(value: p, child: Text(p.label)),
                          ],
                          onChanged: (v) =>
                              setState(() => _priority = v ?? _priority),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<TaskStatus>(
                          initialValue: _status,
                          decoration:
                              const InputDecoration(labelText: 'Status'),
                          items: [
                            for (final s in TaskStatus.values)
                              DropdownMenuItem(value: s, child: Text(s.label)),
                          ],
                          onChanged: (v) =>
                              setState(() => _status = v ?? _status),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _dueDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Due date'),
                      child: Row(
                        children: [
                          Text(_dueDate == null
                              ? 'None'
                              : DateFormat.yMMMd().format(_dueDate!)),
                          const Spacer(),
                          if (_dueDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => setState(() => _dueDate = null),
                            ),
                          const Icon(Icons.calendar_today_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _submit,
                        child: Text(isEditing ? 'Save' : 'Add Task'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(taskRepositoryProvider);

    if (widget.existing == null) {
      await repo.addTask(
        name: _nameCtrl.text.trim(),
        categoryId: _categoryId!,
        projectId: _projectId!,
        owner: _ownerCtrl.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
        status: _status,
      );
    } else {
      await repo.updateTask(
        widget.existing!,
        (t) => t.copyWith(
          name: _nameCtrl.text.trim(),
          categoryId: _categoryId,
          projectId: _projectId,
          owner: _ownerCtrl.text.trim(),
          priority: _priority,
          status: _status,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }
}
