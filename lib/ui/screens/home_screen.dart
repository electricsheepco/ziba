import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../state/app_state.dart';
import 'history_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _ArtworkView(),
          HistoryScreen(),
          FavoritesScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.palette_outlined),
            selectedIcon: Icon(Icons.palette),
            label: 'TODAY',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'HISTORY',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'SAVED',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'SETTINGS',
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Main artwork view
// ══════════════════════════════════════════════════

class _ArtworkView extends ConsumerWidget {
  const _ArtworkView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artworkAsync = ref.watch(currentArtworkProvider);
    final theme = Theme.of(context);

    return artworkAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 1),
            SizedBox(height: 16),
            Text('Fetching artwork...'),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load artwork',
                  style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text(e.toString(), style: theme.textTheme.bodyMedium),
              const SizedBox(height: 24),
              _RefreshButton(),
            ],
          ),
        ),
      ),
      data: (artwork) {
        if (artwork == null) {
          return _EmptyState();
        }
        return _ArtworkDisplay(artwork: artwork);
      },
    );
  }
}

// ══════════════════════════════════════════════════
// Empty state (first launch)
// ══════════════════════════════════════════════════

class _EmptyState extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ZIBA',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 6,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your screen.\nTheir masterpiece.',
              style: theme.textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                ref.read(currentArtworkProvider.notifier).refresh(setWallpaper: false);
              },
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('GET FIRST ARTWORK'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Artwork display (main content)
// ══════════════════════════════════════════════════

class _ArtworkDisplay extends ConsumerWidget {
  final dynamic artwork; // model.Artwork

  const _ArtworkDisplay({required this.artwork});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return CustomScrollView(
      slivers: [
        // Artwork image
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AspectRatio(
                aspectRatio: (artwork.width ?? 16) / (artwork.height ?? 9),
                child: CachedNetworkImage(
                  imageUrl: artwork.image,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 1),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: theme.colorScheme.errorContainer,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Artwork metadata
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  artwork.title,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  artwork.artistName,
                  style: theme.textTheme.bodyLarge,
                ),
                if (artwork.yearAsString != null ||
                    artwork.completitionYear != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      artwork.yearAsString ??
                          artwork.completitionYear.toString(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    // Refresh
                    _ActionButton(
                      icon: Icons.refresh,
                      label: 'NEW',
                      onTap: () {
                        ref.read(currentArtworkProvider.notifier).refresh(setWallpaper: false);
                      },
                    ),
                    const SizedBox(width: 12),
                    // Favorite
                    _ActionButton(
                      icon: Icons.favorite_border,
                      label: 'SAVE',
                      onTap: () async {
                        final db = ref.read(databaseProvider);
                        await db.addFavorite(artwork.contentId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to favorites'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    // Set wallpaper (manual)
                    _ActionButton(
                      icon: Icons.wallpaper,
                      label: 'SET',
                      onTap: () async {
                        final adapter = ref.read(wallpaperAdapterProvider);
                        if (!adapter.isSupported) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(adapter.limitations)),
                            );
                          }
                          return;
                        }
                        // Download + set
                        final wikiArt = ref.read(wikiArtProvider);
                        final path = await wikiArt.downloadImage(artwork);
                        final success = await adapter.setWallpaper(path);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Wallpaper set!'
                                  : 'Failed to set wallpaper'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════
// Reusable widgets
// ══════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefreshButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      onPressed: () {
        ref.read(currentArtworkProvider.notifier).refresh(setWallpaper: false);
      },
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('TRY AGAIN'),
    );
  }
}
