import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medito/constants/constants.dart';
import 'package:medito/models/home/home_model.dart';
import 'package:medito/models/home/product/product_model.dart';
import 'package:medito/models/home/shortcuts/shortcuts_model.dart';
import 'package:medito/providers/home/products_provider.dart';
import 'package:medito/providers/home/up_next_provider.dart';
import 'package:medito/providers/providers.dart';
import 'package:medito/routes/routes.dart';
import 'package:medito/utils/utils.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';
import 'package:medito/widgets/medito_icon.dart';
import 'package:medito/widgets/network_image_widget.dart';
import 'package:url_launcher/url_launcher.dart';

/// TV Home follows the current iPad composition closely: course/up-next first,
/// then the icon shortcut row, Featured artwork, the daily quote and Shop to
/// Support. TV-specific behavior is limited to larger targets and D-pad focus.
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
            child: SizedBox(
              width: 220,
              child: TvFocusCard(
                autofocus: true,
                onPressed: () => ref.invalidate(refreshHomeAPIsProvider),
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
          ),
          data: (homeData) {
            final shortcuts = _tvShortcuts(homeData.shortcuts);
            final featured = _tvCarouselItems(homeData.carousel);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 26, 40, 64),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (homeData.greeting?.trim().isNotEmpty == true) ...[
                        Text(
                          homeData.greeting!,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      _UpNextHero(upNext: upNext),
                      if (shortcuts.isNotEmpty) ...[
                        const SizedBox(height: 30),
                        _ShortcutShelf(items: shortcuts),
                      ],
                      if (featured.isNotEmpty) ...[
                        const SizedBox(height: 36),
                        _FeaturedShelf(items: featured),
                      ],
                      if (homeData.todayQuote != null) ...[
                        const SizedBox(height: 42),
                        _QuoteSection(quote: homeData.todayQuote!),
                      ],
                      const SizedBox(height: 42),
                      const _ShopShelf(),
                    ],
                  ),
                ),
              ),
            );
          },
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
        height: 230,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        final session = data.nextSession;
        if (session == null) {
          return Container(
            height: 160,
            width: double.infinity,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.20),
              ),
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
          borderRadius: 18,
          onPressed: () => handleNavigation(
            session.type,
            [session.id],
            context,
            ref: ref,
          ),
          child: SizedBox(
            height: 240,
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
                        Color(0x88000000),
                        Color(0xEE000000),
                      ],
                      stops: [0.18, 0.58, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 690),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONTINUE YOUR PATH · ${data.pack.title}',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white70,
                              letterSpacing: 1.15,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            session.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (session.subtitle?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Text(
                              session.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
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

class _ShortcutShelf extends ConsumerWidget {
  const _ShortcutShelf({required this.items});

  final List<ShortcutsModel> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: 142,
            child: Column(
              children: [
                SizedBox(
                  width: 112,
                  height: 96,
                  child: TvFocusCard(
                    autofocus: index == 0,
                    borderRadius: 16,
                    onPressed: () => handleNavigation(
                      item.type,
                      [item.path.toString().getIdFromPath(), item.path],
                      context,
                      ref: ref,
                    ),
                    child: Center(
                      child: MeditoRemoteIcon(
                        icon: item.icon ?? '',
                        size: 38,
                        color: onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  item.title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FeaturedShelf extends ConsumerWidget {
  const _FeaturedShelf({required this.items});

  final List<HomeCarouselModel> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Featured',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 236,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 18),
            itemBuilder: (context, index) {
              final item = items[index];
              return SizedBox(
                width: 345,
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
                            colors: [Colors.transparent, Color(0xB9000000)],
                            stops: [0.48, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 15,
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuoteSection extends StatelessWidget {
  const _QuoteSection({required this.quote});

  final HomeQuoteModel quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1220),
        child: Column(
          children: [
            Text(
              quote.quote,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '— ${quote.author}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopShelf extends ConsumerWidget {
  const _ShopShelf();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);

    return products.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final visible = items.take(10).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Shop to Support',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  width: 136,
                  child: TvFocusCard(
                    onPressed: () => unawaited(
                      _openUrl(context, ConfigConstants.shopUrl),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('See all', style: TextStyle(fontSize: 17)),
                        SizedBox(width: 6),
                        Icon(Icons.chevron_right_rounded, size: 22),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 272,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: visible.length,
                separatorBuilder: (_, _) => const SizedBox(width: 18),
                itemBuilder: (context, index) => _ProductTile(
                  product: visible[index],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _openUrl(BuildContext context, String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This link is not available on this TV.')),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final ProductGroupModel product;

  @override
  Widget build(BuildContext context) {
    final image = product.displayImageUrl ?? product.imageUrl;

    return SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            height: 190,
            child: TvFocusCard(
              onPressed: () => unawaited(
                _ShopShelf._openUrl(context, product.url),
              ),
              child: image != null && image.isNotEmpty
                  ? NetworkImageWidget(url: image, shouldCache: true)
                  : const Center(
                      child: Icon(Icons.shopping_bag_outlined, size: 48),
                    ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 2),
          Text(
            'From ${_formatPrice(product)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatPrice(ProductGroupModel product) {
    final symbol = switch (product.currency.toUpperCase()) {
      'USD' => r'$',
      'GBP' => '£',
      'EUR' => '€',
      _ => '${product.currency} ',
    };
    final price = product.basePrice;
    final digits = price == price.roundToDouble() ? 0 : 2;
    return '$symbol${price.toStringAsFixed(digits)}';
  }
}
