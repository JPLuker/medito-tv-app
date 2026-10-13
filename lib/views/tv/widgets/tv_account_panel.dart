import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medito/providers/providers.dart';
import 'package:medito/providers/stats_provider.dart';
import 'package:medito/repositories/auth/auth_repository.dart';
import 'package:medito/views/settings/sign_up_log_in_screen.dart';
import 'package:medito/views/splash_view.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';

/// Compact account row matching the iPad Settings surface.
class TvAccountPanel extends ConsumerWidget {
  const TvAccountPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final auth = ref.watch(authRepositorySyncProvider);
    final email = auth.currentUser?.email;

    if (email == null || email.isEmpty) {
      return TvFocusCard(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SignUpLogInPage(fromSettings: true),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 32,
              color: onSurface.withValues(alpha: 0.88),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'Sign in / Sign up',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 30,
              color: onSurface.withValues(alpha: 0.78),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 32,
                color: onSurface.withValues(alpha: 0.88),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Signed in',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: onSurface.withValues(alpha: 0.64),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TvFocusCard(
          onPressed: () => _signOut(context, ref),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                size: 30,
                color: onSurface.withValues(alpha: 0.88),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  'Sign out',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authRepositorySyncProvider);
    await auth.signOut();
    await ref.read(statsManagerProvider).clearAllStats();
    ref.read(meRefreshProvider)();
    ref.read(statsProvider.notifier).refresh();
    ref.invalidate(packProvider);
    ref.invalidate(authRepositoryProvider);

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashView()),
      (_) => false,
    );
  }
}
