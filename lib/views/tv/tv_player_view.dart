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
import 'package:medito/utils/audio_session_tracker.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';
import 'package:medito/widgets/network_image_widget.dart';

/// Television-native meditation player.
///
/// Its composition deliberately follows Medito's tablet/foldable player:
/// metadata on the left, transport on the right, all over the blurred session
/// artwork. TV-only controls keep large D-pad targets and remote Back exits.
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

    final effectiveDuration = duration > 0 ? duration : request.duration;

    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _stopAndReset();
      },
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.mediaPlayPause):
              _togglePlayPause,
          const SingleActivator(LogicalKeyboardKey.mediaPlay): _togglePlayPause,
          const SingleActivator(LogicalKeyboardKey.mediaPause): _togglePlayPause,
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: _completed
              ? _CompletionSurface(title: request.title, onDone: _finish)
              : _PlayerSurface(
                  request: request,
                  isPlaying: isPlaying,
                  position: position,
                  duration: effectiveDuration,
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
    final imageUrl = request.coverUrl;
    final bgState = ref.watch(backgroundSoundsNotifierProvider);
    final selectedSound = bgState.selectedBgSound;
    final guide = request.guideName?.trim();
    final artist = request.artist?.name.trim();
    final byline = guide?.isNotEmpty == true
        ? guide!
        : artist?.isNotEmpty == true
        ? artist!
        : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl.isNotEmpty && !HTTPConstants.isDeadDomain(imageUrl))
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Opacity(
              opacity: 0.62,
              child: NetworkImageWidget(url: imageUrl, shouldCache: true),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xA6000000), Color(0xD9000000)],
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _PlayerHeading(
                        title: request.title,
                        byline: byline,
                        description: request.description,
                      ),
                    ),
                    const SizedBox(width: 54),
                    Expanded(
                      child: _PlayerControls(
                        isPlaying: isPlaying,
                        position: position,
                        duration: duration,
                        speed: speed,
                        repeatMode: repeatMode,
                        selectedAmbientSound:
                            selectedSound == null ||
                                selectedSound.id == kNoneBackgroundSoundId
                            ? 'Off'
                            : selectedSound.title,
                        onPlayPause: onPlayPause,
                        onBack10: onBack10,
                        onForward10: onForward10,
                        onRepeat: onRepeat,
                        onSpeed: onSpeed,
                        onBackgroundSound: onBackgroundSound,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerHeading extends StatelessWidget {
  const _PlayerHeading({
    required this.title,
    required this.byline,
    required this.description,
  });

  final String title;
  final String? byline;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOW PLAYING',
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title.isEmpty ? 'Meditation' : title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.06,
          ),
        ),
        if (byline != null) ...[
          const SizedBox(height: 14),
          Text(
            byline!,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (description.trim().isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(
            description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white60,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls({
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.speed,
    required this.repeatMode,
    required this.selectedAmbientSound,
    required this.onPlayPause,
    required this.onBack10,
    required this.onForward10,
    required this.onRepeat,
    required this.onSpeed,
    required this.onBackgroundSound,
  });

  final bool isPlaying;
  final int position;
  final int duration;
  final double speed;
  final RepeatMode repeatMode;
  final String selectedAmbientSound;
  final VoidCallback onPlayPause;
  final VoidCallback onBack10;
  final VoidCallback onForward10;
  final VoidCallback onRepeat;
  final VoidCallback onSpeed;
  final VoidCallback? onBackgroundSound;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TvProgress(position: position, duration: duration),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TransportButton(
              label: 'Back 10',
              icon: Icons.replay_10_rounded,
              onPressed: onBack10,
            ),
            const SizedBox(width: 18),
            _TransportButton(
              autofocus: true,
              primary: true,
              label: isPlaying ? 'Pause' : 'Play',
              icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              onPressed: onPlayPause,
            ),
            const SizedBox(width: 18),
            _TransportButton(
              label: 'Forward 10',
              icon: Icons.forward_10_rounded,
              onPressed: onForward10,
            ),
          ],
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(
              width: 190,
              child: _UtilityCard(
                icon: Icons.speed_rounded,
                title: 'Speed',
                value: '${speed.toStringAsFixed(1)}×',
                onPressed: onSpeed,
              ),
            ),
            SizedBox(
              width: 190,
              child: _UtilityCard(
                icon: repeatMode == RepeatMode.once
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                title: 'Repeat',
                value: _repeatValue(repeatMode),
                selected: repeatMode != RepeatMode.none,
                onPressed: onRepeat,
              ),
            ),
            if (onBackgroundSound != null)
              SizedBox(
                width: 230,
                child: _UtilityCard(
                  icon: Icons.graphic_eq_rounded,
                  title: 'Ambient sound',
                  value: selectedAmbientSound,
                  onPressed: onBackgroundSound!,
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'Press Back on your remote to leave the player.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  String _repeatValue(RepeatMode mode) {
    return switch (mode) {
      RepeatMode.none => 'Off',
      RepeatMode.once => 'Once',
      RepeatMode.infinite => 'On',
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
            minHeight: 8,
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
    final value = Duration(milliseconds: milliseconds < 0 ? 0 : milliseconds);
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.autofocus = false,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool autofocus;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: primary ? 170 : 145,
      child: TvFocusCard(
        autofocus: autofocus,
        onPressed: onPressed,
        borderRadius: 18,
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: primary ? 22 : 19,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: primary ? 52 : 38, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
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
    );
  }
}

class _UtilityCard extends StatelessWidget {
  const _UtilityCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return TvFocusCard(
      onPressed: onPressed,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
        children: [
          Icon(
            icon,
            size: 28,
            color: selected ? Colors.white : Colors.white70,
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
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
                              color: Colors.white,
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
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 92,
                  color: Colors.white,
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
