import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String aliNumber = "00004904";
  String qrData = "";

  void initState() {
    //getKey();
    super.initState();
    qrData =
        "$aliNumber,${DateFormat('yyyy-MM-dd').format(DateTime.now())} 23:59:00";
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
                decoration: BoxDecoration(
                  //color: Color.fromARGB(255, 224, 227, 229),
                ),
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
                title: const Text("Scan Qr"),
                // Scan Icon
                leading: const Icon(Icons.qr_code_scanner),
                onTap: () {
                  // Show dialog for scan qr code
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Scan Qr Code"),
                        content: const Text(
                            "You need a screenshot of the qr, take a screenshot and upload it!"),
                        actions: [
                          TextButton(onPressed: () {
                            Navigator.pop(context);
                          }, child: const Text("Cancel")),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: GestureDetector(child: Text("Select Image"),
                            onTap: () async{
                              debugPrint("Select Image");
                              // Open Image Picker
                              final ImagePicker _picker = ImagePicker();
                               final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                                if (image != null) {
                                  debugPrint("Image Selected");
                                  // Read Image
                                  // Read Qr Code
                                  // Set Qr Code
                                }
                                else{
                                  debugPrint("Image Not Selected");
                                  // Snack Bar message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Image Not Selected"),
                                    ),
                                  );
                                }
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
                // Info Icon
                leading: const Icon(Icons.info),
                onTap: () {
                  // Show Dialog
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
              // Switch for dark mode
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
                  errorStateBuilder: (context, error) => const Text("Hata"),
                  errorCorrectionLevel: QrErrorCorrectLevel.L,
                  constrainErrorBounds: true,
                  //embeddedImage: const AssetImage("lib/assets/images/image.png"),
                  // embeddedImageStyle: const QrEmbeddedImageStyle(
                  //   color: Colors.blue,
                    // size: 500,
                  // ),
                  data: qrData,
                ),
              ),
              Text(qrData),
            ],
          ),
        ));
  }
}
