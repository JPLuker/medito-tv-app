import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(widget.borderRadius);

    return FocusableActionDetector(
      autofocus: widget.autofocus,
      onShowFocusHighlight: (focused) {
        if (_focused != focused) setState(() => _focused = focused);
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
        scale: _focused ? 1.035 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _focused
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : theme.cardColor,
            borderRadius: radius,
            border: Border.all(
              color: _focused
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.25),
              width: _focused ? 3 : 1,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.22),
                      blurRadius: 18,
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
