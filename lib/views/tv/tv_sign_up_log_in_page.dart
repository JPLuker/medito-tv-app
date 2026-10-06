import 'package:flutter/material.dart';

/// TV-first frame for the shared OTP authentication form.
///
/// Authentication state and API calls remain in the shared mobile/TV form.
/// The composition follows the wide tablet layout: explanatory content and the
/// form share a centered, bounded pane. TV relies on the remote Back button
/// instead of adding another distant focus target.
class TvSignUpLogInFrame extends StatelessWidget {
  const TvSignUpLogInFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 52),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.self_improvement_rounded,
                            size: 68,
                            color: onSurface.withValues(alpha: 0.82),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Your Medito account',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sign in with your email to keep your favorites and '
                            'account in sync. We will send a six-digit verification '
                            'code to your inbox.',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: onSurface.withValues(alpha: 0.72),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const _InfoLine(
                            icon: Icons.mail_outline_rounded,
                            text: 'Enter your email with the TV keyboard',
                          ),
                          const SizedBox(height: 14),
                          const _InfoLine(
                            icon: Icons.password_rounded,
                            text: 'Enter the six-digit code Medito sends you',
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Press Back on your remote to return.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 680,
                        maxHeight: 720,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.22),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: MediaQuery(
                          data: media.copyWith(
                            size: Size(680, media.size.height),
                            textScaler: const TextScaler.linear(1.18),
                          ),
                          child: Theme(
                            data: theme.copyWith(
                              inputDecorationTheme: theme.inputDecorationTheme
                                  .copyWith(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                      vertical: 22,
                                    ),
                                  ),
                              elevatedButtonTheme: ElevatedButtonThemeData(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(62),
                                  textStyle: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(120, 52),
                                  textStyle: theme.textTheme.titleMedium,
                                ),
                              ),
                            ),
                            child: child,
                          ),
                        ),
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 28, color: onSurface.withValues(alpha: 0.76)),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              color: onSurface.withValues(alpha: 0.76),
            ),
          ),
        ),
      ],
    );
  }
}
