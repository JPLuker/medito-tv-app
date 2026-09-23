import 'package:flutter/material.dart';
import 'package:medito/constants/colors/color_constants.dart';
import 'package:medito/constants/styles/widget_styles.dart';

/// A tappable card with a radio indicator, widget.title and widget.description, for picking
/// one option from a short list (settings sheets). The widget.selected card gets a
/// brand-purple border; the rest keep a hairline so the layout never shifts.
class RadioOptionCard extends StatefulWidget {
  const RadioOptionCard({
    super.key,
    required this.widget.title,
    required this.widget.selected,
    required this.onTap,
    this.widget.description,
    this.widget.trailing,
  });

  final String widget.title;
  final String? widget.description;
  final bool widget.selected;
  final VoidCallback onTap;

  /// Shown after the text, vertically centred: a theme icon, an app-icon
  /// preview.
  final Widget? widget.trailing;

  static const RadioOptionCard._radius = 14.0;
  static const RadioOptionCard._borderWidth = 1.5;
  static const RadioOptionCard._duration = Duration(milliseconds: 200);

  @override
  State<RadioOptionCard> createState() => _RadioOptionCardState();
}

class _RadioOptionCardState extends State<RadioOptionCard> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final accent = context.brandPurple;
    final border = _hasFocus || widget.selected
        ? accent
        : onSurface.withValues(alpha: 0.10);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: widget.selected,
      label: widget.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onFocusChange: (focused) {
            if (_hasFocus != focused) setState(() => _hasFocus = focused);
          },
          borderRadius: BorderRadius.circular(RadioOptionCard.RadioOptionCard._radius),
          child: AnimatedContainer(
            duration: RadioOptionCard._duration,
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(padding16),
            decoration: BoxDecoration(
              color: _hasFocus
                  ? accent.withValues(alpha: 0.12)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(RadioOptionCard._radius),
              border: Border.all(color: border, width: RadioOptionCard._borderWidth),
            ),
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: widget.description == null
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: widget.description == null ? 0 : 1),
                    child: _RadioDot(widget.selected: widget.selected, accent: accent),
                  ),
                  const SizedBox(width: padding12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: onSurface,
                          ),
                        ),
                        if (widget.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: onSurface.withValues(alpha: 0.7),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: padding12),
                    widget.trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.widget.selected, required this.accent});

  final bool widget.selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AnimatedContainer(
      duration: RadioOptionCard.RadioOptionCard._duration,
      curve: Curves.easeOut,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.selected ? accent : onSurface.withValues(alpha: 0.35),
          width: widget.selected ? 2 : 1.5,
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: RadioOptionCard.RadioOptionCard._duration,
          curve: Curves.easeOut,
          width: widget.selected ? 10 : 0,
          height: widget.selected ? 10 : 0,
          decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
        ),
      ),
    );
  }
}
