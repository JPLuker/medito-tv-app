import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medito/views/tv/tv_explore_view.dart';
import 'package:medito/views/tv/tv_home_view.dart';
import 'package:medito/views/tv/tv_library_view.dart';
import 'package:medito/views/tv/tv_search_view.dart';
import 'package:medito/views/tv/tv_settings_view.dart';

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
    TvLibraryView(),
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
              Container(
                width: 190,
                color: theme.colorScheme.surface,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 22, 14, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 22),
                          child: Text(
                            'Medito',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _TvRailButton(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          selected: _selectedIndex == 0,
                          autofocus: true,
                          onPressed: () => _select(0),
                        ),
                        _TvRailButton(
                          icon: Icons.explore_rounded,
                          label: 'Explore',
                          selected: _selectedIndex == 1,
                          onPressed: () => _select(1),
                        ),
                        _TvRailButton(
                          icon: Icons.search_rounded,
                          label: 'Search',
                          selected: _selectedIndex == 2,
                          onPressed: () => _select(2),
                        ),
                        _TvRailButton(
                          icon: Icons.video_library_rounded,
                          label: 'Library',
                          selected: _selectedIndex == 3,
                          onPressed: () => _select(3),
                        ),
                        const Spacer(),
                        _TvRailButton(
                          icon: Icons.settings_rounded,
                          label: 'Settings',
                          selected: _selectedIndex == 4,
                          onPressed: () => _select(4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.18),
              ),
              Expanded(
                child: IndexedStack(index: _selectedIndex, children: _pages),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TvRailButton extends StatefulWidget {
  const _TvRailButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.autofocus = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final bool autofocus;

  @override
  State<_TvRailButton> createState() => _TvRailButtonState();
}

class _TvRailButtonState extends State<_TvRailButton> {
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
    final active = widget.selected || _focused;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Focus(
        autofocus: widget.autofocus,
        onKeyEvent: _onKeyEvent,
        onFocusChange: (focused) {
          if (_focused != focused) setState(() => _focused = focused);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _focused
                ? theme.colorScheme.primary.withValues(alpha: 0.16)
                : widget.selected
                ? theme.colorScheme.primary.withValues(alpha: 0.09)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            canRequestFocus: false,
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 27,
                    color: active
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.74),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withValues(alpha: 0.76),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
