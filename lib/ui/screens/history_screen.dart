import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../state/app_state.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('HISTORY'),
        ),
        historyAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(strokeWidth: 1)),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(child: Text('Error: $e')),
          ),
          data: (items) {
            if (items.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 48,
                          color: theme.colorScheme.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text('No history yet',
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text('Refresh to get your first artwork',
                          style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    return _HistoryCard(
                      imageUrl: item.artwork.imageUrl,
                      title: item.artwork.title,
                      artist: item.artwork.artistName,
                      setAt: item.history.setAt,
                    );
                  },
                  childCount: items.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String artist;
  final DateTime setAt;

  const _HistoryCard({
    required this.imageUrl,
    required this.title,
    required this.artist,
    required this.setAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, __) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              errorWidget: (_, __, ___) => Container(
                color: theme.colorScheme.errorContainer,
                child: const Icon(Icons.broken_image, size: 20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          artist,
          style: theme.textTheme.labelSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
