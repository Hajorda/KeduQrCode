import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tedu_qrcode/models/qr_code_data.dart';
import 'package:tedu_qrcode/services/qr_service.dart';
import 'package:tedu_qrcode/services/storage_service.dart';

/// Manages the user key and the current day's QR code data.
class QrProvider extends ChangeNotifier {
  final StorageService _storageService;
  final QrService _qrService;

  QrCodeData? _qrCodeData;
  bool _isLoading = false;
  String? _errorMessage;

  QrProvider({
    required StorageService storageService,
    required QrService qrService,
  })  : _storageService = storageService,
        _qrService = qrService;

  QrCodeData? get qrCodeData => _qrCodeData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasKey => _qrCodeData != null;

  /// Loads the stored key and builds today's QR data. Called on app startup.
  Future<void> init() async {
    _setLoading(true);
    try {
      final String? key = await _storageService.getKey();
      if (key != null && key.isNotEmpty) {
        _qrCodeData = QrCodeData.forToday(key);
      }
    } catch (e) {
      _errorMessage = 'Failed to load stored key';
      debugPrint('QrProvider.init error: $e');
    }
    _setLoading(false);
  }

  /// Scans a QR code from the given [imageFile], validates it, and saves the key.
  /// Returns null on success or a human-readable error message on failure.
  Future<String?> scanAndSaveKey(XFile imageFile) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final String? rawResult =
          await _qrService.parseQrFromImage(imageFile.path);
      if (rawResult == null) {
        _setLoading(false);
        return 'No QR code found in the selected image';
      }

      if (!_qrService.validateQrFormat(rawResult)) {
        _setLoading(false);
        return 'QR code format is not valid for this app';
      }

      final String key = _qrService.extractKey(rawResult);
      await _storageService.saveKey(key);
      _qrCodeData = QrCodeData.forToday(key);
    } catch (e) {
      debugPrint('QrProvider.scanAndSaveKey error: $e');
      _setLoading(false);
      return 'An unexpected error occurred while scanning';
    }

    _setLoading(false);
    notifyListeners();
    return null;
  }

  /// Deletes the stored key and clears the current QR code.
  Future<void> deleteKey() async {
    try {
      await _storageService.deleteKey();
      _qrCodeData = null;
    } catch (e) {
      _errorMessage = 'Failed to delete key';
      debugPrint('QrProvider.deleteKey error: $e');
    }
    notifyListeners();
  }

  /// Refreshes QR data for today (call when the date changes).
  void refreshForToday() {
    if (_qrCodeData != null) {
      _qrCodeData = QrCodeData.forToday(_qrCodeData!.userKey);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
