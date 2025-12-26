import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/portfolio/portfolio_screen.dart';
import 'package:flutter_application_1/features/matchmaker/matchmaker_screen.dart';
import 'package:flutter_application_1/features/matchmaker/model_discovery_screen.dart';
import 'package:flutter_application_1/features/chat/chat_list_screen.dart';
import 'package:flutter_application_1/features/bookings/bookings_screen.dart';
import 'package:flutter_application_1/features/profile/brand_profile_screen.dart';
import 'package:flutter_application_1/features/matchmaker/brand_jobs_screen.dart';

import 'package:flutter_application_1/features/profile/feedback_screen.dart';
import 'package:flutter_application_1/features/profile/support_screen.dart';
import 'package:flutter_application_1/features/profile/settings_screen.dart';
import 'package:flutter_application_1/features/auth/role_selection_screen.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';

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
        const MatchmakerScreen(), // Home/Feed
        const PortfolioScreen(), // Portfolio/Profile
        const ChatListScreen(),
        const BookingsScreen(userType: 'model'),
      ];
      _destinations = const [
        NavigationDestination(icon: Icon(LucideIcons.home), label: 'Home'),
        NavigationDestination(icon: Icon(LucideIcons.user), label: 'Portfolio'),
        NavigationDestination(icon: Icon(LucideIcons.messageCircle), label: 'Chat'),
        NavigationDestination(icon: Icon(LucideIcons.calendarCheck), label: 'Bookings'),
      ];
    } else {
      _pages = [
        const BrandProfileScreen(), // My Brand
        const ModelDiscoveryScreen(), // Models
        const BrandJobsScreen(), // Jobs
        const BookingsScreen(userType: 'brand'), // Bookings
      ];
      _destinations = const [
        NavigationDestination(icon: Icon(LucideIcons.briefcase), label: 'My Brand'),
        NavigationDestination(icon: Icon(LucideIcons.users), label: 'Models'),
        NavigationDestination(icon: Icon(LucideIcons.list), label: 'Jobs'),
        NavigationDestination(icon: Icon(LucideIcons.calendarCheck), label: 'Bookings'),
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
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action is irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete account: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CASTIQ',
          style: GoogleFonts.tinos(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            letterSpacing: 2,
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              child: Center(
                child: Text(
                  'CASTIQ',
                  style: GoogleFonts.tinos(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(LucideIcons.messageSquare),
              title: const Text('Comments & Feedback'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackScreen()));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.helpCircle),
              title: const Text('Support'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen()));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.settings),
              title: const Text('Account Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
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
              title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
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
