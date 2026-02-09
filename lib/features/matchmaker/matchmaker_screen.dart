import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_application_1/core/services/job_service.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/services/booking_service.dart';
import 'package:flutter_application_1/core/models/job_model.dart';
import 'package:flutter_application_1/core/models/booking_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';

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
      backgroundColor: AppTheme.cream,
      body: StreamBuilder<List<JobModel>>(
        stream: _jobService.getOpenJobs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.montserrat(color: AppTheme.black)));
          }

          final jobs = snapshot.data ?? [];

          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.briefcase, size: 48, color: AppTheme.grey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No jobs available yet.',
                    style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
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
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0DCD5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0DCD5)),
                ),
                child: Center(
                  child: Text(
                    job.brandName.isNotEmpty ? job.brandName[0].toUpperCase() : 'B',
                    style: GoogleFonts.cormorantGaramond(
                      color: AppTheme.black, 
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.brandName,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.black,
                    ),
                  ),
                  Text(
                    '${job.location} • ${DateFormat('MMM d').format(job.date)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: AppTheme.grey,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$${job.rate.toInt()}/day',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            job.title,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            job.description,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: AppTheme.grey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: job.requirements.take(3).map((req) => _Tag(text: req)).toList(),
          ),
          const SizedBox(height: 24),
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
                      backgroundColor: AppTheme.white,
                      title: Text('Application Sent', style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 24)),
                      content: Text('Your profile has been sent to the brand.', style: GoogleFonts.montserrat()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK', style: GoogleFonts.montserrat(color: AppTheme.black, fontWeight: FontWeight.bold)),
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
                backgroundColor: AppTheme.black,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Apply Now', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0DCD5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          color: AppTheme.black.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
