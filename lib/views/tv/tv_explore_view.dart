import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medito/constants/types/type_constants.dart';
import 'package:medito/providers/explore/track_search_provider.dart';
import 'package:medito/routes/routes.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';
import 'package:medito/widgets/network_image_widget.dart';

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 28, 40, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explore',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Browse meditation packs',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: packs.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (_, _) => Center(
                    child: ElevatedButton(
                      onPressed: () => ref.invalidate(explorePacksProvider),
                      child: const Text('Retry'),
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(child: Text('No packs available'));
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 32),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 320,
                            mainAxisExtent: 210,
                            mainAxisSpacing: 18,
                            crossAxisSpacing: 18,
                          ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return TvFocusCard(
                          onPressed: () => handleNavigation(
                            TypeConstants.pack,
                            [item.id, item.path],
                            context,
                            ref: ref,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              NetworkImageWidget(
                                url: item.coverUrl,
                                shouldCache: true,
                              ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Color(0xE6000000),
                                    ],
                                    stops: [0.35, 1],
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
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (item.subtitle.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall?.copyWith(
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
}
