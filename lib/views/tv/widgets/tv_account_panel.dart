import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medito/providers/providers.dart';
import 'package:medito/providers/stats_provider.dart';
import 'package:medito/repositories/auth/auth_repository.dart';
import 'package:medito/views/splash_view.dart';
import 'package:medito/views/tv/tv_sign_up_log_in_page.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';

class TvAccountPanel extends ConsumerWidget {
  const TvAccountPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authRepositorySyncProvider);
    final user = auth.currentUser;
    final email = user?.email;

    if (email == null || email.isEmpty) {
      return TvFocusCard(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const TvSignUpLogInPage(fromSettings: true),
          ),
        ),
        padding: const EdgeInsets.all(26),
        child: Row(
          children: [
            Icon(
              Icons.account_circle_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign in or create an account',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sync favorites and your Medito account across devices.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 32),
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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_circle_rounded,
                size: 46,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Signed in',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
