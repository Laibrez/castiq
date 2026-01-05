import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/chat/chat_detail_screen.dart';
import 'package:flutter_application_1/core/services/booking_service.dart';
import 'package:flutter_application_1/core/models/booking_model.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingDetailScreen extends StatefulWidget {
  final String userType;
  final String bookingId;
  final String? initialStatus;

  const BookingDetailScreen({
    super.key,
    required this.userType,
    required this.bookingId,
    this.initialStatus,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookingService _bookingService = BookingService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      await _bookingService.updateBookingStatus(widget.bookingId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text('Booking not found')));
        }

        final booking = BookingModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Booking #${booking.id.substring(0, 8)}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(),
              indicatorColor: const Color(0xFF6366F1),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Payment'),
                Tab(text: 'Contract'),
                Tab(text: 'Chat'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(booking),
              _buildPaymentTab(booking),
              _BookingContract(
                userType: widget.userType,
                isSigned: ['signed', 'in_progress', 'completed', 'paid'].contains(booking.status),
                onSignContract: () => _updateStatus('signed'),
              ),
              const ChatDetailScreen(isRequested: false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(BookingModel booking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (booking.status == 'completed' || booking.status == 'paid')
            _buildJobSummaryFlashcard(booking)
          else
            _buildInfoCard(
              title: 'Job Application',
              subtitle: widget.userType == 'brand' ? 'Model Application' : 'Brand Application',
              details: [
                {'icon': LucideIcons.calendar, 'text': DateFormat('MMM d, yyyy').format(booking.createdAt)},
                {'icon': LucideIcons.info, 'text': 'Status: ${booking.status.toUpperCase()}'},
              ],
            ),
          const SizedBox(height: 24),
          _buildSectionTitle('Status Timeline'),
          const SizedBox(height: 16),
          _buildStatusTimeline(booking.status),
          const SizedBox(height: 24),
          _buildActions(booking),
        ],
      ),
    );
  }

  Widget _buildPaymentTab(BookingModel booking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPaymentMethodSection(booking),
          const SizedBox(height: 24),
          if (widget.userType == 'brand' && booking.status == 'completed')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _updateStatus('paid'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Pay Now'),
              ),
            )
          else if (booking.status == 'paid')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.checkCircle, color: Colors.green),
                  const SizedBox(width: 12),
                  Text(
                    'Payment Completed',
                    style: GoogleFonts.inter(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(BookingModel booking) {
    final method = booking.paymentMethod ?? 'visa'; // Default to visa for demo
    IconData icon;
    String label;

    switch (method.toLowerCase()) {
      case 'mastercard':
        icon = LucideIcons.creditCard;
        label = 'Mastercard';
        break;
      case 'paypal':
        icon = LucideIcons.creditCard; // PayPal icon not found, using creditCard
        label = 'PayPal';
        break;
      case 'visa':
      default:
        icon = LucideIcons.creditCard;
        label = 'Visa';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Payment Method'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141419),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF6366F1)),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              const Text(
                '**** 4242',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BookingModel booking) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (widget.userType == 'brand') {
      if (booking.status == 'pending') {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStatus('confirmed'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Accept'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStatus('declined'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Decline'),
              ),
            ),
          ],
        );
      } else if (booking.status == 'signed') {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _updateStatus('in_progress'),
            child: const Text('Start Job'),
          ),
        );
      } else if (booking.status == 'in_progress') {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _updateStatus('completed'),
            child: const Text('Complete Job'),
          ),
        );
      }
    } else {
      // Model actions
      if (booking.status == 'confirmed') {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _tabController.animateTo(1),
            child: const Text('Go to Contract to Sign'),
          ),
        );
      } else if (booking.status == 'in_progress') {
        return Column(
          children: [
            if (booking.checkInTime == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _bookingService.updateCheckInOut(booking.id, checkIn: DateTime.now()),
                  child: const Text('Check In'),
                ),
              )
            else if (booking.checkOutTime == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _bookingService.updateCheckInOut(booking.id, checkOut: DateTime.now()),
                  child: const Text('Check Out'),
                ),
              ),
          ],
        );
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildJobSummaryFlashcard(BookingModel booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('JOB COMPLETED', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('Booking #${booking.id.substring(0, 8)}', style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Status', style: GoogleFonts.inter(color: Colors.white)),
              Text(booking.status.toUpperCase(), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String subtitle, required List<Map<String, dynamic>> details}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141419),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(subtitle, style: GoogleFonts.inter(color: Colors.white70)),
          const SizedBox(height: 16),
          ...details.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(d['icon'] as IconData, size: 16, color: Colors.white54),
                const SizedBox(width: 12),
                Text(d['text'] as String, style: GoogleFonts.inter(color: Colors.white70)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(String currentStatus) {
    bool isConfirmed = ['confirmed', 'signed', 'in_progress', 'completed', 'paid'].contains(currentStatus);
    bool isSigned = ['signed', 'in_progress', 'completed', 'paid'].contains(currentStatus);
    bool isInProgress = ['in_progress', 'completed', 'paid'].contains(currentStatus);
    bool isCompleted = ['completed', 'paid'].contains(currentStatus);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTimelineStep('Pending', true),
        _buildTimelineLine(isConfirmed),
        _buildTimelineStep('Confirmed', isConfirmed),
        _buildTimelineLine(isSigned),
        _buildTimelineStep('Signed', isSigned),
        _buildTimelineLine(isInProgress),
        _buildTimelineStep('Active', isInProgress),
        _buildTimelineLine(isCompleted),
        _buildTimelineStep('Done', isCompleted),
      ],
    );
  }

  Widget _buildTimelineStep(String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6366F1) : Colors.white24,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 8, color: isActive ? Colors.white : Colors.white24)),
      ],
    );
  }

  Widget _buildTimelineLine(bool isActive) {
    return Expanded(child: Container(height: 2, color: isActive ? const Color(0xFF6366F1) : Colors.white24));
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white));
  }
}

class _BookingContract extends StatelessWidget {
  final String userType;
  final bool isSigned;
  final VoidCallback onSignContract;

  const _BookingContract({required this.userType, required this.isSigned, required this.onSignContract});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            height: 300,
            width: double.infinity,
            color: Colors.white10,
            child: const Center(child: Text('Contract Document Preview', style: TextStyle(color: Colors.white54))),
          ),
          const SizedBox(height: 24),
          if (!isSigned && userType == 'model')
            ElevatedButton(onPressed: onSignContract, child: const Text('Sign Contract'))
          else
            Text(isSigned ? 'Contract Signed' : 'Awaiting Model Signature', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
