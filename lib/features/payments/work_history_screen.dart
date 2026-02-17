import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/services/payment_service.dart';
import 'package:flutter_application_1/core/models/payment_model.dart';
import 'package:intl/intl.dart';

class WorkHistoryScreen extends StatelessWidget {
  const WorkHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, mocking balance data until integrated with real Stripe Connect account data
    const double availableBalance = 0.00;
    const double pendingBalance = 0.00;
    final AuthService authService = AuthService();
    final PaymentService paymentService = PaymentService();
    final userId = authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'WORK & BALANCE',
                  style: GoogleFonts.didactGothic(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            // Balance Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(0), // Sharp edges
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AVAILABLE',
                                style: GoogleFonts.inter(
                                  color: Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${availableBalance.toStringAsFixed(2)}',
                                style: GoogleFonts.didactGothic(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              'WITHDRAW',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(LucideIcons.clock, size: 14, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'PENDING: \$${pendingBalance.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 48)),

            // History Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'HISTORY',
                  style: GoogleFonts.didactGothic(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // History List
            if (userId != null)
              StreamBuilder<List<PaymentModel>>(
                stream: paymentService.getModelPayments(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                  }

                  final payments = snapshot.data ?? [];

                  if (payments.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No completed payments yet.',
                          style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final payment = payments[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.black12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PAYMENT RECEIVED',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      letterSpacing: 1.0,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(payment.createdAt ?? DateTime.now()),
                                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              Text(
                                '+\$${payment.amount.toStringAsFixed(2)}',
                                style: GoogleFonts.didactGothic(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: payments.length,
                    ),
                  );
                },
              )
            else
              const SliverToBoxAdapter(child: SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
