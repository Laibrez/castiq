import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/core/widgets/application_confirmation_modal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/features/brands/brand_profile_screen.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/core/models/job_model.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/services/job_service.dart';
import 'package:intl/intl.dart';

class JobDetailScreen extends StatefulWidget {
  final JobModel job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final AuthService _authService = AuthService();
  final JobService _jobService = JobService();
  bool _isApplying = false;

  void _handleApply() async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to apply')));
      return;
    }

    setState(() => _isApplying = true);

    try {
      await _jobService.applyToJob(widget.job.id, user.uid, widget.job.brandId);
      if (!mounted) return;
      ApplicationConfirmationModal.show(context, jobName: widget.job.title);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to apply: $e')));
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: CustomScrollView(
        slivers: [
          // 1. Large Cover Image Header
          SliverAppBar(
            expandedHeight: 350,
            backgroundColor: AppTheme.cream,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: AppTheme.white.withOpacity(0.9),
                child: IconButton(
                  icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                   widget.job.images.isNotEmpty 
                    ? Image.network(widget.job.images.first, fit: BoxFit.cover)
                    : Container(color: AppTheme.grey), // Fallback
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.cream.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Brand Logo & View Profile Button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8E4DE)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(width: 60, height: 60, color: AppTheme.grey.withOpacity(0.1), child: const Icon(LucideIcons.user, color: AppTheme.grey)), // Fallback for brand logo if not in JobModel
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.job.brandName,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.black,
                              ),
                            ),
                            Text(
                              'Premium Partner', // Placeholder or fetch brand details
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: AppTheme.gold,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BrandProfileScreen(
                                brandId: widget.job.brandId,
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: AppTheme.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Color(0xFFE8E4DE)),
                          ),
                        ),
                        child: Text(
                          'View Brand Profile',
                          style: GoogleFonts.montserrat(
                            color: AppTheme.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 3. Job Title
                  Text(
                    widget.job.title,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 36,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.black,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Highlighted Info Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE8E4DE)),
                    ),
                    child: Column(
                      children: [
                        _infoRow(LucideIcons.mapPin, 'Location', widget.job.location),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: AppTheme.black.withOpacity(0.06)),
                        ),
                        _infoRow(LucideIcons.calendar, 'Dates', DateFormat('MMM d, yyyy').format(widget.job.shootDate)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: AppTheme.black.withOpacity(0.06)),
                        ),
                        _infoRow(LucideIcons.dollarSign, 'Total Payment', '\$${widget.job.payRate.toStringAsFixed(0)} USD', isHighlight: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 5. Sections
                  _sectionHeader('Description'),
                  const SizedBox(height: 12),
                  Text(
                    widget.job.description,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      color: AppTheme.grey,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _sectionHeader('Requirements'),
                  const SizedBox(height: 12),
                  _requirementItem('Height: ${widget.job.heightMin}cm – ${widget.job.heightMax}cm'),
                  _requirementItem('Gender: ${widget.job.genderRequirement}'),
                  _requirementItem('Experience: ${widget.job.experienceRequired} years'), 
                  _requirementItem('Contract: ${widget.job.contractType}'),
                   if (widget.job.isUrgent) _requirementItem('Urgent Casting'),
                   if (widget.job.isInstantPayoutAvailable) _requirementItem('Instant Payout Available'),

                  const SizedBox(height: 32),

                  // _sectionHeader('Past Events'),
                  // ... (Mock images or fetch from brand)
                  
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cream,
          border: Border(
            top: BorderSide(color: AppTheme.black.withOpacity(0.06)),
          ),
        ),
        child: ElevatedButton(
          onPressed: _isApplying ? null : _handleApply,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.gold,
            foregroundColor: AppTheme.black,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: _isApplying 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.black, strokeWidth: 2))
            : Text(
              'Apply Now',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16),
            ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.grey, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  color: isHighlight ? AppTheme.gold : AppTheme.black,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.cormorantGaramond(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppTheme.black,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _requirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.gold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                color: AppTheme.grey,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaCard(String imageUrl) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
