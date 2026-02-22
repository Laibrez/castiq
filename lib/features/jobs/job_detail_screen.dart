import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';

class _Applicant {
  final String id;
  final String name;
  final String avatar;
  final String location;
  final String rate;
  final String experience;
  final double rating;
  final String appliedAt;
  String status; // 'pending', 'accepted', 'rejected'

  _Applicant({
    required this.id,
    required this.name,
    required this.avatar,
    required this.location,
    required this.rate,
    required this.experience,
    required this.rating,
    required this.appliedAt,
    required this.status,
  });
}

class JobDetailScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late final List<_Applicant> _applicants;

  int get _modelsNeeded => widget.job['modelsNeeded'] ?? 3;
  bool get _isGroupJob => _modelsNeeded > 1;

  List<_Applicant> get _pending =>
      _applicants.where((a) => a.status == 'pending').toList();
  List<_Applicant> get _accepted =>
      _applicants.where((a) => a.status == 'accepted').toList();
  List<_Applicant> get _rejected =>
      _applicants.where((a) => a.status == 'rejected').toList();

  double get _hiringProgress =>
      _modelsNeeded > 0 ? (_accepted.length / _modelsNeeded).clamp(0.0, 1.0) : 0;
  int get _spotsRemaining => (_modelsNeeded - _accepted.length).clamp(0, _modelsNeeded);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _applicants = [
      _Applicant(
        id: '1',
        name: 'Emma Rodriguez',
        avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        location: 'New York, NY',
        rate: '\$600/day',
        experience: '5 years',
        rating: 4.9,
        appliedAt: '2 hours ago',
        status: 'accepted',
      ),
      _Applicant(
        id: '2',
        name: 'Maya Johnson',
        avatar: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=150',
        location: 'Brooklyn, NY',
        rate: '\$500/day',
        experience: '3 years',
        rating: 4.7,
        appliedAt: '5 hours ago',
        status: 'pending',
      ),
      _Applicant(
        id: '3',
        name: 'Aria Chen',
        avatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=150',
        location: 'Manhattan, NY',
        rate: '\$550/day',
        experience: '4 years',
        rating: 4.8,
        appliedAt: '1 day ago',
        status: 'pending',
      ),
      _Applicant(
        id: '4',
        name: 'Sofia Martinez',
        avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
        location: 'Jersey City, NJ',
        rate: '\$450/day',
        experience: '2 years',
        rating: 4.5,
        appliedAt: '1 day ago',
        status: 'rejected',
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleAccept(String applicantId) {
    if (_accepted.length >= _modelsNeeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All spots are already filled.')),
      );
      return;
    }

    final applicant = _applicants.firstWhere((a) => a.id == applicantId);
    setState(() => applicant.status = 'accepted');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${applicant.name} has been added to this booking.')),
    );

    if (_accepted.length >= _modelsNeeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All spots filled! Head to Bookings to manage it.')),
      );
    }
  }

  void _handleReject(String applicantId) {
    final applicant = _applicants.firstWhere((a) => a.id == applicantId);
    setState(() => applicant.status = 'rejected');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${applicant.name}\'s application has been declined.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final title = job['jobName'] ?? job['title'] ?? 'Job Detail';
    final category = job['category'] ?? 'Editorial';
    final location = job['location'] ?? '';
    final date = job['date'] ?? '';
    final startTime = job['startTime'] ?? '9:00 AM';
    final endTime = job['endTime'] ?? '5:00 PM';
    final budgetMin = job['budgetMin'] ?? 500;
    final budgetMax = job['budgetMax'] ?? 800;
    final description = job['description'] ??
        'Looking for confident models for our collection photoshoot.';
    final requirements = job['requirements'] ??
        'Height 5\'8" or above, comfortable with swimwear';
    final bringItems = job['bringItems'] ?? 'Neutral undergarments, natural makeup';

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _badge(category, AppTheme.cream, AppTheme.grey, const Color(0xFFE0DCD5)),
                            const SizedBox(width: 8),
                            _badge('Active', AppTheme.success.withOpacity(0.08), AppTheme.success, AppTheme.success.withOpacity(0.25)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Scrollable Content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hiring Progress (Group Jobs) ──
                    if (_isGroupJob) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.users, size: 16, color: AppTheme.gold),
                                const SizedBox(width: 8),
                                Text(
                                  'Hiring Progress',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.black,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_accepted.length}/$_modelsNeeded hired',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _hiringProgress,
                                minHeight: 8,
                                backgroundColor: AppTheme.gold.withOpacity(0.12),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_spotsRemaining > 0)
                              Text(
                                '$_spotsRemaining spot${_spotsRemaining > 1 ? 's' : ''} remaining · ${_pending.length} pending applications',
                                style: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.grey),
                              )
                            else
                              Text(
                                '✓ All spots filled! View your booking in the Bookings tab.',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.success,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Job Details Card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8E4DE)),
                      ),
                      child: Column(
                        children: [
                          _detailRow(LucideIcons.mapPin, location),
                          const SizedBox(height: 12),
                          _detailRow(LucideIcons.calendar, date),
                          const SizedBox(height: 12),
                          _detailRow(LucideIcons.clock, '$startTime - $endTime'),
                          const SizedBox(height: 12),
                          _detailRow(LucideIcons.dollarSign, '\$$budgetMin - \$$budgetMax per model'),
                          if (_isGroupJob) ...[
                            const SizedBox(height: 12),
                            _detailRow(LucideIcons.users, '$_modelsNeeded models needed'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Description ──
                    if (description.isNotEmpty) ...[
                      Text('Description', style: _sectionStyle()),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: GoogleFonts.montserrat(fontSize: 14, color: AppTheme.grey, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Requirements ──
                    if (requirements.isNotEmpty) ...[
                      Text('Requirements', style: _sectionStyle()),
                      const SizedBox(height: 8),
                      Text(
                        requirements is List ? (requirements as List).join('\n') : requirements.toString(),
                        style: GoogleFonts.montserrat(fontSize: 14, color: AppTheme.grey, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── What to Bring ──
                    if (bringItems.isNotEmpty) ...[
                      Text('What to Bring', style: _sectionStyle()),
                      const SizedBox(height: 8),
                      Text(
                        bringItems,
                        style: GoogleFonts.montserrat(fontSize: 14, color: AppTheme.grey, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Applicant Tabs ──
                    Container(
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
                        labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 12),
                        unselectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w500, fontSize: 12),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: 'Pending (${_pending.length})'),
                          Tab(text: 'Hired (${_accepted.length})'),
                          Tab(text: 'Declined (${_rejected.length})'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTabContent(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tabController.index) {
      case 0:
        return _pending.isEmpty
            ? _emptyState(LucideIcons.users, 'No pending applications')
            : Column(children: _pending.map((a) => _applicantCard(a, showActions: true)).toList());
      case 1:
        if (_accepted.isEmpty) {
          return _emptyState(LucideIcons.checkCircle2, 'No models hired yet', subtitle: 'Accept applications to fill your spots');
        }
        return Column(
          children: [
            ..._accepted.map((a) => _applicantCard(a, showActions: false)),
            if (_accepted.length >= _modelsNeeded)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: AppTheme.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Go to Booking', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.chevronRight, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      case 2:
        return _rejected.isEmpty
            ? _emptyState(LucideIcons.xCircle, 'No declined applications')
            : Column(children: _rejected.map((a) => _applicantCard(a, showActions: false)).toList());
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _applicantCard(_Applicant applicant, {required bool showActions}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E4DE)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.network(
                  applicant.avatar,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: AppTheme.cream, borderRadius: BorderRadius.circular(28)),
                    child: Center(
                      child: Text(
                        applicant.name.split(' ').map((n) => n[0]).join(),
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: AppTheme.grey),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            applicant.name,
                            style: GoogleFonts.montserrat(
                              fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.black,
                            ),
                          ),
                        ),
                        const Icon(LucideIcons.star, size: 14, color: Color(0xFFFFC107)),
                        const SizedBox(width: 4),
                        Text(
                          applicant.rating.toString(),
                          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, size: 12, color: AppTheme.grey),
                        const SizedBox(width: 4),
                        Text(
                          applicant.location,
                          style: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${applicant.rate} · ${applicant.experience}',
                      style: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Applied ${applicant.appliedAt}',
                      style: GoogleFonts.montserrat(fontSize: 11, color: AppTheme.grey.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (showActions && applicant.status == 'pending') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.eye, size: 14),
                    label: Text('View Profile', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.black,
                      side: const BorderSide(color: Color(0xFFE0DCD5)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () => _handleReject(applicant.id),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: Color(0xFFE0DCD5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Icon(LucideIcons.xCircle, size: 16, color: AppTheme.error),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _handleAccept(applicant.id),
                  icon: const Icon(LucideIcons.checkCircle2, size: 14),
                  label: Text('Accept', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: AppTheme.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],

          if (applicant.status == 'accepted') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _badge(
                  '✓ Hired',
                  AppTheme.success.withOpacity(0.08),
                  AppTheme.success,
                  AppTheme.success.withOpacity(0.25),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: [
                      const Icon(LucideIcons.messageSquare, size: 14, color: AppTheme.grey),
                      const SizedBox(width: 6),
                      Text('Message', style: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.grey, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ],

          if (applicant.status == 'rejected') ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: _badge('Declined', AppTheme.grey.withOpacity(0.08), AppTheme.grey, AppTheme.grey.withOpacity(0.2)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.montserrat(fontSize: 14, color: AppTheme.black),
          ),
        ),
      ],
    );
  }

  TextStyle _sectionStyle() => GoogleFonts.cormorantGaramond(
        fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.black,
      );

  Widget _emptyState(IconData icon, String message, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppTheme.grey.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(message, style: GoogleFonts.montserrat(color: AppTheme.grey)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.grey.withOpacity(0.7))),
          ],
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color textColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}
