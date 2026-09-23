import 'package:medito/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:medito/widgets/medito_icon.dart';
import 'package:medito/utils/utils.dart';

class RowItemWidget extends StatefulWidget {
  const RowItemWidget({
    super.key,
    required this.title,
    this.subTitle,
    required this.icon,
    this.widget.hasUnderline = true,
    this.onTap,
    this.isTrailingIcon = true,
    this.isSwitch = false,
    this.switchValue,
    this.onSwitchChanged,
    this.titleStyle,
    this.trailingIconSize = 24,
    this.leadingIconSize = 24,
    this.iconColor,
    this.trailingIcon = Icons.chevron_right_rounded,
    this.trailing,
  });

  final String title;
  final String? subTitle;
  final Widget icon;
  final Color? iconColor;
  final bool widget.hasUnderline;
  final void Function()? onTap;
  final bool isTrailingIcon;
  final bool isSwitch;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final TextStyle? titleStyle;
  final double leadingIconSize;
  final double trailingIconSize;
  final IconData trailingIcon;

  /// Optional widget shown before the trailing icon / switch, e.g. a preview
  /// of the current selection (theme swatch, app icon).
  final Widget? trailing;

  @override
  State<RowItemWidget> createState() => _RowItemWidgetState();
}

class _RowItemWidgetState extends State<RowItemWidget> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    var border = Border(
      bottom: widget.hasUnderline
          ? BorderSide(
              width: 0.7,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacityValue(0.2),
            )
          : BorderSide.none,
    );

    return MergeSemantics(
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        onFocusChange: (focused) {
          if (_hasFocus != focused) setState(() => _hasFocus = focused);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _hasFocus
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hasFocus
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(border: border),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildIconWithColor(),
                      width16,
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 18.0),
                            children: [
                              TextSpan(
                                text: widget.title,
                                style:
                                    widget.titleStyle ??
                                    Theme.of(
                                      context,
                                    ).textTheme.labelMedium?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              if (widget.subTitle != null) _subtitle(context),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.trailing != null) ...[widget.trailing!, width16],
                if (widget.isTrailingIcon && !widget.isSwitch)
                  Icon(
                    widget.trailingIcon,
                    size: widget.trailingIconSize,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                if (widget.isSwitch)
                  Switch(
                    value: widget.switchValue ?? false,
                    onChanged: widget.onSwitchChanged,
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildIconWithColor() {
    if (widget.iconColor != null && widget.icon is MeditoRemoteIcon) {
      final meditoIcon = widget.icon as MeditoRemoteIcon;
      return MeditoRemoteIcon(
        icon: meditoIcon.icon,
        color: widget.iconColor,
        size: meditoIcon.size,
      );
    }
    return widget.icon;
  }

  TextSpan _subtitle(BuildContext context) {
    return TextSpan(
      text: widget.subTitle != null ? '\n${widget.subTitle}' : '',
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        letterSpacing: 0,
        height: 1.7,
      ),
    );
  }
}
