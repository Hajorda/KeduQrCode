/// All magic numbers, keys, and string constants live here.
/// Never use hardcoded values elsewhere in the codebase.
class AppConstants {
  AppConstants._(); // Prevent instantiation

  // --- SharedPreferences keys ---
  static const String prefKeyUserKey = 'key';
  static const String prefKeyWallpaperPath = 'wallpaper';
  static const String prefKeyIsDarkMode = 'is_dark_mode';

  // --- QR code generation ---
  /// Width/height in pixels of the generated QR image for wallpaper use
  static const int qrImageSize = 878;

  /// QR code fills this fraction of the wallpaper width
  static const double qrWallpaperWidthFraction = 1 / 5;

  /// Background box is this multiple larger than the QR (adds padding)
  static const double qrBackgroundPadding = 1.05;

  /// Valid QR data format: 8 alphanumeric characters, comma, YYYY-MM-DD HH:MM:SS
  static final RegExp qrFormatRegex =
      RegExp(r'^[a-zA-Z0-9]{8},\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$');

  /// QR codes are valid until this time each day
  static const String qrExpiryTime = '23:59:00';

  // --- Asset paths ---
  static const String logoAsset = 'assets/images/image.png';

  // --- App metadata ---
  static const String appName = 'KEDU QR Code';
}
