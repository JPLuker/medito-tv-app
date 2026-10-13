import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:medito/constants/types/type_constants.dart';
import 'package:medito/providers/explore/track_search_provider.dart';
import 'package:medito/routes/routes.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';
import 'package:medito/widgets/network_image_widget.dart';

/// iPad-style Explore page adapted for a remote. The masonry grid, separate
/// artwork/text surfaces and four-column rhythm intentionally follow the
/// tablet build rather than the older full-bleed TV cards.
class TvExploreView extends ConsumerStatefulWidget {
  const TvExploreView({super.key});

  @override
  ConsumerState<TvExploreView> createState() => _TvExploreViewState();
}

class _TvExploreViewState extends ConsumerState<TvExploreView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(explorePacksProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final packs = ref.watch(explorePacksProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 38, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: packs.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (_, _) => Center(
                        child: SizedBox(
                          width: 220,
                          child: TvFocusCard(
                            autofocus: true,
                            onPressed: () => ref.invalidate(explorePacksProvider),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 18,
                            ),
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
                      ),
                      data: (items) {
                        if (items.isEmpty) {
                          return const Center(child: Text('No packs available'));
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 1320
                                ? 4
                                : constraints.maxWidth >= 930
                                ? 3
                                : 2;

                            return MasonryGridView.count(
                              padding: const EdgeInsets.fromLTRB(4, 4, 4, 34),
                              crossAxisCount: columns,
                              mainAxisSpacing: 18,
                              crossAxisSpacing: 18,
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return TvFocusCard(
                                  borderRadius: 16,
                                  onPressed: () => handleNavigation(
                                    TypeConstants.pack,
                                    [item.id, item.path],
                                    context,
                                    ref: ref,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: item.coverUrl.isNotEmpty
                                            ? NetworkImageWidget(
                                                url: item.coverUrl,
                                                shouldCache: true,
                                              )
                                            : Container(color: theme.cardColor),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          18,
                                          15,
                                          18,
                                          17,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            if (item.subtitle.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                item.subtitle,
                                                style: theme.textTheme.bodyLarge
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(alpha: 0.72),
                                                      height: 1.32,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
        ),
      ),
    );
  }
}
