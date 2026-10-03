import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medito/constants/constants.dart';
import 'package:medito/models/models.dart';
import 'package:medito/providers/providers.dart';
import 'package:medito/routes/routes.dart';
import 'package:medito/views/tv/widgets/tv_focus_card.dart';
import 'package:medito/views/tv/widgets/tv_submenu_scaffold.dart';
import 'package:medito/widgets/markdown_widget.dart';
import 'package:medito/widgets/network_image_widget.dart';

/// Android TV / Google TV presentation for a meditation pack.
///
/// The mobile pack screen is intentionally left untouched. This surface uses
/// large remote-focusable rows, couch-distance typography and the shared TV
/// submenu frame so navigating deeper from Home does not fall back to a phone
/// layout.
class TvPackView extends ConsumerStatefulWidget {
  const TvPackView({super.key, required this.id});

  final String id;

  @override
  ConsumerState<TvPackView> createState() => _TvPackViewState();
}

class _TvPackViewState extends ConsumerState<TvPackView> {
  bool _markingAll = false;

  @override
  Widget build(BuildContext context) {
    final pack = ref.watch(packProvider(packId: widget.id));

    return pack.when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      loading: () => const TvSubmenuScaffold(
        title: 'Meditations',
        child: SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => TvSubmenuScaffold(
        title: 'Meditations',
        subtitle: 'This collection could not be loaded.',
        child: SizedBox(
          width: 240,
          child: TvFocusCard(
            autofocus: true,
            onPressed: () => ref.refresh(packDataProvider(packId: widget.id)),
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
      data: _buildPack,
    );
  }

  Widget _buildPack(PackModel pack) {
    final theme = Theme.of(context);
    final items = pack.items.where((item) => !_isPhoneOnly(item.type)).toList();

    return TvSubmenuScaffold(
      title: pack.title,
      maxContentWidth: 1320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((pack.coverUrl?.isNotEmpty ?? false) ||
              (pack.description?.trim().isNotEmpty ?? false)) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pack.coverUrl?.isNotEmpty == true) ...[
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.25),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: NetworkImageWidget(
                        url: pack.coverUrl!,
                        shouldCache: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
                if (pack.description?.trim().isNotEmpty == true)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: MarkdownWidget(
                        body: pack.description!,
                        selectable: false,
                        p: theme.textTheme.titleLarge?.copyWith(
                          height: 1.45,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.76,
                          ),
                        ),
                        a: theme.textTheme.titleLarge?.copyWith(
                          height: 1.45,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.76,
                          ),
                          decoration: TextDecoration.none,
                        ),
                        onTapLink: null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 36),
          ],
          Text(
            'Sessions',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text(
              'There are no TV-compatible sessions in this collection.',
              style: theme.textTheme.titleLarge,
            )
          else
            ...[
              for (var index = 0; index < items.length; index++) ...[
                _TvPackItemCard(
                  item: items[index],
                  autofocus: index == 0,
                  onPressed: () => handleNavigation(
                    items[index].type,
                    [items[index].id],
                    context,
                    ref: ref,
                  ),
                ),
                if (index != items.length - 1) const SizedBox(height: 14),
              ],
            ],
          const SizedBox(height: 28),
          _buildMarkAll(pack),
        ],
      ),
    );
  }

  Widget _buildMarkAll(PackModel pack) {
    final trackItems = pack.items
        .where((item) => item.type == TypeConstants.track)
        .toList();
    if (trackItems.isEmpty) return const SizedBox.shrink();

    final allComplete = trackItems.every((item) => item.isCompleted == true);

    return SizedBox(
      width: 330,
      child: TvFocusCard(
        onPressed: _markingAll ? () {} : () => _markAll(!allComplete),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_markingAll)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(allComplete ? Icons.remove_done : Icons.done_all, size: 28),
            const SizedBox(width: 12),
            Text(
              allComplete ? 'Mark all incomplete' : 'Mark all complete',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAll(bool complete) async {
    if (_markingAll) return;
    setState(() => _markingAll = true);
    try {
      await ref
          .read(packProvider(packId: widget.id).notifier)
          .markAll(complete: complete);
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  bool _isPhoneOnly(String type) {
    return type == TypeConstants.url ||
        type == TypeConstants.link ||
        type == TypeConstants.email ||
        type == 'donation';
  }
}

class _TvPackItemCard extends StatelessWidget {
  const _TvPackItemCard({
    required this.item,
    required this.onPressed,
    this.autofocus = false,
  });

  final PackItemsModel item;
  final VoidCallback onPressed;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTrack = item.type == TypeConstants.track;
    final isComplete = item.isCompleted == true;

    return TvFocusCard(
      autofocus: autofocus,
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      child: Row(
        children: [
          Icon(
            isTrack ? Icons.self_improvement_rounded : Icons.folder_rounded,
            size: 38,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.subtitle?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isTrack && isComplete) ...[
            Icon(
              Icons.check_circle_rounded,
              size: 30,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
          ],
          const Icon(Icons.chevron_right_rounded, size: 34),
        ],
      ),
    );
  }
}
