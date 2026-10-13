import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medito/providers/theme_provider.dart';
import 'package:medito/views/tv/tv_analytics_settings_view.dart';
import 'package:medito/views/tv/tv_manage_defaults_view.dart';
import 'package:medito/views/tv/widgets/tv_account_panel.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';

/// TV Settings uses the same sectioned single-row language as the iPad build.
/// Only settings that make sense on a television are surfaced here.
class TvSettingsView extends ConsumerWidget {
  const TvSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedTheme = ref.watch(themeProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(34, 26, 46, 64),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1060),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const _Section(
                    title: 'Account',
                    child: TvAccountPanel(),
                  ),
                  const SizedBox(height: 34),
                  _Section(
                    title: 'Playback',
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
                  const SizedBox(height: 34),
                  _Section(
                    title: 'Privacy',
                    child: _SettingsCard(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Analytics & privacy',
                      subtitle: 'Control optional analytics',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TvAnalyticsSettingsView(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  _Section(
                    title: 'Customisation',
                    child: _SettingsCard(
                      icon: Icons.settings_outlined,
                      title: 'Theme',
                      subtitle: _themeLabel(selectedTheme),
                      onPressed: () => _showThemePicker(
                        context,
                        ref,
                        selectedTheme,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'TV uses Zen Mode automatically.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.52),
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

  static String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.dark => 'Dark',
    ThemeMode.light => 'Light',
    ThemeMode.system => 'System',
  };

  Future<void> _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    ThemeMode selected,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: Text(
            'Theme',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: 660,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final mode in ThemeMode.values) ...[
                  TvFocusCard(
                    autofocus: mode == selected,
                    onPressed: () {
                      ref.read(themeProvider.notifier).setTheme(mode);
                      Navigator.of(dialogContext).pop();
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          switch (mode) {
                            ThemeMode.dark => Icons.dark_mode_rounded,
                            ThemeMode.light => Icons.light_mode_rounded,
                            ThemeMode.system => Icons.settings_brightness_rounded,
                          },
                          size: 32,
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Text(
                            _themeLabel(mode),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (mode == selected)
                          const Icon(Icons.check_rounded, size: 30),
                      ],
                    ),
                  ),
                  if (mode != ThemeMode.values.last)
                    const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        );
      },
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
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
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
    final onSurface = theme.colorScheme.onSurface;

    return TvFocusCard(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Icon(icon, size: 32, color: onSurface.withValues(alpha: 0.88)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: onSurface.withValues(alpha: 0.64),
                  ),
                ),
              ],
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
}
