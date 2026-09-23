import 'package:flutter/material.dart';
import 'package:medito/constants/colors/color_constants.dart';
import 'package:medito/constants/styles/widget_styles.dart';

/// A tappable card with a radio indicator, title and description, for picking
/// one option from a short list (settings sheets). Focus receives the same
/// brand treatment as selection so remote users always know where they are.
class RadioOptionCard extends StatefulWidget {
  const RadioOptionCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.description,
    this.trailing,
  });

  final String title;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  /// Shown after the text, vertically centred: a theme icon, an app-icon
  /// preview.
  final Widget? trailing;

  static const radius = 14.0;
  static const borderWidth = 1.5;
  static const duration = Duration(milliseconds: 200);

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
    final highlighted = _hasFocus || widget.selected;
    final border = highlighted
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
            if (_hasFocus != focused) {
              setState(() => _hasFocus = focused);
            }
          },
          borderRadius: BorderRadius.circular(RadioOptionCard.radius),
          child: AnimatedContainer(
            duration: RadioOptionCard.duration,
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(padding16),
            decoration: BoxDecoration(
              color: _hasFocus
                  ? accent.withValues(alpha: 0.12)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(RadioOptionCard.radius),
              border: Border.all(
                color: border,
                width: _hasFocus ? 3 : RadioOptionCard.borderWidth,
              ),
            ),
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: widget.description == null
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: widget.description == null ? 0 : 1,
                    ),
                    child: _RadioDot(
                      selected: widget.selected,
                      accent: accent,
                    ),
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
  const _RadioDot({required this.selected, required this.accent});

  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AnimatedContainer(
      duration: RadioOptionCard.duration,
      curve: Curves.easeOut,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? accent : onSurface.withValues(alpha: 0.35),
          width: selected ? 2 : 1.5,
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: RadioOptionCard.duration,
          curve: Curves.easeOut,
          width: selected ? 10 : 0,
          height: selected ? 10 : 0,
          decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
        ),
      ),
    );
  }
}
