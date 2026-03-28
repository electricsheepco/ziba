import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../state/app_state.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('FAVORITES'),
        ),
        favoritesAsync.when(
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
                      Icon(Icons.favorite_outline, size: 48,
                          color: theme.colorScheme.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text('No favorites yet',
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text('Tap the heart on any artwork to save it',
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
                    final artwork = items[index];
                    return _FavoriteCard(
                      imageUrl: artwork.imageUrl,
                      title: artwork.title,
                      artist: artwork.artistName,
                      contentId: artwork.contentId,
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

class _FavoriteCard extends ConsumerWidget {
  final String imageUrl;
  final String title;
  final String artist;
  final int contentId;

  const _FavoriteCard({
    required this.imageUrl,
    required this.title,
    required this.artist,
    required this.contentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GestureDetector(
      onLongPress: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove favorite?'),
            content: Text('Remove "$title" from favorites?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('REMOVE'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          ref.read(databaseProvider).removeFavorite(contentId);
        }
      },
      child: Column(
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
      ),
    );
  }
}
