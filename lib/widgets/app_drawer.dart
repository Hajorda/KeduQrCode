import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tedu_qrcode/constants/app_constants.dart';
import 'package:tedu_qrcode/providers/qr_provider.dart';
import 'package:tedu_qrcode/providers/theme_provider.dart';
import 'package:tedu_qrcode/providers/wallpaper_provider.dart';
import 'package:tedu_qrcode/providers/geofence_provider.dart';
import 'package:tedu_qrcode/screens/menu_screen.dart';
import 'package:tedu_qrcode/screens/scan_screen.dart';

/// The app's side drawer with grouped settings, actions, and about section.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final qrProvider = context.watch<QrProvider>();
    final wallpaperProvider = context.watch<WallpaperProvider>();
    final geofenceProvider = context.watch<GeofenceProvider>();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _DrawerHeader(isDarkMode: themeProvider.isDarkMode),
          // --- Settings ---
          const _SectionLabel('Settings'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: themeProvider.isDarkMode,
            onChanged: (_) => themeProvider.toggleTheme(),
          ),
          SwitchListTile(
            title: const Text('Auto Set Wallpaper'),
            subtitle: const Text('Overlays your QR on the lock screen'),
            secondary: wallpaperProvider.isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wallpaper_outlined),
            value: wallpaperProvider.isAutoWallpaperSet,
            onChanged: wallpaperProvider.isProcessing
                ? null
                : (value) async {
                    await wallpaperProvider.setAutoWallpaper(
                      enabled: value,
                      data: qrProvider.qrCodeData,
                    );
                    if (wallpaperProvider.errorMessage != null &&
                        context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(wallpaperProvider.errorMessage!),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  },
          ),
          SwitchListTile(
            title: const Text('Show QR at Gate'),
            subtitle: const Text('Notifies you when arriving at university'),
            secondary: geofenceProvider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.location_on_outlined),
            value: geofenceProvider.isGeofenceEnabled,
            onChanged: geofenceProvider.isLoading
                ? null
                : (value) async {
                    final success =
                        await geofenceProvider.setGeofenceEnabled(value);
                    if (value && !success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Permissions required to enable Gate Notification.'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  },
          ),
          const Divider(),
          // --- Actions ---
          const _SectionLabel('Actions'),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner_outlined),
            title: const Text('Scan QR Code'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu_outlined),
            title: const Text('Günün Menüsü'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MenuScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete Key'),
            onTap: () {
              Navigator.pop(context);
              _showDeleteDialog(context, qrProvider);
            },
          ),
          const Divider(),
          // --- About ---
          const _SectionLabel('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Info'),
            onTap: () {
              Navigator.pop(context);
              _showInfoDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, QrProvider qrProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Key'),
        content: const Text('Are you sure you want to delete the stored key? '
            'You will need to scan your QR code again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await qrProvider.deleteKey();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Key deleted'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppConstants.appName),
        content: const Text(
          'KEDU QR Code generates your daily gate access QR code.\n\n'
          'Scan your QR code from the official KEDU app once — '
          'this app will then generate a fresh, time-stamped QR each day '
          'so you can enter the gate without opening the original app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// A small label that groups drawer sections visually.
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _DrawerHeader extends StatefulWidget {
  final bool isDarkMode;
  const _DrawerHeader({required this.isDarkMode});

  @override
  State<_DrawerHeader> createState() => _DrawerHeaderState();
}

class _DrawerHeaderState extends State<_DrawerHeader> {
  int _tapCount = 0;
  Timer? _tapTimer;

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }

  void _handleAvatarTap(BuildContext context) {
    _tapCount++;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(seconds: 2), () {
      _tapCount = 0;
    });

    if (_tapCount >= 5) {
      _tapCount = 0;
      _tapTimer?.cancel();
      _showManualIdDialog(context);
    }
  }

  void _showManualIdDialog(BuildContext context) {
    final qrProvider = context.read<QrProvider>();
    final controller =
        TextEditingController(text: qrProvider.qrCodeData?.userKey);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manual ID Override'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.text,
            maxLength: 8,
            decoration: const InputDecoration(
              labelText: '8-Character ID',
              hintText: 'Enter your exactly 8-Character ID',
            ),
            validator: (value) {
              if (value == null ||
                  value.length != 8 ||
                  !RegExp(r'^[a-zA-Z0-9]{8}$').hasMatch(value)) {
                return 'Please enter exactly 8 alphanumeric characters';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                await qrProvider.saveKeyManually(controller.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ID updated manually'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return DrawerHeader(
      decoration: BoxDecoration(color: colors.primaryContainer),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () => _handleAvatarTap(context),
            child: CircleAvatar(
              radius: 32,
              backgroundImage: const AssetImage(AppConstants.logoAsset),
              backgroundColor: colors.onPrimaryContainer.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
