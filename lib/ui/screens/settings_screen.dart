import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/app_state.dart';
import '../widgets/ziba_logo.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final adapter = ref.read(wallpaperAdapterProvider);
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: true,
          title: Text('SETTINGS'),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 32, bottom: 8),
            child: Center(child: ZibaLogo(size: 48)),
          ),
        ),
        const SliverToBoxAdapter(child: Divider()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Platform info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PLATFORM',
                        style: theme.textTheme.labelSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            adapter.isSupported
                                ? Icons.check_circle
                                : Icons.warning,
                            size: 16,
                            color: adapter.isSupported
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              adapter.isSupported
                                  ? 'Wallpaper setting supported'
                                  : adapter.limitations,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Startup
                Text('STARTUP', style: theme.textTheme.labelSmall),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Launch at login',
                      style: theme.textTheme.bodyLarge),
                  subtitle: Text('Start Ziba automatically when you log in',
                      style: theme.textTheme.bodyMedium),
                  value: settings.launchAtLogin,
                  onChanged: (v) => notifier.setLaunchAtLogin(v),
                ),

                const SizedBox(height: 32),

                // Auto rotation
                Text('ROTATION', style: theme.textTheme.labelSmall),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Auto-rotate wallpaper',
                      style: theme.textTheme.bodyLarge),
                  subtitle: Text('Change wallpaper automatically',
                      style: theme.textTheme.bodyMedium),
                  value: settings.autoRotate,
                  onChanged: (v) => notifier.setAutoRotate(v),
                ),

                const SizedBox(height: 8),

                // Interval
                if (settings.autoRotate)
                  _IntervalSelector(
                    current: settings.rotationInterval,
                    onChanged: notifier.setInterval,
                  ),

                const SizedBox(height: 32),

                // Orientation
                Text('DISPLAY', style: theme.textTheme.labelSmall),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Prefer landscape',
                      style: theme.textTheme.bodyLarge),
                  subtitle: Text(
                      'Only pick artworks wider than tall (desktop)',
                      style: theme.textTheme.bodyMedium),
                  value: settings.preferLandscape,
                  onChanged: (v) => notifier.setPreferLandscape(v),
                ),

                const SizedBox(height: 32),

                // Art movements filter
                Text('ART MOVEMENTS', style: theme.textTheme.labelSmall),
                const SizedBox(height: 8),
                Text(
                  'Filter artworks by movement. Leave empty for all.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _artMovements.map((movement) {
                    final isSelected =
                        settings.artMovementFilter.contains(movement);
                    return FilterChip(
                      label: Text(movement,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 11,
                          )),
                      selected: isSelected,
                      onSelected: (_) =>
                          notifier.toggleArtMovement(movement),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 48),

                // About
                Text('ABOUT', style: theme.textTheme.labelSmall),
                const SizedBox(height: 12),
                Text('Ziba v0.1.0', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  'Your screen. Their masterpiece.',
                  style: theme.textTheme.bodyMedium,
                ),

                const SizedBox(height: 32),

                // Credits
                Text('CREDITS', style: theme.textTheme.labelSmall),
                const SizedBox(height: 12),
                const _CreditRow(label: 'Artwork', value: 'WikiArt.org'),
                const SizedBox(height: 8),
                const _CreditRow(label: 'Built with', value: 'Flutter'),
                const SizedBox(height: 8),
                const _CreditRow(
                    label: 'Made by', value: 'Electric Sheep Supply Co.'),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IntervalSelector extends StatelessWidget {
  final Duration current;
  final ValueChanged<Duration> onChanged;

  const _IntervalSelector({
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = [
      (label: '1 hour', duration: const Duration(hours: 1)),
      (label: '6 hours', duration: const Duration(hours: 6)),
      (label: '12 hours', duration: const Duration(hours: 12)),
      (label: '24 hours', duration: const Duration(hours: 24)),
      (label: '3 days', duration: const Duration(days: 3)),
      (label: '7 days', duration: const Duration(days: 7)),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = current == opt.duration;
        return ChoiceChip(
          label: Text(opt.label,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
          selected: isSelected,
          onSelected: (_) => onChanged(opt.duration),
        );
      }).toList(),
    );
  }
}

class _CreditRow extends StatelessWidget {
  final String label;
  final String value;

  const _CreditRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

const _artMovements = [
  'Impressionism',
  'Post-Impressionism',
  'Expressionism',
  'Surrealism',
  'Abstract Expressionism',
  'Baroque',
  'Romanticism',
  'Realism',
  'Neo-Impressionism',
  'Symbolism',
  'Art Nouveau',
  'Rococo',
  'Neoclassicism',
  'Pre-Raphaelite',
  'Naive Art',
];
