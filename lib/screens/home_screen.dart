import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tedu_qrcode/providers/qr_provider.dart';
import 'package:tedu_qrcode/providers/wallpaper_provider.dart';
import 'package:tedu_qrcode/screens/scan_screen.dart';
import 'package:tedu_qrcode/widgets/app_drawer.dart';
import 'package:tedu_qrcode/widgets/loading_overlay.dart';
import 'package:tedu_qrcode/widgets/qr_display_card.dart';

/// The main screen. Shows the daily QR code or an empty-state prompt.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final qrProvider = context.watch<QrProvider>();
    final wallpaperProvider = context.watch<WallpaperProvider>();

    return LoadingOverlay(
      isLoading: qrProvider.isLoading || wallpaperProvider.isProcessing,
      message: wallpaperProvider.isProcessing ? 'Setting wallpaper…' : null,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KEDU QR Code'),
          centerTitle: true,
        ),
        drawer: const AppDrawer(),
        body: qrProvider.hasKey
            ? _QrBody(qrData: qrProvider.qrCodeData!.formattedData)
            : const _EmptyState(),
        // FAB for quickly toggling the wallpaper overlay
        floatingActionButton: qrProvider.hasKey
            ? _WallpaperFab(
                isActive: wallpaperProvider.isAutoWallpaperSet,
                isProcessing: wallpaperProvider.isProcessing,
                onTap: () async {
                  await wallpaperProvider.setAutoWallpaper(
                    enabled: !wallpaperProvider.isAutoWallpaperSet,
                    data: qrProvider.qrCodeData,
                  );
                  if (wallpaperProvider.errorMessage != null &&
                      context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(wallpaperProvider.errorMessage!),
                        backgroundColor:
                            Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                },
              )
            : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wallpaper toggle FAB
// ---------------------------------------------------------------------------

class _WallpaperFab extends StatelessWidget {
  final bool isActive;
  final bool isProcessing;
  final VoidCallback onTap;

  const _WallpaperFab({
    required this.isActive,
    required this.isProcessing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return FloatingActionButton.extended(
      onPressed: isProcessing ? null : onTap,
      backgroundColor:
          isActive ? colors.primaryContainer : colors.surfaceContainerHighest,
      foregroundColor:
          isActive ? colors.onPrimaryContainer : colors.onSurfaceVariant,
      icon: isProcessing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(isActive ? Icons.wallpaper : Icons.wallpaper_outlined),
      label: Text(isActive ? 'Wallpaper On' : 'Set Wallpaper'),
    );
  }
}

// ---------------------------------------------------------------------------
// QR code body (shown when a key exists)
// ---------------------------------------------------------------------------

class _QrBody extends StatelessWidget {
  final String qrData;

  const _QrBody({required this.qrData});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String today = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date chip
            Center(
              child: Chip(
                avatar: Icon(Icons.calendar_today_outlined,
                    size: 16, color: colors.onSecondaryContainer),
                label: Text(
                  today,
                  style: TextStyle(color: colors.onSecondaryContainer),
                ),
                backgroundColor: colors.secondaryContainer,
              ),
            ),
            const SizedBox(height: 8),

            // Expiry label
            Center(
              child: Text(
                'Valid until 23:59 today',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 24),

            // QR Card
            QrDisplayCard(qrData: qrData),

            const SizedBox(height: 16),

            // Tip
            Center(
              child: Text(
                'Open the drawer to manage settings',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state (shown when no key is stored)
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2_outlined,
              size: 96,
              color: colors.outlineVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No Key Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Scan your QR code from the KEDU app to get started.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              ),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
