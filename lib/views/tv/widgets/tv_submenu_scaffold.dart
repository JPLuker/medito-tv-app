import 'package:flutter/material.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';

/// Shared 10-foot layout for routes pushed from the TV shell.
///
/// Keeps nested screens visually consistent with the TV home surface instead
/// of dropping back to phone-sized app bars and narrow mobile content.
class TvSubmenuScaffold extends StatelessWidget {
  const TvSubmenuScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.onBack,
    this.showBackButton = true,
    this.maxContentWidth = 1180,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final bool showBackButton;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 28, 40, 56),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showBackButton) ...[
                    SizedBox(
                      width: 150,
                      child: TvFocusCard(
                        onPressed: onBack ?? () => Navigator.of(context).pop(),
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back_rounded, size: 26),
                            const SizedBox(width: 10),
                            Text(
                              'Back',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                  ],
                  Text(
                    title,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Text(
                        subtitle!,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.68,
                          ),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 34),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
