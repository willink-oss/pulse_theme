import 'package:flutter/material.dart';

/// Material 3 brand-aware tab bar.
///
/// Mirrors the React DS `Tabs` compound (`<Tabs><TabsList><TabsTrigger/>...`)
/// as a thin wrapper over Material 3 [TabBar]:
/// ```dart
/// DefaultTabController(
///   length: 2,
///   child: Scaffold(
///     appBar: AppBar(
///       title: const Text('設定'),
///       bottom: const PulseTabBar(
///         tabs: [
///           Tab(text: 'アカウント'),
///           Tab(text: 'パスワード'),
///         ],
///       ),
///     ),
///     body: const TabBarView(children: [AccountForm(), PasswordForm()]),
///   ),
/// )
/// ```
///
/// Colors derive from `Theme.of(context).colorScheme` (indicator + selected
/// label = primary, unselected label = onSurfaceVariant, divider =
/// outlineVariant) so the tab bar follows any brand the consumer configures
/// via `copyWith(colorScheme: ...)` automatically.
///
/// Tab selection state lives in a [TabController] — pass one via [controller]
/// or rely on an ancestor [DefaultTabController], exactly like [TabBar].
/// Implements [PreferredSizeWidget] so it slots into [AppBar.bottom].
class PulseTabBar extends StatelessWidget implements PreferredSizeWidget {
  const PulseTabBar({
    required this.tabs,
    super.key,
    this.controller,
    this.onTap,
    this.isScrollable = false,
  });

  /// Tab widgets, typically [Tab] instances. Passed straight through to
  /// [TabBar.tabs] — length must match the controller's `length`.
  final List<Widget> tabs;

  /// Selection state owner. When `null`, the nearest [DefaultTabController]
  /// ancestor is used (same contract as [TabBar.controller]).
  final TabController? controller;

  /// Called with the index of the tapped tab, in addition to the default
  /// switching behavior.
  final ValueChanged<int>? onTap;

  /// Whether the tab bar can scroll horizontally. Defaults to `false`
  /// (tabs share the available width equally).
  final bool isScrollable;

  /// Matches [TabBar.preferredSize] for the given [tabs] so the widget can
  /// be used directly as [AppBar.bottom].
  @override
  Size get preferredSize => TabBar(tabs: tabs).preferredSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TabBar(
      controller: controller,
      tabs: tabs,
      onTap: onTap,
      isScrollable: isScrollable,
      indicatorColor: colors.primary,
      labelColor: colors.primary,
      unselectedLabelColor: colors.onSurfaceVariant,
      dividerColor: colors.outlineVariant,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
