import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/services/booking_service.dart';
import 'package:flutter_application_1/core/services/payment_service.dart';
import 'package:flutter_application_1/core/models/booking_model.dart';
import 'package:flutter_application_1/core/models/payment_model.dart';
import 'package:intl/intl.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final BookingService _bookingService = BookingService();
  final PaymentService _paymentService = PaymentService();

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payments',
          style: GoogleFonts.tinos(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          tabs: const [
            Tab(text: 'Pay Model'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PayModelTab(
            authService: _authService,
            bookingService: _bookingService,
            paymentService: _paymentService,
          ),
          _PaymentHistoryTab(
            authService: _authService,
            paymentService: _paymentService,
          ),
        ],
      ),
    );
  }
}

class _PayModelTab extends StatelessWidget {
  final AuthService authService;
  final BookingService bookingService;
  final PaymentService paymentService;

  const _PayModelTab({
    required this.authService,
    required this.bookingService,
    required this.paymentService,
  });

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    if (user == null) return const Center(child: Text('Please log in'));

    return StreamBuilder<List<BookingModel>>(
      stream: bookingService.getUserBookings(user.uid, 'brand'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final completedBookings = snapshot.data?.where((b) => b.status == 'completed').toList() ?? [];

        if (completedBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.checkCircle, size: 48, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  'No pending payments.',
                  style: GoogleFonts.inter(color: Colors.white54),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: completedBookings.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final booking = completedBookings[index];
            return _PayModelCard(
              booking: booking,
              onPay: () => _showPaymentOptions(context, booking),
            );
          },
        );
      },
    );
  }

  void _showPaymentOptions(BuildContext context, BookingModel booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141419),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Payment Method',
              style: GoogleFonts.tinos(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Paying \$${booking.rate ?? 0.0} for ${booking.jobTitle ?? 'Job'}',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _PaymentMethodTile(
              icon: LucideIcons.creditCard,
              label: 'PayPal',
              onTap: () => _processPayment(context, booking, 'paypal'),
            ),
            _PaymentMethodTile(
              icon: LucideIcons.creditCard,
              label: 'Credit Card',
              onTap: () => _processPayment(context, booking, 'card'),
            ),
            _PaymentMethodTile(
              icon: LucideIcons.creditCard,
              label: 'Debit Card',
              onTap: () => _processPayment(context, booking, 'debit'),
            ),
            _PaymentMethodTile(
              icon: LucideIcons.wallet,
              label: 'Credit',
              onTap: () => _processPayment(context, booking, 'credit'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(BuildContext context, BookingModel booking, String method) async {
    Navigator.pop(context); // Close bottom sheet
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final payment = PaymentModel(
        id: '',
        brandId: booking.brandId,
        modelId: booking.modelId,
        bookingId: booking.id,
        jobTitle: booking.jobTitle ?? 'Job',
        amount: booking.rate ?? 0.0,
        method: method,
        status: 'completed',
        createdAt: DateTime.now(),
      );

      await paymentService.createPayment(payment);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment of \$${booking.rate} successful via ${method.toUpperCase()}!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class _PayModelCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onPay;

  const _PayModelCard({required this.booking, required this.onPay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.jobTitle ?? 'Job Booking',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Model ID: ${booking.modelId.substring(0, 8)}...',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${booking.rate ?? 0.0}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF818CF8),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onPay,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }
}

class _PaymentHistoryTab extends StatelessWidget {
  final AuthService authService;
  final PaymentService paymentService;

  const _PaymentHistoryTab({required this.authService, required this.paymentService});

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    if (user == null) return const Center(child: Text('Please log in'));

    return StreamBuilder<List<PaymentModel>>(
      stream: paymentService.getBrandPayments(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data ?? [];

        if (payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.history, size: 48, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  'No payment history.',
                  style: GoogleFonts.inter(color: Colors.white54),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final payment = payments[index];
            return _PaymentHistoryCard(payment: payment);
          },
        );
      },
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  final PaymentModel payment;

  const _PaymentHistoryCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141419),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.arrowUpRight, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.jobTitle,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                Text(
                  'via ${payment.method.toUpperCase()}',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-\$${payment.amount}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                DateFormat('MMM d').format(payment.createdAt),
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Colors.white24),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
