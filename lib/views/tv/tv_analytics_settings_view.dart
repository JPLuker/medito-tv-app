import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medito/constants/strings/shared_preference_constants.dart';
import 'package:medito/providers/shared_preference/shared_preference_provider.dart';
import 'package:medito/services/analytics/crashlytics_service.dart';
import 'package:medito/services/analytics/firebase_analytics_service.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';
import 'package:medito/views/tv/widgets/tv_submenu_scaffold.dart';

final _tvFirebaseAnalyticsEnabledProvider = Provider<bool>((ref) {
  return ref
          .watch(sharedPreferencesProvider)
          .getBool(SharedPreferenceConstants.analyticsFirebaseEnabled) ??
      true;
});

class TvAnalyticsSettingsView extends ConsumerWidget {
  const TvAnalyticsSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(_tvFirebaseAnalyticsEnabledProvider);
    final theme = Theme.of(context);

    return TvSubmenuScaffold(
      title: 'Analytics & privacy',
      subtitle:
          'Medito can collect optional anonymous app analytics. Meta/Facebook '
          'tracking is disabled on TV.',
      child: SizedBox(
        width: 760,
        child: TvFocusCard(
          onPressed: () => _changeAnalytics(context, ref, !enabled),
          padding: const EdgeInsets.all(26),
          child: Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 42,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firebase Analytics',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      enabled
                          ? 'Optional analytics are enabled.'
                          : 'Optional analytics are disabled.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.68,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: enabled, onChanged: null),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeAnalytics(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    if (!enabled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Disable analytics?'),
          content: const SizedBox(
            width: 560,
            child: Text(
              'This disables optional Firebase Analytics and Crashlytics '
              'collection on this device.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Disable'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await ref
        .read(sharedPreferencesProvider)
        .setBool(SharedPreferenceConstants.analyticsFirebaseEnabled, enabled);
    await FirebaseAnalyticsService().setCollectionEnabled(enabled);
    await CrashlyticsService().setCollectionEnabled(enabled);
    ref.invalidate(_tvFirebaseAnalyticsEnabledProvider);
  }
}
