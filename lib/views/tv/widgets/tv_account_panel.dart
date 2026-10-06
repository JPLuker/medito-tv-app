import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medito/providers/providers.dart';
import 'package:medito/providers/stats_provider.dart';
import 'package:medito/repositories/auth/auth_repository.dart';
import 'package:medito/views/settings/sign_up_log_in_screen.dart';
import 'package:medito/views/splash_view.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';

class TvAccountPanel extends ConsumerWidget {
  const TvAccountPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final auth = ref.watch(authRepositorySyncProvider);
    final user = auth.currentUser;
    final email = user?.email;

    if (email == null || email.isEmpty) {
      return TvFocusCard(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SignUpLogInPage(fromSettings: true),
          ),
        ),
        padding: const EdgeInsets.all(26),
        child: Row(
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 48,
              color: onSurface.withValues(alpha: 0.76),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign in or create an account',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sync favorites and your Medito account across devices.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 32,
              color: onSurface.withValues(alpha: 0.72),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
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
                size: 46,
                color: onSurface.withValues(alpha: 0.76),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Signed in',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: 280,
          child: TvFocusCard(
            onPressed: () => _signOut(context, ref),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
            child: const Row(
              children: [
                Icon(Icons.logout_rounded, size: 28),
                SizedBox(width: 14),
                Text(
                  'Sign out',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
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
