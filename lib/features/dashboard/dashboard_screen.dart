import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/portfolio/portfolio_screen.dart';
import 'package:flutter_application_1/features/matchmaker/model_discovery_screen.dart';
import 'package:flutter_application_1/features/bookings/bookings_screen.dart';
import 'package:flutter_application_1/features/matchmaker/brand_jobs_screen.dart';
import 'package:flutter_application_1/features/payments/payments_screen.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_application_1/features/profile/feedback_screen.dart';
import 'package:flutter_application_1/features/profile/support_screen.dart';
import 'package:flutter_application_1/features/profile/settings_screen.dart';
import 'package:flutter_application_1/features/auth/role_selection_screen.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/features/brands/brand_profile_screen.dart';
import 'package:flutter_application_1/features/jobs/job_offers_screen.dart';
import 'package:flutter_application_1/features/payments/work_history_screen.dart';
import 'package:flutter_application_1/features/admin/admin_brand_applications_screen.dart';
import 'package:flutter_application_1/features/admin/admin_dashboard_screen.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  final String userType;

  const DashboardScreen({super.key, required this.userType});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  late final List<Widget> _pages;
  late final List<NavigationDestination> _destinations;

  @override
  void initState() {
    super.initState();
    if (widget.userType == 'model') {
      _pages = [
        const JobOffersScreen(),
        const PortfolioScreen(),
        const BookingsScreen(userType: 'model'),
        const WorkHistoryScreen(),
      ];
      _destinations = const [
        NavigationDestination(
            icon: Icon(LucideIcons.briefcase), label: 'Offers'),
        NavigationDestination(
            icon: Icon(LucideIcons.user), label: 'Portfolio'),
        NavigationDestination(
            icon: Icon(LucideIcons.calendarCheck), label: 'Bookings'),
        NavigationDestination(
            icon: Icon(LucideIcons.wallet), label: 'Work'),
      ];
    } else {
      _pages = [
        BrandProfileScreen(),
        ModelDiscoveryScreen(),
        BrandJobsScreen(),
        BookingsScreen(userType: 'brand'),
        PaymentsScreen(),
      ];
      _destinations = const [
        NavigationDestination(
            icon: Icon(LucideIcons.briefcase), label: 'My Brand'),
        NavigationDestination(
            icon: Icon(LucideIcons.users), label: 'Models'),
        NavigationDestination(
            icon: Icon(LucideIcons.list), label: 'Jobs'),
        NavigationDestination(
            icon: Icon(LucideIcons.calendarCheck), label: 'Bookings'),
        NavigationDestination(
            icon: Icon(LucideIcons.creditCard), label: 'Payments'),
      ];
    }
  }

  void _handleLogout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushReplacement(
      MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
    );
  }

  void _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: GoogleFonts.cormorantGaramond(
            fontWeight: FontWeight.bold,
            color: AppTheme.black,
          ),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action is irreversible.',
          style: GoogleFonts.montserrat(color: AppTheme.grey),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authService.deleteAccount();
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to delete account: $e')));
      }
    }
  }

  String _getPageTitle() {
    if (widget.userType == 'model') {
      switch (_selectedIndex) {
        case 0:
          return 'Job Offers';
        case 1:
          return 'Portfolio';
        case 2:
          return 'Bookings';
        case 3:
          return 'Work & Balance';
        default:
          return 'CAZTIQ';
      }
    } else {
      switch (_selectedIndex) {
        case 0:
          return 'My Brand';
        case 1:
          return 'Models';
        case 2:
          return 'Jobs';
        case 3:
          return 'Bookings';
        case 4:
          return 'Payments';
        default:
          return 'CAZTIQ';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        title: Text(
          _getPageTitle(),
          style: GoogleFonts.cormorantGaramond(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppTheme.black,
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.white,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.cream),
              child: Center(
                child: Text(
                  'CAZTIQ',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.black,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(LucideIcons.messageSquare),
              title: const Text('Comments & Feedback'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const FeedbackScreen()));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.helpCircle),
              title: const Text('Support'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const SupportScreen()));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.settings),
              title: const Text('Account Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.shield),
              title: const Text('Admin Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminDashboardScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.building2),
              title: const Text('Admin - Brand Applications'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const AdminBrandApplicationsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.refreshCw),
              title: Text(
                  'Switch to ${widget.userType == 'model' ? 'Brand Owner' : 'Model'}'),
              onTap: () async {
                final newRole =
                    widget.userType == 'model' ? 'brand' : 'model';
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_authService.currentUser!.uid)
                    .update({
                  'role': newRole,
                });
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) =>
                          DashboardScreen(userType: newRole)),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(LucideIcons.logOut),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: Colors.red),
              title: const Text('Delete Account',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleDeleteAccount();
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: _destinations,
      ),
    );
  }
}
