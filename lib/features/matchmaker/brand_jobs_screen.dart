import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/jobs/post_job_screen.dart';
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
import 'package:flutter_application_1/features/jobs/job_detail_screen.dart';

class BrandJobsScreen extends StatefulWidget {
  const BrandJobsScreen({super.key});

  @override
  State<BrandJobsScreen> createState() => _BrandJobsScreenState();
}

class _BrandJobsScreenState extends State<BrandJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return Center(
        child: Text('Please log in',
            style: GoogleFonts.montserrat(color: AppTheme.grey)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: StreamBuilder<List<JobModel>>(
        stream: _jobService.getBrandJobs(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.gold));
          }

          final allJobs = snapshot.data ?? [];
          final activeJobs =
              allJobs.where((j) => j.status == 'open').toList();
          final draftJobs =
              allJobs.where((j) => j.status == 'draft').toList();
          final closedJobs =
              allJobs.where((j) => j.status == 'closed').toList();

          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Jobs',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PostJobScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.gold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.plus,
                                size: 16, color: AppTheme.black),
                            const SizedBox(width: 6),
                            Text(
                              'Post Job',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Segmented Tab Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0DCD5)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppTheme.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: AppTheme.white,
                    unselectedLabelColor: AppTheme.grey,
                    labelStyle: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    unselectedLabelStyle: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500, fontSize: 13),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: 'Active (${activeJobs.length})'),
                      Tab(text: 'Drafts (${draftJobs.length})'),
                      Tab(text: 'Closed (${closedJobs.length})'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildJobsList(activeJobs, 'active'),
                    _buildJobsList(draftJobs, 'draft'),
                    _buildJobsList(closedJobs, 'closed'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildJobsList(List<JobModel> jobs, String statusLabel) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.briefcase,
                size: 48, color: AppTheme.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No $statusLabel jobs',
              style: GoogleFonts.montserrat(color: AppTheme.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: jobs.length,
      itemBuilder: (context, index) =>
          _BrandJobCard(job: jobs[index], statusLabel: statusLabel),
    );
  }
}

class _BrandJobCard extends StatelessWidget {
  final JobModel job;
  final String statusLabel;

  const _BrandJobCard({required this.job, required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    final BookingService bookingService = BookingService();

    return StreamBuilder<List<BookingModel>>(
      stream: bookingService.getJobBookings(job.id),
      builder: (context, snapshot) {
        final bookings = snapshot.data ?? [];
        final confirmedCount = bookings
            .where((b) => [
                  'confirmed',
                  'signed',
                  'in_progress',
                  'completed',
                  'paid'
                ].contains(b.status))
            .length;
        final isGroup = confirmedCount >= 2;

        return GestureDetector(
          onTap: () {
            if (isGroup) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupBookingDashboard(
                    job: job,
                    bookings: bookings
                        .where((b) => [
                              'confirmed',
                              'signed',
                              'in_progress',
                              'completed',
                              'paid'
                            ].contains(b.status))
                        .toList(),
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
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8E4DE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row + status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  job.title,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.black,
                                  ),
                                ),
                              ),
                              if (isGroup) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cream,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0xFFE0DCD5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.users,
                                          size: 12, color: AppTheme.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Group',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.cream,
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: const Color(0xFFE0DCD5)),
                            ),
                            child: Text(
                              job.location,
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatusBadge(status: statusLabel),
                  ],
                ),
                const SizedBox(height: 14),

                // Location
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin,
                        size: 14, color: AppTheme.grey),
                    const SizedBox(width: 8),
                    Text(
                      job.location,
                      style: GoogleFonts.montserrat(
                          fontSize: 13, color: AppTheme.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Date
                Row(
                  children: [
                    const Icon(LucideIcons.calendar,
                        size: 14, color: AppTheme.grey),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM d, yyyy').format(job.date),
                      style: GoogleFonts.montserrat(
                          fontSize: 13, color: AppTheme.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Applicants + Budget
                Row(
                  children: [
                    const Icon(LucideIcons.users,
                        size: 14, color: AppTheme.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isGroup
                            ? '$confirmedCount hired · ${bookings.length} applicants'
                            : '${bookings.length} applicants',
                        style: GoogleFonts.montserrat(
                            fontSize: 13, color: AppTheme.grey),
                      ),
                    ),
                    Text(
                      '\$${job.rate.toInt()}/day',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.black,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // View Details link
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobDetailScreen(job: {
                            'id': job.id,
                            'jobName': job.title,
                            'location': job.location,
                            'date': DateFormat('MMM d, yyyy').format(job.date),
                            'category': job.location,
                            'payment': '\$${job.rate.toInt()}/day',
                            'coverImage':
                                'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?q=80&w=800&auto=format&fit=crop',
                            'brandName': job.brandName,
                            'brandLogo':
                                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(job.brandName)}&background=1A1A1A&color=D4AF37',
                            'description': job.description,
                            'requirements': job.requirements,
                          }),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Details',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.gold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.chevronRight,
                            size: 16, color: AppTheme.gold),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (status) {
      case 'active':
        bgColor = AppTheme.success.withOpacity(0.08);
        textColor = AppTheme.success;
        borderColor = AppTheme.success.withOpacity(0.25);
      case 'draft':
        bgColor = const Color(0xFFF9A825).withOpacity(0.08);
        textColor = const Color(0xFFF9A825);
        borderColor = const Color(0xFFF9A825).withOpacity(0.25);
      case 'closed':
      default:
        bgColor = AppTheme.grey.withOpacity(0.08);
        textColor = AppTheme.grey;
        borderColor = AppTheme.grey.withOpacity(0.2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
