import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:access_wallpaper/access_wallpaper.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scan/scan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String number = "";
  String qrData = "";
  Uint8List wallpaperBytes = Uint8List(0);
  bool engin = false;

  bool isAutoWallpaperSet = false;

  Future<File> generateQrForWallpaper() async {
    if (qrData.isEmpty) {
      debugPrint("Qr Data is empty");
      return File("");
    }
    ByteData? qrImage = await QrPainter(
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
      data: qrData, // Display the QR code data
      gapless: true,
      emptyColor: const Color.fromARGB(
          255, 255, 255, 255), // Set QR code color to white
      //color: const Color.fromARGB(255, 0, 0, 0), // Background inside the QR code remains black
    ).toImageData(878);

    final buffer = qrImage?.buffer;
    if (buffer == null) {
      debugPrint("Buffer is null");
      return File("");
    }
    if (qrImage == null) {
      debugPrint("QrImage is null");
      return File("");
    }

    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    var filePath =
        tempPath + '/file_01.tmp'; // file_01.tmp is dump file, can be anything
    File assetPath = await File(filePath).writeAsBytes(
        buffer.asUint8List(qrImage.offsetInBytes, qrImage.lengthInBytes));
    return assetPath;
  }

  Future<Uint8List> getCurrentWallpaper() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    var manageStatus = await Permission.manageExternalStorage.status;
    if (!manageStatus.isGranted) {
      await Permission.manageExternalStorage.request();
    }

    final AccessWallpaper accessWallpaper = AccessWallpaper();

    Uint8List? wallpaperBytes =
        await accessWallpaper.getWallpaper(AccessWallpaper.homeScreenFlag);
    if (wallpaperBytes == null) {
      debugPrint("Wallpaper is null");
      return Uint8List(0);
    }
    return wallpaperBytes;
  }

  Future<void> setOriginalWallapaper() async {
    // Get wallapaper from shared preferences
    SharedPreferences.getInstance().then((prefs) {
      String? wallpaperPath = prefs.getString("wallpaper");
      if (wallpaperPath != null) {
        // Set the wallpaper
        WallpaperManager.setWallpaperFromFile(
            wallpaperPath, WallpaperManager.LOCK_SCREEN);
      } else {
        debugPrint("Original Wallpaper Path is null");
      }
    });
  }

  Future<void> setWallpaper() async {
    // Generate the QR code file
    File qrFile = await generateQrForWallpaper();

    // Get the current wallpaper
    Uint8List wallpaperBytes = await getCurrentWallpaper();
    if (wallpaperBytes.isEmpty) {
      debugPrint("Wallpaper is empty");
      return;
    }
    // Check is there original wallpaper
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? wallpaperPath = prefs.getString("wallpaper");
    if (wallpaperPath == null) {
      // Save the current wallpaper as a file
      File wallpaperFile = File('${qrFile.parent.path}/wallpaper.png')
        ..writeAsBytesSync(wallpaperBytes);
      // Save the file to sharedpreferces
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("wallpaper", wallpaperFile.path);
    }
    
    // Decode the current wallpaper into an img.Image
    img.Image wallpaperImage = img.decodeImage(wallpaperBytes)!;

    // Read and decode the QR code image from the file
    Uint8List qrBytes = qrFile.readAsBytesSync();
    img.Image qrImage = img.decodeImage(qrBytes)!;

    // Resize the QR code to be smaller (e.g., 1/3 of the wallpaper width)
    int qrWidth = (wallpaperImage.width / 5).round();
    img.Image resizedQrImage = img.copyResize(qrImage, width: qrWidth);

    // Calculate the size for the black background (5% larger than the QR code)
    int backgroundWidth = (resizedQrImage.width * 1.05).round();
    int backgroundHeight = (resizedQrImage.height * 1.05).round();

    // Create a black background image
    img.Image background =
        img.Image(width: backgroundWidth, height: backgroundHeight);
    img.fill(background,
        color: img.ColorFloat64.rgb(0, 100, 0)); // Black background

    // // Optionally, you can add rounded corners to the black background
    // drawRoundedCorners(background, backgroundWidth ~/ 8);

    // Composite the QR code onto the black background
    int qrCenterX = (backgroundWidth - resizedQrImage.width) ~/ 2;
    int qrCenterY = (backgroundHeight - resizedQrImage.height) ~/ 2;
    img.compositeImage(background, resizedQrImage,
        dstX: qrCenterX, dstY: qrCenterY);

    // Calculate the position to center the black background (with the QR code) on the wallpaper
    int centerX = (wallpaperImage.width - backgroundWidth) ~/ 2;
    int centerY = (wallpaperImage.height - backgroundHeight) ~/ 2;

    // Composite the black background (with the QR code) onto the wallpaper
    img.compositeImage(wallpaperImage, background,
        dstX: centerX, dstY: centerY);

    // Save the modified wallpaper as a new file
    File newWallpaperFile = File('${qrFile.parent.path}/new_wallpaper.png')
      ..writeAsBytesSync(img.encodePng(wallpaperImage));

    // Set the modified wallpaper as the lock screen or home screen wallpaper
    int location = WallpaperManager
        .LOCK_SCREEN; // can be set to WallpaperManager.HOME_SCREEN or BOTH_SCREEN
    bool result = await WallpaperManager.setWallpaperFromFile(
        newWallpaperFile.path, location);

    // Debugging feedback
    if (result) {
      debugPrint("Wallpaper set successfully");
    } else {
      debugPrint("Failed to set wallpaper");
    }
  }

  Future<void> getKey() async {
    // Get Keys from Shared Preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? key = prefs.getString("key");

    if (key != null) {
      setState(() {
        number = key;
        qrData =
            "$number,${DateFormat('yyyy-MM-dd').format(DateTime.now())} 23:59:00";
      });
    } else {
      debugPrint("Key Not Found");
      // show a dialog screen
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text("Key Not Found"),
              content: const Text("You need to scan a qr code first!"),
              actions: [
                TextButton(
                  onPressed: () {
                    parseQr(context);
                  },
                  child: const Text("Scan QR"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getKey(); // Get the key when the widget is initialized
    WakelockPlus.enable();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("KEDU Qr Code"),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage("lib/assets/images/image.png"),
                    backgroundColor: Colors.transparent,
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text("Delete Key"),
              leading: const Icon(Icons.delete),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Delete Key"),
                      content:
                          const Text("Are you sure you want to delete key?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            SharedPreferences.getInstance().then((prefs) {
                              prefs.remove("key");
                              setState(() {
                                number =
                                    ""; // Clear the number when key is deleted
                                qrData = ""; // Clear the QR code
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Key Deleted"),
                                ),
                              );
                              Navigator.pop(context);
                            });
                          },
                          child: const Text("Yes"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("No"),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              title: const Text("Scan Qr"),
              leading: const Icon(Icons.qr_code_scanner),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Scan Qr Code"),
                      content: const Text(
                          "You need a screenshot of the qr, take a screenshot and upload it!"),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("Cancel")),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: GestureDetector(
                            child: const Text("Select Image"),
                            onTap: () async {
                              await parseQr(context);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              title: const Text("Info"),
              leading: const Icon(Icons.info),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Info"),
                      content: const Text(
                          "This is a simple Qr Code Generator App for Kedu Edu. First Scan your qr code from your real application and after that you can use this app while entering gate."),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("OK"),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            SwitchListTile(
              title: const Text("Dark Mode"),
              value: false,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text("Auto Set Wallpaper"),
              value: isAutoWallpaperSet,
              onChanged: (value) {
                // Auto Set Wallpaper
                setState(() {
                  isAutoWallpaperSet = value;
                });
                if (isAutoWallpaperSet) {
                  setState(() {
                    debugPrint("Auto Set Wallpaper Activated");
                    setWallpaper();
                  });
                } else {
                  debugPrint("Auto Set Wallpaper Deactivated");
                  setOriginalWallapaper();
                }
              },
            ),
          ],
        ),
      ),
      body: Builder(builder: (context) {
        if (number.isEmpty) {
          return const Center(
            child: Text("No Key Found"),
          );
        }
        return Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(60.0),
                child: QrImageView(
                  version: QrVersions.auto,
                  errorStateBuilder: (context, error) => const Text("Error"),
                  errorCorrectionLevel: QrErrorCorrectLevel.L,
                  constrainErrorBounds: true,
                  data: qrData, // Display the QR code data
                ),
              ),
              Text(qrData), // Display the QR code string
              // Image that shows wallapaper as image if engin is true
              engin ? Image.memory(wallpaperBytes) : const SizedBox(),
              ElevatedButton(
                  onPressed: () async {
                    debugPrint("Button Pressed");
                    var bytes = await getCurrentWallpaper();
                    setState(() {
                      wallpaperBytes = bytes;
                      engin = true;
                    });
                  },
                  child: Text("Button"))
            ],
          ),
        );
      }),
    );
  }

  Future<void> parseQr(BuildContext context) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      String? result = await Scan.parse(image.path);
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Qr Code Not Found"),
          ),
        );
      } else {
        RegExp regExp = RegExp(r'^\d{8},\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$');
        if (regExp.hasMatch(result)) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("key", result.split(",")[0]);
          setState(() {
            number = result.split(",")[0];
            qrData =
                "$number,${DateFormat('yyyy-MM-dd').format(DateTime.now())} 23:59:00";
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Qr Code Saved"),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Qr Code Not Valid"),
            ),
          );
        }
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Image Not Selected"),
        ),
      );
    }
  }
}
