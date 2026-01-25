import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/features/auth/onboarding_screen.dart';
import 'package:flutter_application_1/features/admin/admin_dashboard_screen.dart';
import 'package:flutter_application_1/features/dashboard/dashboard_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // 1. If waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. If no user, show Onboarding
        if (!snapshot.hasData) {
          return const OnboardingScreen();
        }

        // 3. If user exists, fetch role
        final User user = snapshot.data!;
        return FutureBuilder<String?>(
          future: _authService.getUserRole(user.uid),
          builder: (context, roleSnapshot) {
             if (roleSnapshot.connectionState == ConnectionState.waiting) {
               return const Scaffold(
                 backgroundColor: Colors.black,
                 body: Center(child: CircularProgressIndicator()),
               );
             }

             final role = roleSnapshot.data;

             if (role == 'admin') {
               return const AdminDashboardScreen();
             } else if (role == 'brand') {
               return const DashboardScreen(userType: 'brand');
             } else if (role == 'model') {
               return const DashboardScreen(userType: 'model');
             } else {
               // Fallback / Error / Default
               // If role is missing, maybe default to model or show error
                return const DashboardScreen(userType: 'model');
             }
          },
        );
      },
    );
  }
}
