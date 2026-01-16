import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/bookings/booking_detail_screen.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/services/booking_service.dart';
import 'package:flutter_application_1/core/models/booking_model.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingsScreen extends StatefulWidget {
  final String userType;

  const BookingsScreen({super.key, required this.userType});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final BookingService _bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('Please log in', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Custom Tab Bar for Brands
          if (widget.userType == 'brand')
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
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Canceled'),
                  ],
                ),
              ),
            ),
          
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: _bookingService.getUserBookings(user.uid, widget.userType),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                final allBookings = snapshot.data ?? [];

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingList(allBookings, 'upcoming'),
                    _buildBookingList(allBookings, 'completed'),
                    _buildBookingList(allBookings, 'canceled'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList(List<BookingModel> bookings, String filter) {
    List<BookingModel> filtered;
    
    switch (filter) {
      case 'upcoming':
        filtered = bookings.where((b) => ['pending', 'confirmed', 'signed', 'in_progress', 'awaiting_confirmation'].contains(b.status)).toList();
        break;
      case 'completed':
        filtered = bookings.where((b) => ['completed', 'paid'].contains(b.status)).toList();
        break;
      case 'canceled':
        filtered = bookings.where((b) => ['canceled', 'declined'].contains(b.status)).toList();
        break;
      default:
        filtered = bookings;
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.calendarX, size: 48, color: Colors.white10),
            const SizedBox(height: 16),
            Text(
              'No $filter bookings',
              style: TextStyle(color: Colors.white.withOpacity(0.2)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _BookingCard(
        booking: filtered[index],
        userType: widget.userType,
      ),
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
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Model/Brand Avatar Placeholder
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(userType == 'brand' ? booking.modelId : booking.brandId).get(),
                      builder: (context, snapshot) {
                        final userData = snapshot.data?.data() as Map<String, dynamic>?;
                        final name = userData?['name'] ?? (userType == 'brand' ? 'Model' : 'Brand');
                        final photoUrl = userData?['profileImageUrl'];

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                image: photoUrl != null 
                                  ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                                  : null,
                              ),
                              child: photoUrl == null ? const Icon(LucideIcons.user, color: Colors.white24, size: 24) : null,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  booking.jobTitle ?? 'Model Booking',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const Spacer(),
                    _statusBadge(booking.status),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _infoItem(LucideIcons.calendar, DateFormat('MMM d, h:mm a').format(booking.date ?? booking.createdAt)),
                    const SizedBox(width: 20),
                    _infoItem(LucideIcons.mapPin, booking.location ?? 'Miami, FL'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoItem(LucideIcons.dollarSign, '${booking.rate?.toInt() ?? 0} total'),
                    if (booking.initiatedByBrand)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'INVITATION',
                          style: TextStyle(
                            color: Color(0xFF818CF8),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'pending': color = Colors.orange; break;
      case 'confirmed': color = Colors.blue; break;
      case 'signed': color = Colors.indigo; break;
      case 'in_progress': color = Colors.amber; break;
      case 'completed': color = Colors.green; break;
      case 'paid': color = Colors.green; break;
      case 'declined':
      case 'canceled': color = Colors.red; break;
      default: color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white24),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}
