import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medito/constants/types/type_constants.dart';
import 'package:medito/models/explore/explore_list_item.dart';
import 'package:medito/providers/explore/track_search_provider.dart';
import 'package:medito/routes/routes.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';
import 'package:medito/widgets/network_image_widget.dart';

enum _TvSearchFilter { packs, tracks }

/// Search surface built specifically for a remote.
///
/// The phone SearchResults widget uses touch-first tabs/list cards. On TV we
/// keep the same Packs/Tracks model but render large focusable tabs and results
/// inside the same bounded pane used by Medito's tablet/foldable layouts.
class TvSearchView extends ConsumerStatefulWidget {
  const TvSearchView({super.key});

  @override
  ConsumerState<TvSearchView> createState() => _TvSearchViewState();
}

class _TvSearchViewState extends ConsumerState<TvSearchView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  _TvSearchFilter _filter = _TvSearchFilter.packs;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final packsAsync = ref.watch(explorePacksProvider);
    final AsyncValue<List<TrackItem>> tracksAsync = _query.isEmpty
        ? const AsyncData(<TrackItem>[])
        : ref.watch(searchTracksProvider(_query));

    final packs = packsAsync.value ?? <PackItem>[];
    final lowerQuery = _query.toLowerCase();
    final filteredPacks = _query.isEmpty
        ? <PackItem>[]
        : packs
              .where(
                (item) =>
                    item.title.toLowerCase().contains(lowerQuery) ||
                    item.subtitle.toLowerCase().contains(lowerQuery),
              )
              .toList();
    final tracks = tracksAsync.value ?? <TrackItem>[];

    if (_query.isNotEmpty &&
        _filter == _TvSearchFilter.packs &&
        filteredPacks.isEmpty &&
        tracks.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _filter == _TvSearchFilter.packs) {
          setState(() => _filter = _TvSearchFilter.tracks);
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 28, 40, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) {
                        final ascii = value.replaceAll(
                          RegExp(r'[^\x00-\x7F]'),
                          '',
                        );
                        if (_query == ascii) return;
                        setState(() {
                          _query = ascii;
                          _filter = _TvSearchFilter.packs;
                        });
                      },
                      style: theme.textTheme.titleLarge,
                      decoration: InputDecoration(
                        hintText: 'Search Medito',
                        prefixIcon: const Icon(Icons.search_rounded, size: 30),
                        suffixIcon: _controller.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _controller.clear();
                                  setState(() {
                                    _query = '';
                                    _filter = _TvSearchFilter.packs;
                                  });
                                  _focusNode.requestFocus();
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: theme.colorScheme.onSurface,
                            width: 3,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_query.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'Search for a meditation or pack.',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.58,
                            ),
                          ),
                        ),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        SizedBox(
                          width: 230,
                          child: _FilterCard(
                            label: 'Packs',
                            count: filteredPacks.length,
                            selected: _filter == _TvSearchFilter.packs,
                            onPressed: () => setState(
                              () => _filter = _TvSearchFilter.packs,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        SizedBox(
                          width: 230,
                          child: _FilterCard(
                            label: 'Tracks',
                            count: tracks.length,
                            selected: _filter == _TvSearchFilter.tracks,
                            onPressed: () => setState(
                              () => _filter = _TvSearchFilter.tracks,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _filter == _TvSearchFilter.packs
                          ? _buildPackResults(filteredPacks, packsAsync)
                          : _buildTrackResults(tracks, tracksAsync),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPackResults(List<PackItem> packs, AsyncValue<List<PackItem>> state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.hasError) {
      return _RetryState(onRetry: () => ref.invalidate(explorePacksProvider));
    }
    if (packs.isEmpty) return const _EmptyState(label: 'No packs found.');

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 36),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        mainAxisExtent: 215,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
      ),
      itemCount: packs.length,
      itemBuilder: (context, index) {
        final item = packs[index];
        return _PackResultCard(
          item: item,
          onPressed: () {
            _focusNode.unfocus();
            handleNavigation(
              TypeConstants.pack,
              [item.id, item.path],
              context,
              ref: ref,
            );
          },
        );
      },
    );
  }

  Widget _buildTrackResults(
    List<TrackItem> tracks,
    AsyncValue<List<TrackItem>> state,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.hasError) {
      return _RetryState(
        onRetry: () => ref.invalidate(searchTracksProvider(_query)),
      );
    }
    if (tracks.isEmpty) return const _EmptyState(label: 'No tracks found.');

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 36),
      itemCount: tracks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = tracks[index];
        return _TrackResultCard(
          item: item,
          onPressed: () {
            _focusNode.unfocus();
            handleNavigation(
              TypeConstants.track,
              [item.id, item.path],
              context,
              ref: ref,
            );
          },
        );
      },
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.label,
    required this.count,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TvFocusCard(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (selected) ...[
            const Icon(Icons.check_rounded, size: 24),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackResultCard extends StatelessWidget {
  const _PackResultCard({required this.item, required this.onPressed});

  final PackItem item;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TvFocusCard(
      onPressed: onPressed,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.coverUrl.isNotEmpty)
            NetworkImageWidget(url: item.coverUrl, shouldCache: true)
          else
            Container(color: Theme.of(context).cardColor),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xE6000000)],
                stops: [0.32, 1],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackResultCard extends StatelessWidget {
  const _TrackResultCard({required this.item, required this.onPressed});

  final TrackItem item;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TvFocusCard(
      onPressed: onPressed,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 96,
              height: 96,
              child: item.coverUrl.isEmpty
                  ? Container(color: theme.colorScheme.surfaceContainerHighest)
                  : NetworkImageWidget(
                      url: item.coverUrl,
                      shouldCache: true,
                    ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.chevron_right_rounded, size: 34),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      label,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.58),
      ),
    ),
  );
}

class _RetryState extends StatelessWidget {
  const _RetryState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 220,
      child: TvFocusCard(
        autofocus: true,
        onPressed: onRetry,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh_rounded, size: 28),
            SizedBox(width: 10),
            Text('Retry', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    ),
  );
}
