import 'package:uuid/uuid.dart';
import '../models/category.dart';

const _uuid = Uuid();

/// Pre-loaded categories and projects, exactly as specified.
/// Each entry: category name -> list of project/client names.
/// Categories with no listed sub-projects (Internal Requests, Pending
/// Confirmation, Billing, Teams) still get a category row so tasks can be
/// filed directly under them; the Lists screen lets you add projects later.
final Map<String, List<String>> seedStructure = {
  'Subtitles': ['Giant Creatives', 'Euphoria 360', 'Inkblot'],
  'Dubbing': [
    'Zacu TV series/movies',
    'BBC',
    'Iyuno–Disney',
    'Zee TV',
    'Arewa 24',
    'Avante',
    'Dambe',
  ],
  'Internal Requests': [],
  'Pending Confirmation': [],
  'Billing': [],
  'Teams': [],
};

class SeedResult {
  final List<Category> categories;
  final List<Project> projects;
  SeedResult(this.categories, this.projects);
}

SeedResult buildSeedData() {
  final categories = <Category>[];
  final projects = <Project>[];
  int order = 0;
  seedStructure.forEach((catName, projectNames) {
    final cat = Category(id: _uuid.v4(), name: catName, sortOrder: order++);
    categories.add(cat);
    for (final p in projectNames) {
      projects.add(Project(id: _uuid.v4(), name: p, categoryId: cat.id));
    }
  });
  return SeedResult(categories, projects);
}
