import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/services/booking_service.dart';
import 'package:flutter_application_1/core/services/payment_service.dart';
import 'package:flutter_application_1/core/models/booking_model.dart';
import 'package:flutter_application_1/core/models/payment_model.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
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
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Premium Header with Stripe Notice
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financials',
                      style: GoogleFonts.tinos(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text('Secure transactions via Stripe', style: TextStyle(color: Colors.white24, fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.shieldCheck, color: Color(0xFF818CF8), size: 14),
                      const SizedBox(width: 8),
                      const Text('ENCRYPTED', style: TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Custom Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  Tab(text: 'History'),
                  Tab(text: 'Upcoming'),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PaymentHistoryTab(authService: _authService, paymentService: _paymentService),
                _UpcomingPayoutsTab(),
              ],
            ),
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
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final payments = snapshot.data ?? [];

        if (payments.isEmpty) {
          return _emptyState(LucideIcons.history, 'No payment history yet');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: payments.length,
          itemBuilder: (context, index) => _PaymentCard(payment: payments[index]),
        );
      },
    );
  }
}

class _UpcomingPayoutsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // This would fetch bookings with 'awaiting_confirmation' status
    return _emptyState(LucideIcons.calendarClock, 'No upcoming payouts');
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showPaymentDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.check, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.jobTitle,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Completed on ${DateFormat('MMM d, yyyy').format(payment.createdAt)}',
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${payment.amount.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const Icon(LucideIcons.chevronRight, size: 14, color: Colors.white24),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentDetail(BuildContext context) {
    final modelRate = payment.amount;
    final platformFee = modelRate * 0.1;
    final total = modelRate + platformFee;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Payment Detail', style: GoogleFonts.tinos(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 32),
            _detailSection('Project', payment.jobTitle),
            const SizedBox(height: 16),
            _detailSection('Transaction ID', 'TRX-${payment.id.hashCode.toString().toUpperCase()}'),
            const SizedBox(height: 32),
            const Divider(color: Colors.white10),
            const SizedBox(height: 32),
            _feeRow('Model Rate', '\$${modelRate.toStringAsFixed(2)}'),
            _feeRow('Platform Fee (10%)', '\$${platformFee.toStringAsFixed(2)}'),
            _feeRow('Stripe Processing', 'Included', isAccent: true),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Charged', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt downloading...')));
                },
                icon: const Icon(LucideIcons.download, size: 18),
                label: const Text('Download Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _detailSection(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }

  Widget _feeRow(String label, String value, {bool isAccent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 14)),
          Text(value, style: TextStyle(color: isAccent ? const Color(0xFF818CF8) : Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

Widget _emptyState(IconData icon, String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: Colors.white10),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(color: Colors.white.withOpacity(0.2)),
        ),
      ],
    ),
  );
}
