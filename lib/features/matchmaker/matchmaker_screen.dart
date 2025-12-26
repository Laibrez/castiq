import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_application_1/core/services/job_service.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/services/booking_service.dart';
import 'package:flutter_application_1/core/models/job_model.dart';
import 'package:flutter_application_1/core/models/booking_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MatchmakerScreen extends StatefulWidget {
  const MatchmakerScreen({super.key});

  @override
  State<MatchmakerScreen> createState() => _MatchmakerScreenState();
}

class _MatchmakerScreenState extends State<MatchmakerScreen> {
  final JobService _jobService = JobService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Find Jobs',
          style: GoogleFonts.tinos(fontWeight: FontWeight.w600, fontStyle: FontStyle.italic),
        ),
      ),
      body: StreamBuilder<List<JobModel>>(
        stream: _jobService.getOpenJobs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final jobs = snapshot.data ?? [];

          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.briefcase, size: 48, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    'No jobs available yet.',
                    style: GoogleFonts.tinos(color: Colors.white54, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              return _JobCard(job: jobs[index]);
            },
          );
        },
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    job.brandName.isNotEmpty ? job.brandName[0].toUpperCase() : 'B',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.brandName,
                    style: GoogleFonts.tinos(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${job.location} • ${DateFormat('MMM d').format(job.date)}',
                    style: GoogleFonts.tinos(
                      fontSize: 12,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                ),
                child: Text(
                  '\$${job.rate.toInt()}/day',
                  style: GoogleFonts.tinos(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF818CF8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            job.title,
            style: GoogleFonts.tinos(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            job.description,
            style: GoogleFonts.tinos(
              fontSize: 14,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: job.requirements.take(3).map((req) => _Tag(text: req)).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final authService = AuthService();
                final bookingService = BookingService();
                final user = authService.currentUser;

                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please log in to apply')),
                  );
                  return;
                }

                try {
                  // Check if already applied
                  final existingBookings = await FirebaseFirestore.instance
                      .collection('bookings')
                      .where('jobId', isEqualTo: job.id)
                      .where('modelId', isEqualTo: user.uid)
                      .get();

                  if (existingBookings.docs.isNotEmpty) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You have already applied for this job')),
                    );
                    return;
                  }

                  final booking = BookingModel(
                    id: '',
                    jobId: job.id,
                    brandId: job.brandId,
                    modelId: user.uid,
                    status: 'pending',
                    createdAt: DateTime.now(),
                  );

                  await bookingService.createBooking(booking);

                  if (!context.mounted) return;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Application Sent'),
                      content: const Text('Your profile has been sent to the brand.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to apply: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('Apply Now'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;

  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.tinos(
          fontSize: 12,
          color: Colors.white70,
        ),
      ),
    );
  }
}
