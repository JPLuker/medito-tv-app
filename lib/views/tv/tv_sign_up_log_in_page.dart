import 'package:flutter/material.dart';
import 'package:medito/views/settings/sign_up_log_in_screen.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';

/// TV-first wrapper around the existing OTP authentication flow.
///
/// The authentication logic stays shared with mobile, but the presentation is
/// widened, enlarged and given a 10-foot composition so it does not look like
/// a phone form floating in the middle of a television.
class TvSignUpLogInPage extends StatelessWidget {
  const TvSignUpLogInPage({super.key, this.fromSettings = false});

  final bool fromSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 30, 40, 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(right: 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 150,
                        child: TvFocusCard(
                          onPressed: () => Navigator.of(context).pop(),
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
                      const Spacer(),
                      Icon(
                        Icons.self_improvement_rounded,
                        size: 72,
                        color: theme.colorScheme.primary,
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
                        'code to your phone or inbox.',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.72,
                          ),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _InfoLine(
                        icon: Icons.mail_outline_rounded,
                        text: 'Enter your email with the TV keyboard',
                      ),
                      const SizedBox(height: 14),
                      _InfoLine(
                        icon: Icons.password_rounded,
                        text: 'Enter the six-digit code Medito sends you',
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 760,
                      maxHeight: 720,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: MediaQuery(
                        data: media.copyWith(
                          size: Size(760, media.size.height),
                          textScaler: const TextScaler.linear(1.22),
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
                          child: SignUpLogInForm(
                            fromSettings: fromSettings,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
    return Row(
      children: [
        Icon(icon, size: 28, color: theme.colorScheme.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
            ),
          ),
        ),
      ],
    );
  }
}
