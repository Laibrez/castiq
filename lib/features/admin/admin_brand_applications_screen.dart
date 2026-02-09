import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';

class AdminBrandApplicationsScreen extends StatefulWidget {
  const AdminBrandApplicationsScreen({super.key});

  @override
  State<AdminBrandApplicationsScreen> createState() =>
      _AdminBrandApplicationsScreenState();
}

class _AdminBrandApplicationsScreenState
    extends State<AdminBrandApplicationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        title: Text(
          'Brand Applications',
          style: GoogleFonts.cormorantGaramond(
            fontWeight: FontWeight.bold,
            color: AppTheme.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('brand_applications')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.gold));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.inbox,
                      size: 48, color: AppTheme.black.withOpacity(0.15)),
                  const SizedBox(height: 16),
                  Text(
                    'No brand applications yet',
                    style: GoogleFonts.montserrat(
                        color: AppTheme.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final applications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final data =
                  applications[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E4DE)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['brand_name'] ?? 'Unknown Brand',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['contact_email'] ?? '',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: AppTheme.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: status == 'approved'
                            ? const Color(0xFF2E7D32).withOpacity(0.1)
                            : status == 'rejected'
                                ? const Color(0xFFC62828).withOpacity(0.1)
                                : AppTheme.lightGold.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toString().toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: status == 'approved'
                              ? const Color(0xFF2E7D32)
                              : status == 'rejected'
                                  ? const Color(0xFFC62828)
                                  : AppTheme.gold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
