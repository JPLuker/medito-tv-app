import 'package:flutter/material.dart';
import 'package:medito/constants/styles/widget_styles.dart';

/// A full-width selectable option tile used in onboarding question screens.
///
/// Supports touch/click input and keyboard/D-pad focus + activation.
class OnboardingOptionButton extends StatefulWidget {
  const OnboardingOptionButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.focusNode,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  @override
  State<OnboardingOptionButton> createState() =>
      _OnboardingOptionButtonState();
}

class _OnboardingOptionButtonState extends State<OnboardingOptionButton> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final highlighted = widget.selected || _hasFocus;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        focusNode: widget.focusNode,
        onTap: widget.onTap,
        onFocusChange: (hasFocus) {
          if (_hasFocus == hasFocus) return;
          setState(() => _hasFocus = hasFocus);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: padding20,
            vertical: 18,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? colorScheme.primary.withAlpha(25)
                : _hasFocus
                    ? colorScheme.primary.withAlpha(18)
                    : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlighted
                  ? colorScheme.primary
                  : colorScheme.outline.withAlpha(80),
              width: _hasFocus ? 3 : (widget.selected ? 1.5 : 1),
            ),
          ),
          child: Text(
            widget.label,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
              color: highlighted
                  ? colorScheme.primary
                  : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
