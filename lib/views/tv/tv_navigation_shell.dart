import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medito/constants/icons/medito_icons.dart';
import 'package:medito/widgets/medito_icon.dart';
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
                    width: 144,
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
                            assetName: MeditoIcons.home,
                            label: 'Home',
                            selected: _selectedIndex == 0,
                            autofocus: true,
                            onPressed: () => _select(0),
                          ),
                          _TvSidebarItem(
                            assetName: MeditoIcons.book,
                            label: 'Explore',
                            selected: _selectedIndex == 1,
                            onPressed: () => _select(1),
                          ),
                          _TvSidebarItem(
                            assetName: MeditoIcons.search,
                            label: 'Search',
                            selected: _selectedIndex == 2,
                            onPressed: () => _select(2),
                          ),
                          const SizedBox(height: 12),
                          _TvSidebarItem(
                            assetName: MeditoIcons.settings,
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
    required this.assetName,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.autofocus = false,
  });

  final String assetName;
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
                  horizontal: 10,
                  vertical: 18,
                ),
                child: Column(
                  children: [
                    MeditoIcon(
                      assetName: widget.assetName,
                      size: 34,
                      color: active
                          ? onSurface
                          : onSurface.withValues(alpha: 0.74),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      widget.label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        height: 1.1,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active
                            ? onSurface
                            : onSurface.withValues(alpha: 0.78),
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
