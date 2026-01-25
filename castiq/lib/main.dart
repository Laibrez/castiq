import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart'; // Uncomment when Firebase is configured
import 'screens/model_registration_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (commented out until configured)
  // To enable Firebase:
  // 1. Run: dart pub global activate flutterfire_cli
  // 2. Run: flutterfire configure
  // 3. Uncomment the code below and import firebase_options.dart
  
  // try {
  //   import 'firebase_options.dart';
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  // } catch (e) {
  //   debugPrint('Firebase initialization error: $e');
  // }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CastIQ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ModelRegistrationScreen(),
      // Uncomment and use this if you have a home screen:
      // home: const HomeScreen(),
      // routes: {
      //   '/registration': (context) => const ModelRegistrationScreen(),
      // },
    );
  }
}
