import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/matchmaker/create_job_screen.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/services/job_service.dart';
import 'package:flutter_application_1/core/models/job_model.dart';
import 'package:intl/intl.dart';

class BrandJobsScreen extends StatefulWidget {
  const BrandJobsScreen({super.key});

  @override
  State<BrandJobsScreen> createState() => _BrandJobsScreenState();
}

class _BrandJobsScreenState extends State<BrandJobsScreen> {
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) return const Center(child: Text('Please log in'));

    return Scaffold(
      body: StreamBuilder<List<JobModel>>(
        stream: _jobService.getBrandJobs(user.uid),
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
                    'No jobs posted yet',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateJobScreen()),
                      );
                    },
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('Post Your First Job'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return _BrandJobCard(job: job);
            },
          );
        },
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

class _BrandJobCard extends StatelessWidget {
  final JobModel job;

  const _BrandJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: GoogleFonts.tinos(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: job.status == 'open' ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  job.status.toUpperCase(),
                  style: TextStyle(
                    color: job.status == 'open' ? Colors.green : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.mapPin, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                job.location,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(width: 16),
              const Icon(LucideIcons.calendar, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM d, yyyy').format(job.date),
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            job.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white60),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${job.rate.toInt()}/day',
                style: GoogleFonts.tinos(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF818CF8),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: View applicants or edit job
                },
                child: const Text('View Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
