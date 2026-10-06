import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Focusable surface used across the Android TV UI.
///
/// The styling intentionally mirrors Medito's current monochrome tablet/foldable
/// surfaces: selection is expressed with the on-surface colour, while TV adds a
/// stronger outline and a small scale lift so focus remains unambiguous at ten
/// feet.
class TvFocusCard extends StatefulWidget {
  const TvFocusCard({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderRadius = 16,
    this.autofocus = false,
    this.padding,
  });

  final VoidCallback onPressed;
  final Widget child;
  final double borderRadius;
  final bool autofocus;
  final EdgeInsetsGeometry? padding;

  @override
  State<TvFocusCard> createState() => _TvFocusCardState();
}

class _TvFocusCardState extends State<TvFocusCard> {
  bool _focused = false;

  void _handleFocus(bool focused) {
    if (_focused != focused) setState(() => _focused = focused);
    if (!focused) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: 0.5,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(widget.borderRadius);
    final onSurface = theme.colorScheme.onSurface;

    return FocusableActionDetector(
      autofocus: widget.autofocus,
      onShowFocusHighlight: _handleFocus,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed();
            return null;
          },
        ),
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _focused ? 1.025 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _focused
                ? onSurface.withValues(alpha: 0.11)
                : theme.cardColor,
            borderRadius: radius,
            border: Border.all(
              color: _focused
                  ? onSurface.withValues(alpha: 0.86)
                  : theme.colorScheme.outline.withValues(alpha: 0.22),
              width: _focused ? 3 : 1,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: onSurface.withValues(alpha: 0.12),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                canRequestFocus: false,
                onTap: widget.onPressed,
                child: Padding(
                  padding: widget.padding ?? EdgeInsets.zero,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
