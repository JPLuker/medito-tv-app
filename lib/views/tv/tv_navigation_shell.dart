import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medito/views/tv/tv_explore_view.dart';
import 'package:medito/views/tv/tv_home_view.dart';
import 'package:medito/views/tv/tv_search_view.dart';
import 'package:medito/views/tv/tv_settings_view.dart';

/// Android TV navigation intentionally mirrors Medito's iPad sidebar: a
/// compact rail with Home, Explore, Search and Settings. TV adds an explicit
/// focus outline and D-pad transitions, but does not invent extra destinations.
class TvNavigationShell extends StatefulWidget {
  const TvNavigationShell({super.key});

  @override
  State<TvNavigationShell> createState() => _TvNavigationShellState();
}

class _TvNavigationShellState extends State<TvNavigationShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    TvHomeView(),
    TvExploreView(),
    TvSearchView(),
    TvSettingsView(),
  ];

  void _select(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectedIndex != 0) _select(0);
      },
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: Scaffold(
          body: Row(
            children: [
              Material(
                color: theme.scaffoldBackgroundColor,
                child: SafeArea(
                  right: false,
                  child: SizedBox(
                    width: 116,
                    height: double.infinity,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 26,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TvSidebarItem(
                            icon: Icons.home_outlined,
                            selectedIcon: Icons.home_rounded,
                            label: 'Home',
                            selected: _selectedIndex == 0,
                            autofocus: true,
                            onPressed: () => _select(0),
                          ),
                          _TvSidebarItem(
                            icon: Icons.menu_book_outlined,
                            selectedIcon: Icons.menu_book_rounded,
                            label: 'Explore',
                            selected: _selectedIndex == 1,
                            onPressed: () => _select(1),
                          ),
                          _TvSidebarItem(
                            icon: Icons.search_rounded,
                            selectedIcon: Icons.search_rounded,
                            label: 'Search',
                            selected: _selectedIndex == 2,
                            onPressed: () => _select(2),
                          ),
                          const SizedBox(height: 12),
                          _TvSidebarItem(
                            icon: Icons.settings_outlined,
                            selectedIcon: Icons.settings_rounded,
                            label: 'Settings',
                            selected: _selectedIndex == 3,
                            onPressed: () => _select(3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                key: const ValueKey('tv-main-content'),
                child: IndexedStack(index: _selectedIndex, children: _pages),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TvSidebarItem extends StatefulWidget {
  const _TvSidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.autofocus = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final bool autofocus;

  @override
  State<_TvSidebarItem> createState() => _TvSidebarItemState();
}

class _TvSidebarItemState extends State<_TvSidebarItem> {
  bool _focused = false;

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.space) {
      widget.onPressed();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      FocusScope.of(context).focusInDirection(TraversalDirection.right);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final active = widget.selected || _focused;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Focus(
        autofocus: widget.autofocus,
        onKeyEvent: _onKeyEvent,
        onFocusChange: (focused) {
          if (_focused != focused) setState(() => _focused = focused);
        },
        child: AnimatedScale(
          scale: _focused ? 1.035 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: _focused
                  ? onSurface.withValues(alpha: 0.14)
                  : widget.selected
                  ? onSurface.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _focused
                    ? onSurface.withValues(alpha: 0.90)
                    : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: InkWell(
              canRequestFocus: false,
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 15,
                ),
                child: Column(
                  children: [
                    Icon(
                      widget.selected ? widget.selectedIcon : widget.icon,
                      size: 30,
                      color: active
                          ? onSurface
                          : onSurface.withValues(alpha: 0.70),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active
                            ? onSurface
                            : onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
