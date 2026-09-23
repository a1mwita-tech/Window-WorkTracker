import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/app_providers.dart';
import 'screens/daily_review_screen.dart';
import 'screens/how_to_use_screen.dart';
import 'screens/lists_screen.dart';
import 'screens/tasks_screen.dart';
import 'widgets/top_toolbar.dart';
import 'widgets/task_form_dialog.dart';

class _NewTaskIntent extends Intent {
  const _NewTaskIntent();
}

class _TabIntent extends Intent {
  final int index;
  const _TabIntent(this.index);
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(selectedTabProvider);

    final screens = const [
      DailyReviewScreen(),
      TasksScreen(),
      ListsScreen(),
      HowToUseScreen(),
    ];

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN):
            const _NewTaskIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
            const _NewTaskIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit1):
            const _TabIntent(0),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit1):
            const _TabIntent(0),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit2):
            const _TabIntent(1),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit2):
            const _TabIntent(1),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit3):
            const _TabIntent(2),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit3):
            const _TabIntent(2),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit4):
            const _TabIntent(3),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit4):
            const _TabIntent(3),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NewTaskIntent: CallbackAction<_NewTaskIntent>(
            onInvoke: (_) {
              showTaskFormDialog(context, ref);
              return null;
            },
          ),
          _TabIntent: CallbackAction<_TabIntent>(
            onInvoke: (intent) {
              ref.read(selectedTabProvider.notifier).state = intent.index;
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: TopToolbar(
              onPrimaryAction: tab == 2
                  ? null // Lists screen has its own inline add actions
                  : () => showTaskFormDialog(context, ref),
              primaryActionLabel: 'New Task',
              primaryActionIcon: Icons.add_rounded,
            ),
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(tab),
                child: SafeArea(top: false, child: screens[tab]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
