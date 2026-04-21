import 'package:intl/intl.dart';
import 'package:tedu_qrcode/constants/app_constants.dart';

/// Represents a single day's QR code for gate access.
class QrCodeData {
  /// The 8-character alphanumeric user key extracted from the original scanned QR.
  final String userKey;

  /// The date this QR is valid for (expires at 23:59:00).
  final DateTime generatedDate;

  const QrCodeData({
    required this.userKey,
    required this.generatedDate,
  });

  /// The formatted string encoded in the QR code.
  /// Format: "75A08773,2024-03-31 23:59:00"
  String get formattedData {
    final String dateStr = DateFormat('yyyy-MM-dd').format(generatedDate);
    return '$userKey,$dateStr ${AppConstants.qrExpiryTime}';
  }

  /// Returns true if the raw [value] from a scanned QR matches the expected format.
  static bool isValidFormat(String value) {
    return AppConstants.qrFormatRegex.hasMatch(value);
  }

  /// Extracts the 8-character user key from a raw QR string.
  /// Assumes [isValidFormat] has already returned true.
  static String extractKey(String rawQrValue) {
    return rawQrValue.split(',')[0];
  }

  /// Creates a [QrCodeData] for today from a stored [userKey].
  factory QrCodeData.forToday(String userKey) {
    return QrCodeData(
      userKey: userKey,
      generatedDate: DateTime.now(),
    );
  }

  @override
  String toString() => formattedData;
}
