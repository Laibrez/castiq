import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/matchmaker/create_job_screen.dart';

class BrandJobsScreen extends StatelessWidget {
  const BrandJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Jobs',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: Text(
          'Brand Jobs List',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateJobScreen()),
          );
        },
        label: const Text('Post Job'),
        icon: const Icon(LucideIcons.plus),
      ),
    );
  }
}
