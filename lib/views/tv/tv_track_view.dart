import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medito/l10n/app_localizations.dart';
import 'package:medito/models/favorites/favorite_item.dart';
import 'package:medito/models/models.dart';
import 'package:medito/providers/duration_preference_provider.dart';
import 'package:medito/providers/favorites/favorites_provider.dart';
import 'package:medito/providers/guide_name_preference_provider.dart';
import 'package:medito/providers/meditation/track_provider.dart';
import 'package:medito/providers/providers.dart';
import 'package:medito/utils/logger.dart';
import 'package:medito/utils/track_variant_selector.dart';
import 'package:medito/views/tv/tv_player_view.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';
import 'package:medito/views/tv/widgets/tv_submenu_scaffold.dart';
import 'package:medito/widgets/markdown_widget.dart';
import 'package:medito/widgets/network_image_widget.dart';

/// TV-first meditation detail screen.
///
/// The content order deliberately mirrors Medito's adaptive tablet track page:
/// artwork first, then title/description, pickers and the primary action. TV
/// enlarges those controls for D-pad use and relies on the remote Back button.
class TvTrackView extends ConsumerWidget {
  const TvTrackView({super.key, required this.trackId});

  final String trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(tracksProvider(trackId: trackId));
    final guideName = ref.watch(guideNamePreferenceProvider);
    final duration = ref.watch(durationPreferenceProvider);

    return track.when(
      loading: () => const TvSubmenuScaffold(
        title: 'Meditation',
        showBackButton: false,
        maxContentWidth: 840,
        child: SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => TvSubmenuScaffold(
        title: 'Meditation',
        subtitle: 'This meditation could not be loaded.',
        showBackButton: false,
        maxContentWidth: 840,
        child: SizedBox(
          width: 240,
          child: TvFocusCard(
            autofocus: true,
            onPressed: () => ref.refresh(tracksProvider(trackId: trackId)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, size: 30),
                SizedBox(width: 12),
                Text(
                  'Retry',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (value) {
        final selection = TrackVariantSelector.resolve(
          value,
          guideName: guideName,
          durationMs: duration,
        );
        return _TrackSurface(
          track: value,
          activeVoice: selection.voice,
          activeFile: selection.file,
        );
      },
    );
  }
}

class _TrackSurface extends ConsumerWidget {
  const _TrackSurface({
    required this.track,
    required this.activeVoice,
    required this.activeFile,
  });

  final Track track;
  final TrackVoice activeVoice;
  final TrackAudioFile activeFile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final guideOptions = track.voices
        .where((voice) => voice.guideName?.trim().isNotEmpty == true)
        .toList();
    final favorites = ref.watch(favoritesNotifierProvider);
    final isFavorite = favorites.maybeWhen(
      data: (items) => items.any((item) => item.id == track.id),
      orElse: () => false,
    );

    const dailyMeditationId = 'BmTFAyYt8jVMievZ';
    final canFavorite = track.id != dailyMeditationId;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 32, 40, 52),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.22,
                            ),
                          ),
                        ),
                        child: NetworkImageWidget(
                          url: track.coverUrl,
                          shouldCache: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    track.title,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (track.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    MarkdownWidget(
                      body: track.description,
                      selectable: false,
                      p: theme.textTheme.titleLarge?.copyWith(
                        height: 1.45,
                        color: onSurface.withValues(alpha: 0.78),
                      ),
                      a: theme.textTheme.titleLarge?.copyWith(
                        height: 1.45,
                        color: onSurface.withValues(alpha: 0.78),
                        decoration: TextDecoration.none,
                      ),
                      onTapLink: null,
                    ),
                  ],
                  const SizedBox(height: 30),
                  if (guideOptions.isNotEmpty) ...[
                    _SectionLabel(label: 'Guide'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        for (var index = 0;
                            index < guideOptions.length;
                            index++)
                          SizedBox(
                            width: 250,
                            child: _ChoiceCard(
                              label: guideOptions[index].guideName!,
                              selected: guideOptions[index].guideName ==
                                  activeVoice.guideName,
                              autofocus: index == 0,
                              onPressed: () =>
                                  _setGuide(ref, guideOptions[index]),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 26),
                  ],
                  const _SectionLabel(label: 'Duration'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (var index = 0;
                          index < activeVoice.audioFiles.length;
                          index++)
                        SizedBox(
                          width: 190,
                          child: _ChoiceCard(
                            label: _durationLabel(
                              activeVoice.audioFiles[index].duration,
                            ),
                            selected: activeVoice.audioFiles[index].duration ==
                                activeFile.duration,
                            autofocus: guideOptions.isEmpty && index == 0,
                            onPressed: () => ref
                                .read(durationPreferenceProvider.notifier)
                                .setDuration(
                                  activeVoice.audioFiles[index].duration,
                                ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: TvFocusCard(
                          onPressed: () => _play(context, ref),
                          borderRadius: 16,
                          child: Container(
                            height: 72,
                            alignment: Alignment.center,
                            color: theme.brightness == Brightness.dark
                                ? Colors.white
                                : onSurface,
                            child: Icon(
                              Icons.play_arrow_rounded,
                              size: 42,
                              color: theme.brightness == Brightness.dark
                                  ? Colors.black
                                  : theme.colorScheme.surface,
                            ),
                          ),
                        ),
                      ),
                      if (canFavorite) ...[
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 280,
                          child: TvFocusCard(
                            onPressed: () => _toggleFavorite(ref, isFavorite),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 20,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isFavorite
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 32,
                                  color: onSurface,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isFavorite ? 'Saved' : 'Save to favorites',
                                  style: theme.textTheme.titleLarge?.copyWith(
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
                  const SizedBox(height: 22),
                  Text(
                    'Press Back on your remote to return.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: onSurface.withValues(alpha: 0.5),
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

  void _setGuide(WidgetRef ref, TrackVoice voice) {
    ref
        .read(guideNamePreferenceProvider.notifier)
        .setGuideName(voice.guideName);

    final currentDuration = ref.read(durationPreferenceProvider);
    if (currentDuration == null) return;

    final bestFile = TrackVariantSelector.closestDuration(
      voice.audioFiles,
      currentDuration,
    );
    ref
        .read(durationPreferenceProvider.notifier)
        .setDuration(bestFile.duration);
  }

  void _toggleFavorite(WidgetRef ref, bool isFavorite) {
    final notifier = ref.read(favoritesNotifierProvider.notifier);
    if (isFavorite) {
      notifier.removeFromFavorites(track.id);
      return;
    }

    notifier.addToFavorites(
      FavoriteItem(
        id: track.id,
        title: track.title,
        coverUrl: track.coverUrl,
        subtitle: track.subtitle,
        type: FavoriteItemType.track,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> _play(BuildContext context, WidgetRef ref) async {
    try {
      final request = PlaybackRequest.fromTrack(track, activeVoice, activeFile);
      await ref.read(playerProvider.notifier).play(request);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TvPlayerView()),
      );
    } catch (error, stackTrace) {
      AppLogger.e('TV_TRACK', 'Failed to start playback', error, stackTrace);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.unableToLoadAudio),
        ),
      );
    }
  }

  String _durationLabel(int durationMs) {
    if (durationMs < Duration.millisecondsPerMinute) {
      final seconds = (durationMs / Duration.millisecondsPerSecond).round();
      return '$seconds sec';
    }
    final minutes = (durationMs / Duration.millisecondsPerMinute).round();
    return '$minutes min';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.autofocus = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return TvFocusCard(
      autofocus: autofocus,
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (selected) ...[
            Icon(Icons.check_circle_rounded, size: 26, color: onSurface),
            const SizedBox(width: 9),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
