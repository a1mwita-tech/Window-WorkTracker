import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../models/task.dart';
import 'seed_data.dart';

class HiveBoxes {
  static const categories = 'categories';
  static const projects = 'projects';
  static const tasks = 'tasks';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(ProjectAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(PriorityAdapter());
    Hive.registerAdapter(TaskStatusAdapter());

    await Hive.openBox<Category>(categories);
    await Hive.openBox<Project>(projects);
    await Hive.openBox<Task>(tasks);

    final catBox = Hive.box<Category>(categories);
    if (catBox.isEmpty) {
      final seed = buildSeedData();
      final projBox = Hive.box<Project>(projects);
      for (final c in seed.categories) {
        await catBox.put(c.id, c);
      }
      for (final p in seed.projects) {
        await projBox.put(p.id, p);
      }
    }
  }
}
