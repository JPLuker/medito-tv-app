import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medito/constants/constants.dart';
import 'package:medito/models/models.dart';
import 'package:medito/models/player/repeat_mode.dart';
import 'package:medito/providers/background_sounds/background_sounds_notifier.dart';
import 'package:medito/providers/player/repeat_state_provider.dart';
import 'package:medito/providers/providers.dart';
import 'package:medito/services/analytics/firebase_analytics_service.dart';
import 'package:medito/src/audio_pigeon.g.dart' as pigeon;
import 'package:medito/utils/audio_session_tracker.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';
import 'package:medito/widgets/network_image_widget.dart';

/// A television-native meditation player.
///
/// The phone player is intentionally left untouched. TV removes touch-first
/// chrome, relies on the remote Back button for exit, and exposes the actions
/// that matter during a session as large D-pad targets.
class TvPlayerView extends ConsumerStatefulWidget {
  const TvPlayerView({super.key});

  @override
  ConsumerState<TvPlayerView> createState() => _TvPlayerViewState();
}

class _TvPlayerViewState extends ConsumerState<TvPlayerView> {
  static const _speedOptions = <double>[0.6, 0.7, 0.8, 0.9, 1.0];

  int _speedIndex = 4;
  bool _completed = false;
  bool _completionHandled = false;

  double get _speed => _speedOptions[_speedIndex];

  @override
  void initState() {
    super.initState();
    final request = ref.read(playerProvider);
    unawaited(
      FirebaseAnalyticsService().logScreenView(
        screenName: 'TvPlayerView',
        parameters: request == null ? null : {'trackid': request.trackId},
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialise());
  }

  Future<void> _initialise() async {
    final request = ref.read(playerProvider);
    if (request?.hasBackgroundSound ?? false) {
      ref
          .read(backgroundSoundsNotifierProvider.notifier)
          .playBackgroundSoundFromPref();
    } else {
      ref.read(backgroundSoundsNotifierProvider.notifier).stopBackgroundSound();
    }
  }

  @override
  void dispose() {
    unawaited(AudioSessionTracker.instance.onPlayerClosed());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(playerProvider);
    final track = ref.watch(audioStateProvider.select((state) => state.track));
    final isPlaying = ref.watch(
      audioStateProvider.select((state) => state.isPlaying),
    );
    final isCompleted = ref.watch(
      audioStateProvider.select((state) => state.isCompleted),
    );
    final position = ref.watch(
      audioStateProvider.select((state) => state.position),
    );
    final duration = ref.watch(
      audioStateProvider.select((state) => state.duration),
    );
    final repeatMode = ref.watch(repeatStateProvider);

    if (isCompleted && position > 5000 && !_completionHandled) {
      _completionHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(backgroundSoundsNotifierProvider.notifier)
            .stopBackgroundSound();
        setState(() => _completed = true);
      });
    }

    if (request == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: Text(
            'Unable to load this meditation.',
            style: TextStyle(color: Colors.white, fontSize: 28),
          ),
        ),
      );
    }

    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _stopAndReset();
      },
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.mediaPlayPause):
              _togglePlayPause,
          const SingleActivator(LogicalKeyboardKey.mediaPlay): _togglePlayPause,
          const SingleActivator(LogicalKeyboardKey.mediaPause):
              _togglePlayPause,
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: _completed
              ? _CompletionSurface(
                  title: track.title.isEmpty ? 'Meditation' : track.title,
                  onDone: _finish,
                )
              : _PlayerSurface(
                  request: request,
                  track: track,
                  isPlaying: isPlaying,
                  position: position,
                  duration: duration,
                  speed: _speed,
                  repeatMode: repeatMode,
                  onPlayPause: _togglePlayPause,
                  onBack10: () => ref
                      .read(playerProvider.notifier)
                      .skip10SecondsBackward(),
                  onForward10: () => ref
                      .read(playerProvider.notifier)
                      .skip10SecondsForward(),
                  onRepeat: _toggleRepeat,
                  onSpeed: _cycleSpeed,
                  onBackgroundSound: request.hasBackgroundSound
                      ? _showBackgroundSoundPicker
                      : null,
                ),
        ),
      ),
    );
  }

  void _togglePlayPause() {
    ref.read(playerProvider.notifier).playPause();
  }

  void _toggleRepeat() {
    final mode = ref.read(repeatStateProvider.notifier).toggleRepeat();
    ref.read(playerProvider.notifier).setRepeatMode(mode);
  }

  void _cycleSpeed() {
    setState(() => _speedIndex = (_speedIndex + 1) % _speedOptions.length);
    ref.read(playerProvider.notifier).setSpeed(_speed);
  }

  Future<void> _showBackgroundSoundPicker() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _BackgroundSoundDialog(
        onSelected: (sound) {
          ref
              .read(backgroundSoundsNotifierProvider.notifier)
              .handleOnChangeSound(sound);
          Navigator.of(dialogContext).pop();
        },
        onRetry: (sound) => ref
            .read(backgroundSoundsNotifierProvider.notifier)
            .retryDownload(sound),
      ),
    );
  }

  void _finish() {
    _stopAndReset();
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  void _stopAndReset() {
    ref.read(playerProvider.notifier).stop();
    ref.read(backgroundSoundsNotifierProvider.notifier).stopBackgroundSound();
    ref.read(audioStateProvider.notifier).resetState();
  }
}

class _PlayerSurface extends ConsumerWidget {
  const _PlayerSurface({
    required this.request,
    required this.track,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.speed,
    required this.repeatMode,
    required this.onPlayPause,
    required this.onBack10,
    required this.onForward10,
    required this.onRepeat,
    required this.onSpeed,
    required this.onBackgroundSound,
  });

  final PlaybackRequest request;
  final pigeon.Track track;
  final bool isPlaying;
  final int position;
  final int duration;
  final double speed;
  final RepeatMode repeatMode;
  final VoidCallback onPlayPause;
  final VoidCallback onBack10;
  final VoidCallback onForward10;
  final VoidCallback onRepeat;
  final VoidCallback onSpeed;
  final VoidCallback? onBackgroundSound;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = track.imageUrl;
    final bgState = ref.watch(backgroundSoundsNotifierProvider);
    final selectedSound = bgState.selectedBgSound;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl.isNotEmpty && !HTTPConstants.isDeadDomain(imageUrl))
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Opacity(
              opacity: 0.42,
              child: NetworkImageWidget(url: imageUrl, shouldCache: true),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xCC101010), Color(0xF20D0D0D)],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(58, 42, 58, 42),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: imageUrl.isNotEmpty
                              ? NetworkImageWidget(
                                  url: imageUrl,
                                  shouldCache: true,
                                )
                              : Container(color: const Color(0xFF242424)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 64),
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'NOW PLAYING',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        track.title.isEmpty ? 'Meditation' : track.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.04,
                        ),
                      ),
                      if (track.artist?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 10),
                        Text(
                          track.artist!,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                      const SizedBox(height: 42),
                      _TvProgress(position: position, duration: duration),
                      const SizedBox(height: 34),
                      Row(
                        children: [
                          _ControlCard(
                            label: '10 sec',
                            icon: Icons.replay_10_rounded,
                            onPressed: onBack10,
                          ),
                          const SizedBox(width: 18),
                          _ControlCard(
                            autofocus: true,
                            primary: true,
                            label: isPlaying ? 'Pause' : 'Play',
                            icon: isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            onPressed: onPlayPause,
                          ),
                          const SizedBox(width: 18),
                          _ControlCard(
                            label: '10 sec',
                            icon: Icons.forward_10_rounded,
                            onPressed: onForward10,
                          ),
                          const SizedBox(width: 18),
                          _ControlCard(
                            selected: repeatMode != RepeatMode.none,
                            label: _repeatLabel(repeatMode),
                            icon: repeatMode == RepeatMode.once
                                ? Icons.repeat_one_rounded
                                : Icons.repeat_rounded,
                            onPressed: onRepeat,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          SizedBox(
                            width: 220,
                            child: _UtilityCard(
                              icon: Icons.speed_rounded,
                              title: 'Playback speed',
                              value: '${speed.toStringAsFixed(1)}×',
                              onPressed: onSpeed,
                            ),
                          ),
                          if (onBackgroundSound != null) ...[
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 300,
                              child: _UtilityCard(
                                icon: Icons.graphic_eq_rounded,
                                title: 'Ambient sound',
                                value:
                                    selectedSound == null ||
                                        selectedSound.id ==
                                            kNoneBackgroundSoundId
                                    ? 'Off'
                                    : selectedSound.title,
                                onPressed: onBackgroundSound!,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Use the Back button on your remote to leave the player.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _repeatLabel(RepeatMode mode) {
    return switch (mode) {
      RepeatMode.none => 'Repeat',
      RepeatMode.once => 'Repeat once',
      RepeatMode.infinite => 'Repeat',
    };
  }
}

class _TvProgress extends StatelessWidget {
  const _TvProgress({required this.position, required this.duration});

  final int position;
  final int duration;

  @override
  Widget build(BuildContext context) {
    final safeDuration = duration <= 0 ? 1 : duration;
    final safePosition = position.clamp(0, safeDuration);
    final progress = safePosition / safeDuration;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _format(position),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white70,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              _format(duration),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white70,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _format(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds < 0 ? 0 : milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.autofocus = false,
    this.primary = false,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool autofocus;
  final bool primary;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: primary ? 156 : 126,
      child: TvFocusCard(
        autofocus: autofocus,
        onPressed: onPressed,
        borderRadius: 18,
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: primary ? 20 : 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: primary ? 48 : 36,
              color: selected ? Theme.of(context).colorScheme.primary : null,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UtilityCard extends StatelessWidget {
  const _UtilityCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TvFocusCard(
      onPressed: onPressed,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundSoundDialog extends ConsumerWidget {
  const _BackgroundSoundDialog({
    required this.onSelected,
    required this.onRetry,
  });

  final ValueChanged<BackgroundSoundsModel> onSelected;
  final ValueChanged<BackgroundSoundsModel> onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sounds = ref.watch(backgroundSoundsProvider);
    final state = ref.watch(backgroundSoundsNotifierProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ambient sound',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a background sound. Press Back to cancel.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: sounds.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (_, _) => const Center(
                    child: Text(
                      'Unable to load ambient sounds.',
                      style: TextStyle(color: Colors.white70, fontSize: 20),
                    ),
                  ),
                  data: (items) => ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final sound = items[index];
                      final selected = state.selectedBgSound?.id == sound.id ||
                          (state.selectedBgSound == null &&
                              sound.id == kNoneBackgroundSoundId);
                      final downloading =
                          state.downloadingBgSound?.id == sound.id;
                      final failed = state.failedBgSound?.id == sound.id;
                      return TvFocusCard(
                        autofocus: index == 0,
                        onPressed: () =>
                            failed ? onRetry(sound) : onSelected(sound),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white70,
                              size: 30,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                sound.id == kNoneBackgroundSoundId
                                    ? 'None'
                                    : sound.title,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            if (downloading)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else if (failed)
                              const Row(
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Retry',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionSurface extends StatelessWidget {
  const _CompletionSurface({required this.title, required this.onDone});

  final String title;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 92,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 26),
                Text(
                  'Session complete',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 38),
                SizedBox(
                  width: 260,
                  child: TvFocusCard(
                    autofocus: true,
                    onPressed: onDone,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Done',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
