import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scan/scan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tedu_qrcode/HomePage.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // WidgetsFlutterBinding.ensureInitialized();

    Future<void> getKey() async{
  // Get Keys from Shared Preferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? key = prefs.getString("key");
  if(key == null){
    debugPrint("Key Not Found");
    // show a dialog screen ?
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Key Not Found"),
          content: const Text("You need to scan a qr code first!"),
          actions: [
            TextButton(onPressed: () async{
             debugPrint("Select Image");
    // Open Image Picker
    final ImagePicker _picker = ImagePicker();
     final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        debugPrint("Image Selected");
        // Read Image
        String? result = await Scan.parse(image.path);
        debugPrint("Result: $result");
        RegExp regExp = RegExp(r'^\d{8},\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$');
        if(result == null){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Qr Code Not Found"),
            ),
          );
        }
        else{
        if(regExp.hasMatch(result)){
          // Save Qr Code
          SharedPreferences prefs = await SharedPreferences.getInstance();
          try{
             await prefs.setString("key", result.split(",")[0]);
             debugPrint("Key Saved: ${result.split(",")[0]}");
          }
          catch(e){
            debugPrint("Error: $e");
          }
         
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Qr Code Saved"),
            ),
          );
        }
        else{
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Qr Code Not Valid"),
            ),
          );
        }
        }
        Navigator.pop(context);
       
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
            }, child: const Text("Scan QR")),
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

   SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 255, 255, 255)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}