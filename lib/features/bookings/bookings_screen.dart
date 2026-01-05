import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/bookings/booking_detail_screen.dart';

import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/services/booking_service.dart';
import 'package:flutter_application_1/core/models/booking_model.dart';
import 'package:intl/intl.dart';

class BookingsScreen extends StatelessWidget {
  final String userType;

  const BookingsScreen({super.key, required this.userType});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const Tab(text: 'Action Required'),
      const Tab(text: 'Active'),
      const Tab(text: 'Completed'),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.inter(),
            indicatorColor: const Color(0xFF6366F1),
            tabs: tabs,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _BookingList(statusTab: 'Action Required', userType: userType),
                _BookingList(statusTab: 'Active', userType: userType),
                _BookingList(statusTab: 'Completed', userType: userType),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final String statusTab;
  final String userType;

  const _BookingList({required this.statusTab, required this.userType});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final bookingService = BookingService();
    final user = authService.currentUser;

    if (user == null) return const Center(child: Text('Please log in'));

    return StreamBuilder<List<BookingModel>>(
      stream: bookingService.getUserBookings(user.uid, userType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allBookings = snapshot.data ?? [];
        
        // Filter based on tab status
        final bookings = allBookings.where((b) {
          if (statusTab == 'Action Required') {
            return ['pending', 'confirmed', 'signed'].contains(b.status);
          } else if (statusTab == 'Active') {
            return b.status == 'in_progress';
          } else if (statusTab == 'Completed') {
            return ['completed', 'paid'].contains(b.status);
          } else {
            return false; // Drafts not implemented yet
          }
        }).toList();

        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.calendar, size: 48, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  'No bookings in this category.',
                  style: GoogleFonts.inter(color: Colors.white54),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _BookingCard(booking: bookings[index], userType: userType);
          },
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final String userType;

  const _BookingCard({required this.booking, required this.userType});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141419),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          highlightColor: Colors.white.withOpacity(0.1),
          splashColor: Colors.white.withOpacity(0.05),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailScreen(
                  userType: userType,
                  bookingId: booking.id,
                  initialStatus: booking.status,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.user, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // In a real app, we'd fetch the counterpart's name
                          Text(
                            userType == 'brand' ? 'Model Application' : 'Job Application',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(booking.status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              booking.status.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: _getStatusColor(booking.status),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Booking ID: ${booking.id.substring(0, 8)}...',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(booking.createdAt),
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'signed':
        return Colors.indigo;
      case 'in_progress':
        return Colors.amber;
      case 'completed':
        return Colors.green;
      case 'paid':
        return Colors.teal;
      case 'declined':
        return Colors.red;
      default:
        return Colors.white;
    }
  }
}
