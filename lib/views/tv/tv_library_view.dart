import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medito/constants/constants.dart';
import 'package:medito/models/favorites/favorite_item.dart';
import 'package:medito/providers/favorites/favorites_provider.dart';
import 'package:medito/routes/routes.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';
import 'package:medito/widgets/network_image_widget.dart';

class TvLibraryView extends ConsumerWidget {
  const TvLibraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final favorites = ref.watch(favoritesNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 28, 40, 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Library',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your favorite meditations and packs.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: favorites.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (_, _) => Center(
                    child: ElevatedButton.icon(
                      onPressed: () => ref
                          .read(favoritesNotifierProvider.notifier)
                          .refreshFromServer(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_border_rounded,
                              size: 54,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.45,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No favorites yet',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Favorite a meditation or pack and it will appear here.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 1180 ? 4 : 3;
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 18,
                                mainAxisSpacing: 18,
                                childAspectRatio: 1.55,
                              ),
                          itemCount: items.length,
                          itemBuilder: (context, index) => _FavoriteCard(
                            item: items[index],
                            onPressed: () => _openFavorite(
                              context,
                              ref,
                              items[index],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFavorite(
    BuildContext context,
    WidgetRef ref,
    FavoriteItem item,
  ) {
    handleNavigation(
      item.type == FavoriteItemType.track
          ? TypeConstants.track
          : TypeConstants.pack,
      [item.id, item.path],
      context,
      ref: ref,
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.item, required this.onPressed});

  final FavoriteItem item;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cover = item.coverUrl;
    final isTrack = item.type == FavoriteItemType.track;

    return TvFocusCard(
      onPressed: onPressed,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cover != null && cover.isNotEmpty)
            NetworkImageWidget(
              url: cover,
              shouldCache: true,
              errorWidget: _FallbackCover(isTrack: isTrack),
            )
          else
            _FallbackCover(isTrack: isTrack),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xE6000000)],
                stops: [0.28, 1],
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
                Row(
                  children: [
                    Icon(
                      isTrack
                          ? Icons.play_circle_outline_rounded
                          : Icons.collections_bookmark_outlined,
                      size: 18,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      isTrack ? 'Meditation' : 'Pack',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.subtitle?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
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

class _FallbackCover extends StatelessWidget {
  const _FallbackCover({required this.isTrack});

  final bool isTrack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: Icon(
          isTrack ? Icons.spa_rounded : Icons.menu_book_rounded,
          size: 52,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
