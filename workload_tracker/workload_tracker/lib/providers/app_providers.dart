import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/hive_boxes.dart';
import '../models/category.dart';
import '../models/task.dart';

const _uuid = Uuid();

/// A tick that providers can watch to force re-evaluation after any
/// write (Hive's ValueListenable already does this per-box, but this
/// keeps cross-box derived providers — like urgency ranking — in sync).
final _categoryBoxProvider = Provider<Box<Category>>(
  (ref) => Hive.box<Category>(HiveBoxes.categories),
);
final _projectBoxProvider = Provider<Box<Project>>(
  (ref) => Hive.box<Project>(HiveBoxes.projects),
);
final _taskBoxProvider = Provider<Box<Task>>(
  (ref) => Hive.box<Task>(HiveBoxes.tasks),
);

final categoriesProvider = StreamProvider<List<Category>>((ref) async* {
  final box = ref.watch(_categoryBoxProvider);
  List<Category> snapshot() =>
      box.values.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  yield snapshot();
  await for (final _ in box.watch()) {
    yield snapshot();
  }
});

final projectsProvider = StreamProvider<List<Project>>((ref) async* {
  final box = ref.watch(_projectBoxProvider);
  List<Project> snapshot() => box.values.toList();
  yield snapshot();
  await for (final _ in box.watch()) {
    yield snapshot();
  }
});

/// Raw tasks stream — also runs the auto-archive sweep on every emission
/// so "Done 30+ days ago" tasks silently fall out of active views.
final tasksProvider = StreamProvider<List<Task>>((ref) async* {
  final box = ref.watch(_taskBoxProvider);

  List<Task> snapshotAndSweep() {
    final now = DateTime.now();
    for (final t in box.values) {
      if (!t.archived && t.shouldAutoArchive(now)) {
        t.archived = true;
        t.save();
      }
    }
    return box.values.toList();
  }

  yield snapshotAndSweep();
  await for (final _ in box.watch()) {
    yield snapshotAndSweep();
  }
});

/// Active (non-archived) tasks only — feeds Tasks view and Daily Review.
final activeTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
  return tasks.where((t) => !t.archived).toList();
});

final archivedTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
  return tasks.where((t) => t.archived).toList();
});

class DailyReviewData {
  final int openCount;
  final int overdueCount;
  final int dueTodayCount;
  final List<Task> top30;
  DailyReviewData({
    required this.openCount,
    required this.overdueCount,
    required this.dueTodayCount,
    required this.top30,
  });
}

/// Daily Review: open tasks (not Done, not archived) ranked by urgency,
/// most urgent first. Done tasks drop off automatically since they're
/// excluded here.
final dailyReviewProvider = Provider<DailyReviewData>((ref) {
  final now = DateTime.now();
  final active = ref
      .watch(activeTasksProvider)
      .where((t) => t.status != TaskStatus.done)
      .toList();

  final overdue =
      active.where((t) => t.deadlineState(now) == DeadlineState.overdue);
  final dueToday =
      active.where((t) => t.deadlineState(now) == DeadlineState.dueToday);

  final ranked = [...active]
    ..sort((a, b) => b.urgency(now).compareTo(a.urgency(now)));

  return DailyReviewData(
    openCount: active.length,
    overdueCount: overdue.length,
    dueTodayCount: dueToday.length,
    top30: ranked.take(30).toList(),
  );
});

/// Repository: all writes go through here.
class TaskRepository {
  final Box<Task> _taskBox;
  final Box<Category> _catBox;
  final Box<Project> _projBox;

  TaskRepository(this._taskBox, this._catBox, this._projBox);

  Future<void> addTask({
    required String name,
    required String categoryId,
    required String projectId,
    required String owner,
    required Priority priority,
    DateTime? dueDate,
    required TaskStatus status,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      name: name,
      categoryId: categoryId,
      projectId: projectId,
      owner: owner,
      priority: priority,
      dueDate: dueDate,
      status: status,
      doneDate: status == TaskStatus.done ? DateTime.now() : null,
      createdAt: DateTime.now(),
    );
    await _taskBox.put(task.id, task);
  }

  Future<void> updateTask(Task task, Task Function(Task) updater) async {
    final updated = updater(task);
    // If status just changed to Done, stamp doneDate; if moved off Done,
    // clear it so auto-archive timing resets correctly.
    if (updated.status == TaskStatus.done && task.status != TaskStatus.done) {
      updated.doneDate = DateTime.now();
    } else if (updated.status != TaskStatus.done) {
      updated.doneDate = null;
    }
    await _taskBox.put(updated.id, updated);
  }

  Future<void> setArchived(Task task, bool archived) async {
    task.archived = archived;
    await task.save();
  }

  Future<void> deleteTask(Task task) async {
    await task.delete();
  }

  Future<void> addCategory(String name) async {
    final order = _catBox.values.length;
    final cat = Category(id: _uuid.v4(), name: name, sortOrder: order);
    await _catBox.put(cat.id, cat);
  }

  Future<void> addProject(String name, String categoryId) async {
    final proj = Project(id: _uuid.v4(), name: name, categoryId: categoryId);
    await _projBox.put(proj.id, proj);
  }

  Future<void> renameCategory(Category cat, String newName) async {
    cat.name = newName;
    await cat.save();
  }

  Future<void> renameProject(Project proj, String newName) async {
    proj.name = newName;
    await proj.save();
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(
    ref.watch(_taskBoxProvider),
    ref.watch(_categoryBoxProvider),
    ref.watch(_projectBoxProvider),
  );
});

/// UI state: selected tab, dark-mode override, and Tasks-view filters.
final darkModeOverrideProvider = StateProvider<bool?>((ref) => null);
final selectedTabProvider = StateProvider<int>((ref) => 0);

class TaskFilters {
  final String? categoryId;
  final String? projectId;
  final bool showDone;
  final String search;
  const TaskFilters({
    this.categoryId,
    this.projectId,
    this.showDone = true,
    this.search = '',
  });

  TaskFilters copyWith({
    String? categoryId,
    bool clearCategory = false,
    String? projectId,
    bool clearProject = false,
    bool? showDone,
    String? search,
  }) {
    return TaskFilters(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      projectId: clearProject ? null : (projectId ?? this.projectId),
      showDone: showDone ?? this.showDone,
      search: search ?? this.search,
    );
  }
}

final taskFiltersProvider =
    StateProvider<TaskFilters>((ref) => const TaskFilters());

final filteredTasksProvider = Provider<List<Task>>((ref) {
  final filters = ref.watch(taskFiltersProvider);
  final now = DateTime.now();
  var tasks = ref.watch(activeTasksProvider);

  if (filters.categoryId != null) {
    tasks = tasks.where((t) => t.categoryId == filters.categoryId).toList();
  }
  if (filters.projectId != null) {
    tasks = tasks.where((t) => t.projectId == filters.projectId).toList();
  }
  if (!filters.showDone) {
    tasks = tasks.where((t) => t.status != TaskStatus.done).toList();
  }
  if (filters.search.trim().isNotEmpty) {
    final q = filters.search.toLowerCase();
    tasks = tasks
        .where((t) =>
            t.name.toLowerCase().contains(q) ||
            t.owner.toLowerCase().contains(q))
        .toList();
  }

  tasks.sort((a, b) => b.urgency(now).compareTo(a.urgency(now)));
  return tasks;
});
