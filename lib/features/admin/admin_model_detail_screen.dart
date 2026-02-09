import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';

class AdminModelDetailScreen extends StatefulWidget {
  final String modelId;

  const AdminModelDetailScreen({super.key, required this.modelId});

  @override
  State<AdminModelDetailScreen> createState() => _AdminModelDetailScreenState();
}

class _AdminModelDetailScreenState extends State<AdminModelDetailScreen> {
  Map<String, dynamic>? _modelData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchModelData();
  }

  Future<void> _fetchModelData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('model_profiles')
          .doc(widget.modelId)
          .get();
      if (doc.exists) {
        setState(() {
          _modelData = doc.data();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        title: Text(
          'Model Profile',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.gold))
          : _modelData == null
              ? Center(
                  child: Text(
                    'Model not found',
                    style: GoogleFonts.montserrat(color: AppTheme.grey),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile header
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: AppTheme.lightGold,
                              backgroundImage:
                                  _modelData!['profile_photo_url'] != null
                                      ? NetworkImage(
                                          _modelData!['profile_photo_url'])
                                      : null,
                              child:
                                  _modelData!['profile_photo_url'] == null
                                      ? Text(
                                          '${(_modelData!['first_name'] ?? ' ')[0]}${(_modelData!['last_name'] ?? ' ')[0]}'
                                              .toUpperCase(),
                                          style: GoogleFonts.cormorantGaramond(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.black,
                                          ),
                                        )
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${_modelData!['first_name'] ?? ''} ${_modelData!['last_name'] ?? ''}'
                                  .trim(),
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_modelData!['city'] ?? ''}, ${_modelData!['country'] ?? ''}'
                                  .trim(),
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: AppTheme.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Categories
                      if (_modelData!['categories'] != null &&
                          (_modelData!['categories'] as List)
                              .isNotEmpty) ...[
                        Text(
                          'Categories',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              (_modelData!['categories'] as List)
                                  .map((cat) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.lightGold
                                              .withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: AppTheme.gold
                                                  .withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          cat.toString(),
                                          style: GoogleFonts.montserrat(
                                            fontSize: 12,
                                            color: AppTheme.gold,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Verification status
                      Text(
                        'Verification Status',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatusRow('ID Verified',
                          _modelData!['id_verified'] == true),
                      const SizedBox(height: 8),
                      _buildStatusRow('Portfolio Approved',
                          _modelData!['portfolio_approved'] == true),
                      const SizedBox(height: 8),
                      _buildStatusRow(
                          'Stripe Onboarding',
                          _modelData!['stripe_onboarding_complete'] ==
                              true),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E4DE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.montserrat(
                  color: AppTheme.black, fontSize: 14)),
          Icon(
            status ? LucideIcons.checkCircle : LucideIcons.xCircle,
            color: status ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            size: 20,
          ),
        ],
      ),
    );
  }
}
