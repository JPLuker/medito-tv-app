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
    final onSurface = theme.colorScheme.onSurface;

    return TvSubmenuScaffold(
      title: 'Analytics & privacy',
      subtitle:
          'Medito can collect optional anonymous app analytics. Meta/Facebook '
          'tracking is disabled on TV.',
      showBackButton: false,
      maxContentWidth: 960,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 760,
            child: TvFocusCard(
              onPressed: () => _changeAnalytics(context, ref, !enabled),
              padding: const EdgeInsets.all(26),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 42,
                    color: onSurface.withValues(alpha: 0.76),
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
                            color: onSurface.withValues(alpha: 0.68),
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
          const SizedBox(height: 28),
          Text(
            'Press Back on your remote to return.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
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
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Disable analytics?',
                    style: Theme.of(dialogContext).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'This disables optional Firebase Analytics and Crashlytics '
                    'collection on this device.',
                    style: Theme.of(dialogContext).textTheme.titleMedium
                        ?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: TvFocusCard(
                          autofocus: true,
                          onPressed: () => Navigator.pop(dialogContext, false),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TvFocusCard(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: const Center(
                            child: Text(
                              'Disable',
                              style: TextStyle(
                                fontSize: 18,
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
            ),
          ),
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
