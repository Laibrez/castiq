import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/matchmaker/create_job_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/services/job_service.dart';
import 'package:flutter_application_1/core/models/job_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/core/services/booking_service.dart';
import 'package:flutter_application_1/core/models/booking_model.dart';

import 'package:flutter_application_1/features/bookings/group_booking_dashboard.dart';
import 'package:flutter_application_1/features/bookings/booking_detail_screen.dart';

class BrandJobsScreen extends StatefulWidget {
  const BrandJobsScreen({super.key});

  @override
  State<BrandJobsScreen> createState() => _BrandJobsScreenState();
}

class _BrandJobsScreenState extends State<BrandJobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) return const Center(child: Text('Please log in'));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Custom Tab Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF161618),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                indicator: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Closed'),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildJobsList('open'),
                _buildJobsList('closed'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateJobScreen()),
          );
        },
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        label: const Text('Post a Job', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(LucideIcons.plus, size: 20),
      ),
    );
  }

  Widget _buildJobsList(String status) {
    final user = _authService.currentUser;
    return StreamBuilder<List<JobModel>>(
      stream: _jobService.getBrandJobs(user?.uid ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final allJobs = snapshot.data ?? [];
        final filteredJobs = allJobs.where((j) => j.status == status).toList();

        if (filteredJobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'open' ? LucideIcons.briefcase : LucideIcons.archive,
                  size: 48,
                  color: Colors.white.withOpacity(0.1),
                ),
                const SizedBox(height: 16),
                Text(
                  status == 'open' ? 'No active jobs' : 'No closed jobs',
                  style: TextStyle(color: Colors.white.withOpacity(0.3)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: filteredJobs.length,
          itemBuilder: (context, index) => _JobCard(job: filteredJobs[index]),
        );
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final BookingService bookingService = BookingService();

    return StreamBuilder<List<BookingModel>>(
      stream: bookingService.getJobBookings(job.id),
      builder: (context, snapshot) {
        final bookings = snapshot.data ?? [];
        final confirmedCount = bookings.where((b) => ['confirmed', 'signed', 'in_progress', 'completed', 'paid'].contains(b.status)).length;
        final isGroup = confirmedCount >= 2;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161618),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Posted ${DateFormat('MMM d').format(job.createdAt)}',
                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (job.status == 'open')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.users, size: 12, color: Color(0xFF818CF8)),
                          const SizedBox(width: 6),
                          Text(
                            '${bookings.length} Applicants',
                            style: const TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _infoItem(LucideIcons.mapPin, job.location),
                  const SizedBox(width: 20),
                  _infoItem(LucideIcons.calendar, DateFormat('MMM d, yyyy').format(job.date)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _infoItem(LucideIcons.dollarSign, '${job.rate.toInt()}/day'),
                  if (isGroup) ...[
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                      ),
                      child: const Text(
                        'GROUP BOOKING',
                        style: TextStyle(color: Color(0xFF818CF8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Text('Edit Job', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (isGroup) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupBookingDashboard(
                                job: job,
                                bookings: bookings.where((b) => ['confirmed', 'signed', 'in_progress', 'completed', 'paid'].contains(b.status)).toList(),
                              ),
                            ),
                          );
                        } else if (bookings.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingDetailScreen(
                                userType: 'brand',
                                bookingId: bookings.first.id,
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isGroup ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.05),
                        foregroundColor: isGroup ? Colors.white : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        isGroup ? 'Manage Group' : 'View Applicants',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.3)),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        ),
      ],
    );
  }
}
