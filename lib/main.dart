import 'package:flutter/material.dart';
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          brightness: Brightness.light,
          primary: const Color.fromARGB(255, 0, 0, 0),
          secondary: const Color.fromARGB(255, 0, 0, 0),
          surface: const Color.fromARGB(255, 255, 255, 255),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
            brightness: Brightness.dark,
            primary: Colors.grey[900],
            secondary: Colors.grey[800],
            surface: const Color.fromARGB(255, 255, 252, 252)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
