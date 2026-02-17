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
import 'package:flutter_application_1/core/theme/app_theme.dart';

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
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          // Custom Tab Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0DCD5)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                indicator: BoxDecoration(
                  color: AppTheme.cream, // Lighter indicator
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0DCD5)),
                ),
                labelColor: AppTheme.black,
                unselectedLabelColor: AppTheme.grey,
                labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13),
                dividerColor: Colors.transparent, // Remove default divider
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
        backgroundColor: AppTheme.black,
        foregroundColor: AppTheme.white,
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
          return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
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
                  color: AppTheme.grey.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  status == 'open' ? 'No active jobs' : 'No closed jobs',
                  style: GoogleFonts.montserrat(color: AppTheme.grey),
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

  ButtonStyle _outlinedBtnStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppTheme.black,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: Color(0xFFE0DCD5)),
    );
  }

  ButtonStyle _filledBtnStyle({bool isAccent = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: isAccent ? AppTheme.gold : AppTheme.black,
      foregroundColor: isAccent ? AppTheme.black : AppTheme.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
    );
  }

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
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE0DCD5)),
             boxShadow: [
              BoxShadow(
                color: AppTheme.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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
                            color: AppTheme.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Posted ${DateFormat('MMM d').format(job.createdAt)}',
                          style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (job.status == 'open')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.users, size: 12, color: AppTheme.gold),
                          const SizedBox(width: 6),
                          Text(
                            '${bookings.length} Applicants',
                            style: GoogleFonts.montserrat(color: AppTheme.gold, fontSize: 11, fontWeight: FontWeight.bold),
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
                        color: AppTheme.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.black.withOpacity(0.1)),
                      ),
                      child: const Text(
                        'GROUP BOOKING',
                        style: TextStyle(color: AppTheme.black, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
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
                      style: _outlinedBtnStyle(),
                      child: const Text('Edit Job', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        } else {
                           // Handle case with no applicants if needed, generally 'View Applicants' would be disabled or lead to empty list
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No applicants yet.')));
                        }
                      },
                      style: _filledBtnStyle(isAccent: isGroup),
                      child: Text(
                        isGroup ? 'Manage Group' : 'View Applicants',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
        Icon(icon, size: 14, color: AppTheme.grey),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 13),
        ),
      ],
    );
  }
}

