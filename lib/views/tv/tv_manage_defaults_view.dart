import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medito/providers/duration_preference_provider.dart';
import 'package:medito/providers/guide_name_preference_provider.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';
import 'package:medito/views/tv/widgets/tv_submenu_scaffold.dart';

class TvManageDefaultsView extends ConsumerWidget {
  const TvManageDefaultsView({super.key});

  static const _durationOptions = <int>[5, 10, 15, 20, 30, 45, 60];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final guide = ref.watch(guideNamePreferenceProvider);
    final durationMs = ref.watch(durationPreferenceProvider);
    final durationMinutes = durationMs == null ? null : durationMs ~/ 60000;

    return TvSubmenuScaffold(
      title: 'Playback defaults',
      subtitle:
          'Choose defaults that make starting a meditation faster with a remote.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guide',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
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
                        Icons.record_voice_over_rounded,
                        size: 36,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Default guide',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              guide ?? 'Not set',
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
              ),
              if (guide != null) ...[
                const SizedBox(width: 16),
                SizedBox(
                  width: 220,
                  child: TvFocusCard(
                    onPressed: () => ref
                        .read(guideNamePreferenceProvider.notifier)
                        .clearGuideName(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close_rounded, size: 28),
                        SizedBox(width: 10),
                        Text(
                          'Clear guide',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 34),
          Text(
            'Duration',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            durationMinutes == null
                ? 'No default duration selected'
                : 'Current default: $durationMinutes minutes',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final minutes in _durationOptions)
                SizedBox(
                  width: 170,
                  child: TvFocusCard(
                    onPressed: () => ref
                        .read(durationPreferenceProvider.notifier)
                        .setDuration(minutes * 60000),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (durationMinutes == minutes) ...[
                            Icon(
                              Icons.check_circle_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            '$minutes min',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (durationMinutes != null)
                SizedBox(
                  width: 170,
                  child: TvFocusCard(
                    onPressed: () => ref
                        .read(durationPreferenceProvider.notifier)
                        .clearDuration(),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No default',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
