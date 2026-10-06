import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medito/constants/types/type_constants.dart';
import 'package:medito/models/home/home_model.dart';
import 'package:medito/models/home/shortcuts/shortcuts_model.dart';
import 'package:medito/providers/home/up_next_provider.dart';
import 'package:medito/providers/providers.dart';
import 'package:medito/routes/routes.dart';
import 'package:medito/utils/utils.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';
import 'package:medito/widgets/network_image_widget.dart';

/// TV home keeps the same vertical section rhythm as Medito's adaptive tablet
/// home and caps the readable/content width rather than stretching shelves
/// across the full television panel.
class TvHomeView extends ConsumerWidget {
  const TvHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(fetchHomeProvider);
    final upNext = ref.watch(upNextProvider);

    return Scaffold(
      body: SafeArea(
        child: home.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: ElevatedButton(
              onPressed: () => ref.invalidate(refreshHomeAPIsProvider),
              child: const Text('Retry'),
            ),
          ),
          data: (homeData) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(40, 28, 40, 56),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homeData.greeting?.trim().isNotEmpty == true
                          ? homeData.greeting!
                          : 'Medito',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _UpNextHero(upNext: upNext),
                    if (_tvCarouselItems(homeData.carousel).isNotEmpty) ...[
                      const SizedBox(height: 34),
                      _CarouselShelf(
                        items: _tvCarouselItems(homeData.carousel),
                      ),
                    ],
                    if (_tvShortcuts(homeData.shortcuts).isNotEmpty) ...[
                      const SizedBox(height: 34),
                      _ShortcutShelf(
                        items: _tvShortcuts(homeData.shortcuts),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<HomeCarouselModel> _tvCarouselItems(List<HomeCarouselModel> items) {
    return items.where((item) => !_isPhoneOnly(item.type, item.path)).toList();
  }

  List<ShortcutsModel> _tvShortcuts(List<ShortcutsModel> items) {
    return items.where((item) => !_isPhoneOnly(item.type, item.path)).toList();
  }

  bool _isPhoneOnly(String? type, String? path) {
    return type == TypeConstants.url ||
        type == TypeConstants.link ||
        type == TypeConstants.email ||
        type == 'donation' ||
        (type == TypeConstants.route && path == RouteConstants.donation) ||
        (type == TypeConstants.route &&
            path?.contains(RouteConstants.stats) == true);
  }
}

class _UpNextHero extends ConsumerWidget {
  const _UpNextHero({required this.upNext});

  final AsyncValue<UpNextData> upNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return upNext.when(
      loading: () => const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        final session = data.nextSession;
        if (session == null) {
          return Container(
            height: 190,
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.pack.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  data.isCompleted
                      ? 'You have completed this path.'
                      : 'Choose something to meditate with.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        final cover = session.coverUrl ?? data.pack.coverUrl;

        return TvFocusCard(
          borderRadius: 20,
          onPressed: () => handleNavigation(
            session.type,
            [session.id],
            context,
            ref: ref,
          ),
          child: SizedBox(
            height: 280,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (cover != null && cover.isNotEmpty)
                  NetworkImageWidget(url: cover, shouldCache: true)
                else
                  Container(color: Theme.of(context).cardColor),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.transparent,
                        Color(0x99000000),
                        Color(0xEE000000),
                      ],
                      stops: [0.15, 0.58, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 650),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONTINUE YOUR PATH · ${data.pack.title}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Colors.white70,
                                  letterSpacing: 1.2,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            session.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          if (session.subtitle?.isNotEmpty == true) ...[
                            const SizedBox(height: 10),
                            Text(
                              session.subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                          const SizedBox(height: 22),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.black,
                                  size: 34,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'Play',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CarouselShelf extends ConsumerWidget {
  const _CarouselShelf({required this.items});

  final List<HomeCarouselModel> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _TvShelf(
      title: 'Featured',
      height: 190,
      children: items.map((item) {
        return SizedBox(
          width: 290,
          child: TvFocusCard(
            onPressed: () => handleNavigation(
              item.type,
              [item.path.toString().getIdFromPath(), item.path],
              context,
              ref: ref,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetworkImageWidget(url: item.coverUrl, shouldCache: true),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xDD000000)],
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ShortcutShelf extends ConsumerWidget {
  const _ShortcutShelf({required this.items});

  final List<ShortcutsModel> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return _TvShelf(
      title: 'Quick access',
      height: 112,
      children: items.map((item) {
        return SizedBox(
          width: 235,
          child: TvFocusCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            onPressed: () => handleNavigation(
              item.type,
              [item.path.toString().getIdFromPath(), item.path],
              context,
              ref: ref,
            ),
            child: Row(
              children: [
                Icon(
                  item.isHighlighted ? Icons.play_circle_fill : Icons.spa,
                  size: 32,
                  color: onSurface,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.title ?? 'Meditate',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TvShelf extends StatelessWidget {
  const _TvShelf({
    required this.title,
    required this.height,
    required this.children,
  });

  final String title;
  final double height;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: children.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (_, index) => children[index],
          ),
        ),
      ],
    );
  }
}
