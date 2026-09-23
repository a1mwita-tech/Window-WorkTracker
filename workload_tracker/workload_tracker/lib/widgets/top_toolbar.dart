import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

const tabTitles = ['Daily Review', 'Tasks', 'Lists', 'How to Use'];

/// A single blurred, translucent horizontal header holding: app title,
/// section switcher, and the primary action for the active section.
/// Everything that used to live in a right-hand rail lives here now.
class TopToolbar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;
  final IconData? primaryActionIcon;

  const TopToolbar({
    super.key,
    this.onPrimaryAction,
    this.primaryActionLabel,
    this.primaryActionIcon,
  });

  @override
  Size get preferredSize => const Size.fromHeight(112);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final darkOverride = ref.watch(darkModeOverrideProvider);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 720;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              compact ? 16 : 24, 12, compact ? 16 : 24, 10),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .scaffoldBackgroundColor
                .withValues(alpha: 0.75),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accentBlue, Color(0xFF5E5CE6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.bolt_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Workload',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: darkOverride == true
                          ? 'Switch to light mode'
                          : 'Switch to dark mode',
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                      ),
                      onPressed: () {
                        ref.read(darkModeOverrideProvider.notifier).state =
                            !isDark;
                      },
                    ),
                    if (onPrimaryAction != null) ...[
                      const SizedBox(width: 4),
                      FilledButton.icon(
                        onPressed: onPrimaryAction,
                        icon: Icon(primaryActionIcon ?? Icons.add_rounded,
                            size: 18),
                        label: Text(primaryActionLabel ?? 'New'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<int>(
                      segments: [
                        for (int i = 0; i < tabTitles.length; i++)
                          ButtonSegment(
                            value: i,
                            label: Text(tabTitles[i]),
                          ),
                      ],
                      selected: {selectedTab},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => ref
                          .read(selectedTabProvider.notifier)
                          .state = s.first,
                    ),
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
