import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_shell.dart';
import 'data/hive_boxes.dart';
import 'providers/app_providers.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();
  runApp(const ProviderScope(child: WorkloadApp()));
}

class WorkloadApp extends ConsumerWidget {
  const WorkloadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkOverride = ref.watch(darkModeOverrideProvider);

    return MaterialApp(
      title: 'Workload',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: darkOverride == null
          ? ThemeMode.system
          : (darkOverride ? ThemeMode.dark : ThemeMode.light),
      home: const AppShell(),
    );
  }
}
