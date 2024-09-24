import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scan/scan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  String number = "";
  String qrData = "";

  Future<void> getKey() async {
    // Get Keys from Shared Preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? key = prefs.getString("key");

    if (key != null) {
      setState(() {
        number = key;
        qrData = "$number,${DateFormat('yyyy-MM-dd').format(DateTime.now())} 23:59:00";
      });
    } else {
      debugPrint("Key Not Found");
      // show a dialog screen
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
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
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getKey(); // Get the key when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      content: const Text("Are you sure you want to delete key?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            SharedPreferences.getInstance().then((prefs) {
                              prefs.remove("key");
                              setState(() {
                                number = ""; // Clear the number when key is deleted
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
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: QrImageView(
                version: QrVersions.auto,
                errorStateBuilder: (context, error) => const Text("Error"),
                errorCorrectionLevel: QrErrorCorrectLevel.L,
                constrainErrorBounds: true,
                data: qrData, // Display the QR code data
              ),
            ),
            Text(qrData), // Display the QR code string
          ],
        ),
      ),
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
            qrData = "$number,${DateFormat('yyyy-MM-dd').format(DateTime.now())} 23:59:00";
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
