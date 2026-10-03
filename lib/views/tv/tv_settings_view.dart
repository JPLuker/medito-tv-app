import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medito/providers/theme_provider.dart';
import 'package:medito/views/tv/tv_analytics_settings_view.dart';
import 'package:medito/views/tv/tv_manage_defaults_view.dart';
import 'package:medito/views/tv/widgets/tv_account_panel.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';

class TvSettingsView extends ConsumerWidget {
  const TvSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedTheme = ref.watch(themeProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 28, 40, 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'TV uses Zen Mode automatically.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 28),
              const _Section(title: 'Account', child: TvAccountPanel()),
              const SizedBox(height: 30),
              _Section(
                title: 'Appearance',
                child: Row(
                  children: [
                    Expanded(
                      child: _ThemeCard(
                        icon: Icons.dark_mode_rounded,
                        title: 'Dark',
                        selected: selectedTheme == ThemeMode.dark,
                        onPressed: () => ref
                            .read(themeProvider.notifier)
                            .setTheme(ThemeMode.dark),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ThemeCard(
                        icon: Icons.light_mode_rounded,
                        title: 'Light',
                        selected: selectedTheme == ThemeMode.light,
                        onPressed: () => ref
                            .read(themeProvider.notifier)
                            .setTheme(ThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ThemeCard(
                        icon: Icons.settings_brightness_rounded,
                        title: 'System',
                        selected: selectedTheme == ThemeMode.system,
                        onPressed: () => ref
                            .read(themeProvider.notifier)
                            .setTheme(ThemeMode.system),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _Section(
                title: 'App',
                child: Row(
                  children: [
                    Expanded(
                      child: _SettingsCard(
                        icon: Icons.tune_rounded,
                        title: 'Playback defaults',
                        subtitle: 'Guide and duration preferences',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TvManageDefaultsView(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _SettingsCard(
                        icon: Icons.privacy_tip_rounded,
                        title: 'Analytics & privacy',
                        subtitle: 'Control optional analytics',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TvAnalyticsSettingsView(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TvFocusCard(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Row(
        children: [
          Icon(icon, size: 34, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (selected)
            Icon(
              Icons.check_circle_rounded,
              color: theme.colorScheme.primary,
              size: 30,
            ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TvFocusCard(
      onPressed: onPressed,
      padding: const EdgeInsets.all(22),
      child: SizedBox(
        height: 110,
        child: Row(
          children: [
            Icon(icon, size: 36, color: theme.colorScheme.primary),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 30),
          ],
        ),
      ),
    );
  }
}
