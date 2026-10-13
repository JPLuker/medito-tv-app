import 'package:flutter/material.dart';
import 'package:medito/constants/constants.dart';

/// TV frame for the shared OTP authentication form.
///
/// The previous split-pane treatment constrained the form to a short card and
/// clipped the benefits/header content at 720p. The iPad layout is a much
/// better reference for TV: one centered content column with the form allowed
/// to use the full vertical viewport and scroll when the keyboard is open.
class TvSignUpLogInFrame extends StatelessWidget {
  const TvSignUpLogInFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 940),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(36, 26, 36, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign in / Sign up',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use your Medito account to keep your progress and favorites in sync.',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: onSurface.withValues(alpha: 0.66),
                    ),
                  ),
                  if (isMockMode) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: onSurface.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.science_outlined,
                            size: 25,
                            color: onSurface.withValues(alpha: 0.76),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Mock mode: no email is sent. Any six-digit code works (for example 123456).',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: onSurface.withValues(alpha: 0.74),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.22),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Theme(
                          data: theme.copyWith(
                            inputDecorationTheme: theme.inputDecorationTheme
                                .copyWith(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 20,
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
                  const SizedBox(height: 12),
                  Text(
                    'Press Back on your remote to return.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: onSurface.withValues(alpha: 0.48),
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
