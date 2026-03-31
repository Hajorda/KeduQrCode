import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tedu_qrcode/providers/qr_provider.dart';

/// Full-screen flow for scanning a QR code from a gallery image.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  XFile? _selectedImage;
  String? _status;
  bool _isSuccess = false;

  Future<void> _pickImage() async {
    // Capture the provider before any await to avoid stale context issues
    final qrProvider = context.read<QrProvider>();

    final XFile? image =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _selectedImage = image;
      _status = null;
    });

    final String? error = await qrProvider.scanAndSaveKey(image);

    setState(() {
      if (error == null) {
        _isSuccess = true;
        _status = 'QR code scanned and saved successfully!';
      } else {
        _isSuccess = false;
        _status = error;
      }
    });

    if (_isSuccess && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isLoading = context.watch<QrProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Instructions card ---
            Card(
              color: colors.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: colors.onSecondaryContainer),
                        const SizedBox(width: 8),
                        Text(
                          'How to scan',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: colors.onSecondaryContainer),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Open the official KEDU app\n'
                      '2. Take a screenshot of your QR code\n'
                      '3. Tap "Select Image" below and choose that screenshot',
                      style: TextStyle(color: colors.onSecondaryContainer),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Image preview or placeholder ---
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.outlineVariant,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          File(_selectedImage!.path),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.image_not_supported, size: 48),
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined,
                              size: 64, color: colors.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text(
                            'No image selected',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Status message ---
            if (_status != null)
              AnimatedOpacity(
                opacity: 1,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isSuccess
                        ? Colors.green.withValues(alpha: 0.1)
                        : colors.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSuccess ? Icons.check_circle : Icons.error_outline,
                        color: _isSuccess ? Colors.green : colors.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _status!,
                          style: TextStyle(
                            color: _isSuccess
                                ? Colors.green
                                : colors.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // --- Action button ---
            FilledButton.icon(
              onPressed: isLoading ? null : _pickImage,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.photo_library_outlined),
              label: Text(isLoading ? 'Scanning...' : 'Select Image'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
