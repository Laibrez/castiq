import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/dashboard/dashboard_screen.dart';

class IDVerificationStatusScreen extends StatelessWidget {
  const IDVerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.shieldCheck,
              size: 80,
              color: Color(0xFF6366F1),
            ),
            const SizedBox(height: 32),
            Text(
              'Verification Pending',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your ID is currently being reviewed. This usually takes less than 24 hours. You will be notified once approved.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFFB4B4B8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Mock approval for demo purposes
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(userType: 'model'),
                    ),
                  );
                },
                child: const Text('Check Status (Mock: Approve)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
