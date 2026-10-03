import 'package:flutter/material.dart';
import 'package:medito/views/settings/advanced_settings_screen.dart';
import 'package:medito/views/settings/analytics_settings_screen.dart';
import 'package:medito/views/settings/widgets/account_section_widget.dart';
import 'package:medito/views/settings/widgets/theme_tile.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';

class TvSettingsView extends StatelessWidget {
  const TvSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              _Section(
                title: 'Account',
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const AccountSectionWidget(inCard: true),
                ),
              ),
              const SizedBox(height: 28),
              _Section(
                title: 'Appearance',
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const ThemeTile(
                    icon: Icon(Icons.palette_rounded),
                    title: 'Theme',
                    hasUnderline: false,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _Section(
                title: 'App',
                child: Row(
                  children: [
                    Expanded(
                      child: _SettingsCard(
                        icon: Icons.tune_rounded,
                        title: 'Advanced',
                        subtitle: 'Playback and app preferences',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdvancedSettingsScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _SettingsCard(
                        icon: Icons.privacy_tip_rounded,
                        title: 'Analytics & Privacy',
                        subtitle: 'Control optional analytics',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AnalyticsSettingsScreen(),
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
          ],
        ),
      ),
    );
  }
}
