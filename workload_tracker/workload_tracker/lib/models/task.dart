import 'package:hive/hive.dart';

/// Priority levels. Point values are part of the urgency formula —
/// do not change without updating the product's scoring rules.
enum Priority { high, medium, low }

extension PriorityX on Priority {
  int get points {
    switch (this) {
      case Priority.high:
        return 30;
      case Priority.medium:
        return 20;
      case Priority.low:
        return 10;
    }
  }

  String get label {
    switch (this) {
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Medium';
      case Priority.low:
        return 'Low';
    }
  }
}

enum TaskStatus { notStarted, inProgress, blocked, done }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.notStarted:
        return 'Not Started';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.blocked:
        return 'Blocked';
      case TaskStatus.done:
        return 'Done';
    }
  }
}

class Task extends HiveObject {
  String id;
  String name;
  String categoryId;
  String projectId;
  String owner;
  Priority priority;
  DateTime? dueDate;
  TaskStatus status;
  bool archived;
  DateTime? doneDate;
  DateTime createdAt;

  Task({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.projectId,
    required this.owner,
    required this.priority,
    required this.dueDate,
    required this.status,
    this.archived = false,
    this.doneDate,
    required this.createdAt,
  });

  /// Deadline classification relative to [now] (date-only comparison).
  DeadlineState deadlineState(DateTime now) {
    if (dueDate == null) return DeadlineState.none;
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final diff = due.difference(today).inDays;
    if (diff < 0) return DeadlineState.overdue;
    if (diff == 0) return DeadlineState.dueToday;
    if (diff <= 3) return DeadlineState.dueSoon;
    return DeadlineState.none;
  }

  /// Urgency = Priority points + Deadline points.
  /// Priority: High=30, Medium=20, Low=10.
  /// Deadline: Overdue=+40, Due today=+35, Due within 3 days=+20.
  /// This is intentional: an overdue Low task can outrank a High task
  /// with no deadline (10 + 40 = 50 > 30 + 0 = 30).
  int urgency(DateTime now) {
    int score = priority.points;
    switch (deadlineState(now)) {
      case DeadlineState.overdue:
        score += 40;
        break;
      case DeadlineState.dueToday:
        score += 35;
        break;
      case DeadlineState.dueSoon:
        score += 20;
        break;
      case DeadlineState.none:
        break;
    }
    return score;
  }

  bool get isDone => status == TaskStatus.done;

  /// Auto-archive rule: Done 30+ days ago.
  bool shouldAutoArchive(DateTime now) {
    if (!isDone || doneDate == null) return false;
    return now.difference(doneDate!).inDays >= 30;
  }

  Task copyWith({
    String? name,
    String? categoryId,
    String? projectId,
    String? owner,
    Priority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    TaskStatus? status,
    bool? archived,
    DateTime? doneDate,
    bool clearDoneDate = false,
  }) {
    return Task(
      id: id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      projectId: projectId ?? this.projectId,
      owner: owner ?? this.owner,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      status: status ?? this.status,
      archived: archived ?? this.archived,
      doneDate: clearDoneDate ? null : (doneDate ?? this.doneDate),
      createdAt: createdAt,
    );
  }
}

enum DeadlineState { none, dueSoon, dueToday, overdue }

// ---------- Hive Adapters (manual — no build_runner needed) ----------

class PriorityAdapter extends TypeAdapter<Priority> {
  @override
  final int typeId = 10;

  @override
  Priority read(BinaryReader reader) => Priority.values[reader.readByte()];

  @override
  void write(BinaryWriter writer, Priority obj) =>
      writer.writeByte(obj.index);
}

class TaskStatusAdapter extends TypeAdapter<TaskStatus> {
  @override
  final int typeId = 11;

  @override
  TaskStatus read(BinaryReader reader) => TaskStatus.values[reader.readByte()];

  @override
  void write(BinaryWriter writer, TaskStatus obj) =>
      writer.writeByte(obj.index);
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 2;

  @override
  Task read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      name: fields[1] as String,
      categoryId: fields[2] as String,
      projectId: fields[3] as String,
      owner: fields[4] as String,
      priority: fields[5] as Priority,
      dueDate: fields[6] as DateTime?,
      status: fields[7] as TaskStatus,
      archived: fields[8] as bool,
      doneDate: fields[9] as DateTime?,
      createdAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.projectId)
      ..writeByte(4)
      ..write(obj.owner)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.dueDate)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.archived)
      ..writeByte(9)
      ..write(obj.doneDate)
      ..writeByte(10)
      ..write(obj.createdAt);
  }
}
