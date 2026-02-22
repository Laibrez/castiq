import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/services/payment_service.dart'; // Fake service for now
import 'package:flutter_application_1/core/models/payment_model.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
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
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          const SizedBox(height: 24),

          // Balance Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE0DCD5)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Balance',
                        style: GoogleFonts.montserrat(
                          color: AppTheme.grey,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.arrowUpRight, color: AppTheme.gold, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '+12.5%',
                              style: GoogleFonts.montserrat(
                                color: AppTheme.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\$12,450.00',
                    style: GoogleFonts.cormorantGaramond(
                      color: AppTheme.black,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.black,
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('Withdraw Funds', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Tabs
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0DCD5)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0DCD5)),
              ),
              labelColor: AppTheme.black,
              unselectedLabelColor: AppTheme.grey,
              labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w500, fontSize: 13),
              dividerColor: Colors.transparent,
              indicatorPadding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'History'),
                Tab(text: 'Upcoming'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // List
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
    final userId = authService.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<List<PaymentModel>>(
      stream: paymentService.getUserPayments(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
        }

        final payments = snapshot.data ?? [];
        if (payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.receipt, size: 48, color: AppTheme.grey.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text('No payment history yet', style: GoogleFonts.montserrat(color: AppTheme.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            return _PaymentCard(payment: payments[index]);
          },
        );
      },
    );
  }
}

class _UpcomingPayoutsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final upcoming = [
      PaymentModel(
        id: '1',
        brandId: 'brand1',
        modelId: 'model1',
        bookingId: 'booking1',
        jobTitle: 'Summer Campaign 2024',
        amount: 3200.00,
        method: 'card',
        status: 'pending',
        createdAt: DateTime.now().add(const Duration(days: 2)),
      ),
      PaymentModel(
        id: '2',
        brandId: 'brand2',
        modelId: 'model1',
        bookingId: 'booking2',
        jobTitle: 'Editorial Shoot',
        amount: 1500.00,
        method: 'paypal',
        status: 'processing',
        createdAt: DateTime.now().add(const Duration(days: 5)),
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: upcoming.length,
      itemBuilder: (context, index) {
        return _PaymentCard(payment: upcoming[index], isUpcoming: true);
      },
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final bool isUpcoming;

  const _PaymentCard({required this.payment, this.isUpcoming = false});

  @override
  Widget build(BuildContext context) {
    final isCompleted = payment.status == 'completed';
    final isProcessing = payment.status == 'processing';

    Color statusColor;
    IconData statusIcon;

    if (isCompleted) {
      statusColor = AppTheme.success;
      statusIcon = LucideIcons.checkCircle;
    } else if (isProcessing) {
      statusColor = AppTheme.gold;
      statusIcon = LucideIcons.refreshCw;
    } else {
      statusColor = AppTheme.grey;
      statusIcon = LucideIcons.clock;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0DCD5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isUpcoming ? LucideIcons.calendarClock : LucideIcons.arrowDownLeft,
              color: AppTheme.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.jobTitle,
                  style: GoogleFonts.cormorantGaramond(
                    color: AppTheme.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat.yMMMd().format(payment.createdAt),
                  style: GoogleFonts.montserrat(
                    color: AppTheme.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+\$${payment.amount.toStringAsFixed(2)}',
                style: GoogleFonts.montserrat(
                  color: AppTheme.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(statusIcon, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    payment.status.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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
      backgroundColor: AppTheme.white,
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
                Text('Payment Detail', style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.black)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, color: AppTheme.black)),
              ],
            ),
            const SizedBox(height: 32),
            _detailSection('Project', payment.jobTitle),
            const SizedBox(height: 16),
            _detailSection('Transaction ID', 'TRX-${payment.id.hashCode.toString().toUpperCase()}'),
            const SizedBox(height: 32),
            const Divider(color: Color(0xFFE0DCD5)),
            const SizedBox(height: 32),
            _feeRow('Model Rate', '\$${modelRate.toStringAsFixed(2)}'),
            _feeRow('Platform Fee (10%)', '\$${platformFee.toStringAsFixed(2)}'),
            _feeRow('Stripe Processing', 'Included', isAccent: true),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Charged', style: TextStyle(color: AppTheme.black, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.black, fontSize: 24, fontWeight: FontWeight.bold)),
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
                  backgroundColor: AppTheme.black,
                  foregroundColor: AppTheme.white,
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
        Text(label, style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.montserrat(color: AppTheme.black, fontSize: 16)),
      ],
    );
  }

  Widget _feeRow(String label, String value, {bool isAccent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 14)),
          Text(value, style: GoogleFonts.montserrat(color: isAccent ? AppTheme.gold : AppTheme.black.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600)),
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
        Icon(icon, size: 48, color: AppTheme.grey.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text(
          message,
          style: GoogleFonts.montserrat(color: AppTheme.grey.withOpacity(0.5)),
        ),
      ],
    ),
  );
}
