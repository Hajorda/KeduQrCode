import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scan/scan.dart';
import 'package:tedu_qrcode/constants/app_constants.dart';
import 'package:tedu_qrcode/models/qr_code_data.dart';

/// Handles QR code generation and parsing.
class QrService {
  /// Generates a PNG image of the QR code for [data] and returns the temp [File].
  /// Returns null if generation fails for any reason.
  Future<File?> generateQrImage(QrCodeData data) async {
    if (data.formattedData.isEmpty) {
      debugPrint('QrService.generateQrImage: QR data is empty');
      return null;
    }

    try {
      final ByteData? qrImage = await QrPainter(
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
        data: data.formattedData,
        gapless: true,
      ).toImageData(AppConstants.qrImageSize.toDouble());

      final buffer = qrImage?.buffer;
      if (buffer == null || qrImage == null) {
        debugPrint('QrService.generateQrImage: buffer is null');
        return null;
      }

      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/qr_image.tmp';
      return File(filePath).writeAsBytes(
        buffer.asUint8List(qrImage.offsetInBytes, qrImage.lengthInBytes),
      );
    } catch (e) {
      debugPrint('QrService.generateQrImage error: $e');
      return null;
    }
  }

  /// Scans the image at [imagePath] and returns the raw QR string, or null.
  Future<String?> parseQrFromImage(String imagePath) async {
    try {
      return await Scan.parse(imagePath);
    } catch (e) {
      debugPrint('QrService.parseQrFromImage error: $e');
      return null;
    }
  }

  /// Returns true if [value] matches the expected QR format.
  bool validateQrFormat(String value) => QrCodeData.isValidFormat(value);

  /// Extracts the 8-digit key from a validated QR string.
  String extractKey(String rawQrValue) => QrCodeData.extractKey(rawQrValue);
}
