import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/features/admin/admin_brand_applications_screen.dart';
import 'package:flutter_application_1/features/admin/admin_model_profiles_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  int _totalBrandApplications = 0;
  int _pendingBrandApplications = 0;
  int _approvedBrandApplications = 0;
  int _rejectedBrandApplications = 0;
  int _totalModels = 0;
  int _verifiedModels = 0;
  int _unverifiedModels = 0;
  int _portfoliosPendingReview = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      // Fetch brand applications
      final brandAppsSnapshot = await FirebaseFirestore.instance
          .collection('brand_applications')
          .get();

      final brandStats = {
        'total': brandAppsSnapshot.docs.length,
        'pending': brandAppsSnapshot.docs.where((doc) {
          final data = doc.data();
          return data['status'] == 'pending';
        }).length,
        'approved': brandAppsSnapshot.docs.where((doc) {
          final data = doc.data();
          return data['status'] == 'approved';
        }).length,
        'rejected': brandAppsSnapshot.docs.where((doc) {
          final data = doc.data();
          return data['status'] == 'rejected';
        }).length,
      };

      // Fetch model profiles
      final modelProfilesSnapshot = await FirebaseFirestore.instance
          .collection('model_profiles')
          .get();

      final modelStats = {
        'total': modelProfilesSnapshot.docs.length,
        'verified': modelProfilesSnapshot.docs.where((doc) {
          final data = doc.data();
          return data['id_verified'] == true;
        }).length,
        'unverified': modelProfilesSnapshot.docs.where((doc) {
          final data = doc.data();
          return data['id_verified'] != true;
        }).length,
        'portfoliosPending': modelProfilesSnapshot.docs.where((doc) {
          final data = doc.data();
          return data['portfolio_approved'] != true;
        }).length,
      };

      setState(() {
        _totalBrandApplications = brandStats['total'] ?? 0;
        _pendingBrandApplications = brandStats['pending'] ?? 0;
        _approvedBrandApplications = brandStats['approved'] ?? 0;
        _rejectedBrandApplications = brandStats['rejected'] ?? 0;
        _totalModels = modelStats['total'] ?? 0;
        _verifiedModels = modelStats['verified'] ?? 0;
        _unverifiedModels = modelStats['unverified'] ?? 0;
        _portfoliosPendingReview = modelStats['portfoliosPending'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching stats: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildQuickStatCard({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoading ? '–' : value.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard({
    required String title,
    required String description,
    required IconData icon,
    required int totalValue,
    required String totalLabel,
    required List<Map<String, dynamic>> stats,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                Icon(
                  LucideIcons.arrowRight,
                  color: Colors.white.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _isLoading ? '–' : totalValue.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  totalLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: stats.map((stat) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: stat['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${stat['value']} ${stat['label']}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.tinos(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here\'s what\'s happening with your platform today.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Quick Stats
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: [
                _buildQuickStatCard(
                  label: 'Pending reviews',
                  value: _pendingBrandApplications,
                  icon: LucideIcons.clock,
                  color: Colors.amber,
                  bgColor: Colors.amber.withOpacity(0.2),
                ),
                _buildQuickStatCard(
                  label: 'Portfolios pending',
                  value: _portfoliosPendingReview,
                  icon: LucideIcons.alertCircle,
                  color: Colors.blue,
                  bgColor: Colors.blue.withOpacity(0.2),
                ),
                _buildQuickStatCard(
                  label: 'Approved',
                  value: _approvedBrandApplications,
                  icon: LucideIcons.checkCircle,
                  color: Colors.green,
                  bgColor: Colors.green.withOpacity(0.2),
                ),
                _buildQuickStatCard(
                  label: 'Rejected',
                  value: _rejectedBrandApplications,
                  icon: LucideIcons.xCircle,
                  color: Colors.red,
                  bgColor: Colors.red.withOpacity(0.2),
                ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),

            // Main Cards
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildMainCard(
                    title: 'Brand Applications',
                    description: 'Review and manage brand registrations',
                    icon: LucideIcons.building2,
                    totalValue: _totalBrandApplications,
                    totalLabel: 'total',
                    stats: [
                      {
                        'value': _pendingBrandApplications,
                        'label': 'pending',
                        'color': Colors.amber,
                      },
                      {
                        'value': _approvedBrandApplications,
                        'label': 'approved',
                        'color': Colors.green,
                      },
                    ],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminBrandApplicationsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildMainCard(
                    title: 'Model Profiles',
                    description: 'Manage model registrations and portfolios',
                    icon: LucideIcons.users,
                    totalValue: _totalModels,
                    totalLabel: 'registered',
                    stats: [
                      {
                        'value': _verifiedModels,
                        'label': 'verified',
                        'color': Colors.green,
                      },
                      {
                        'value': _unverifiedModels,
                        'label': 'unverified',
                        'color': Colors.grey,
                      },
                    ],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminModelProfilesScreen(),
                        ),
                      );
                    },
                  ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildMainCard(
                        title: 'Brand Applications',
                        description: 'Review and manage brand registrations',
                        icon: LucideIcons.building2,
                        totalValue: _totalBrandApplications,
                        totalLabel: 'total',
                        stats: [
                          {
                            'value': _pendingBrandApplications,
                            'label': 'pending',
                            'color': Colors.amber,
                          },
                          {
                            'value': _approvedBrandApplications,
                            'label': 'approved',
                            'color': Colors.green,
                          },
                        ],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminBrandApplicationsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildMainCard(
                        title: 'Model Profiles',
                        description: 'Manage model registrations and portfolios',
                        icon: LucideIcons.users,
                        totalValue: _totalModels,
                        totalLabel: 'registered',
                        stats: [
                          {
                            'value': _verifiedModels,
                            'label': 'verified',
                            'color': Colors.green,
                          },
                          {
                            'value': _unverifiedModels,
                            'label': 'unverified',
                            'color': Colors.grey,
                          },
                        ],
                        onTap: () {
                          // TODO: Navigate to Model Profiles admin screen when created
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Model Profiles admin screen coming soon')),
                          );
                        },
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
