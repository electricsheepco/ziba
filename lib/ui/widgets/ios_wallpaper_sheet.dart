import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bottom sheet shown after saving an artwork to Photos on iOS.
///
/// iOS has no programmatic wallpaper API, so the user must open
/// Settings → Wallpaper → Add New Wallpaper manually.
class IOSWallpaperSheet extends StatelessWidget {
  const IOSWallpaperSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const IOSWallpaperSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SAVED TO PHOTOS', style: theme.textTheme.labelSmall),
            const SizedBox(height: 12),
            Text(
              'Set it as your wallpaper:',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const _Step(number: '1', text: 'Open Settings → Wallpaper'),
            const _Step(number: '2', text: 'Tap "Add New Wallpaper"'),
            const _Step(number: '3', text: 'Choose "Photos" and select the artwork'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings_outlined, size: 16),
                label: const Text('OPEN SETTINGS'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6B8EC4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    // Deep-link to wallpaper settings on iOS 16+; falls back to generic Settings.
    final wallpaperUri = Uri.parse('App-prefs:Wallpaper');
    final settingsUri = Uri.parse('app-settings:');
    if (await canLaunchUrl(wallpaperUri)) {
      await launchUrl(wallpaperUri);
    } else if (await canLaunchUrl(settingsUri)) {
      await launchUrl(settingsUri);
    }
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF6B8EC4).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: const Color(0xFF6B8EC4)),
            ),
          ),
          const SizedBox(width: 12),
          Text(text, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
