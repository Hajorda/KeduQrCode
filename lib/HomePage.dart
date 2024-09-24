import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String aliNumber = "00004904";
  String qrData = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    qrData =
        "$aliNumber,${DateFormat('yyyy-MM-dd').format(DateTime.now())} 23:59:00";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Tedu Qr Code"),
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 224, 227, 229),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage("lib/assets/images/image.png"),
                      backgroundColor: Color.fromARGB(255, 224, 227, 229),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text("Scan Qr"),
                // Scan Icon
                leading: const Icon(Icons.qr_code_scanner),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Info"),
                // Info Icon
                leading: const Icon(Icons.info),
                onTap: () {
                  Navigator.pop(context);
                },
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
                  embeddedImage: const AssetImage("lib/assets/images/image.png"),
                  // embeddedImageStyle: const QrEmbeddedImageStyle(
                  //   color: Colors.blue,
                  //   size: Size(50, 50),
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
