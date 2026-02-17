import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/auth/onboarding_screen.dart';
import 'package:flutter_application_1/features/auth/auth_wrapper.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/firebase_options.dart';

import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Stripe
  Stripe.publishableKey = 'pk_test_51T0nzCC5ljKxfVh20aElHSnEohGnepMpFujRepxBqLcVsbEG4EGiQgdiP3LMyF1NyVtrAE3LyMM8Tia2YXonK1uY00hkc8klyd';
  await Stripe.instance.applySettings();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caztiq',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}
