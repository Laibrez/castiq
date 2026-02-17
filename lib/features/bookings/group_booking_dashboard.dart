import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/core/models/job_model.dart';
import 'package:flutter_application_1/core/models/booking_model.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class GroupBookingDashboard extends StatefulWidget {
  final JobModel job;
  final List<BookingModel> bookings;

  const GroupBookingDashboard({
    super.key,
    required this.job,
    required this.bookings,
  });

  @override
  State<GroupBookingDashboard> createState() => _GroupBookingDashboardState();
}

class _GroupBookingDashboardState extends State<GroupBookingDashboard> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Overview', 'Shared Chat', 'Contracts', 'Payments'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.job.title,
              style: GoogleFonts.cormorantGaramond(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.black),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'GROUP PROJECT',
                style: TextStyle(color: AppTheme.gold, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Sub-navigation
          _buildSubNav(),
          
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: _tabs.asMap().entries.map((entry) {
            final isSelected = _selectedTabIndex == entry.key;
            return GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = entry.key),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.black : AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? AppTheme.black : const Color(0xFFE0DCD5)),
                  boxShadow: isSelected ? null : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  entry.value,
                  style: GoogleFonts.montserrat(
                    color: isSelected ? AppTheme.white : AppTheme.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: return _buildOverview();
      case 1: return _buildSharedChat();
      case 2: return _buildContracts();
      case 3: return _buildPayments();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Summary Card
          _infoCard(
            title: 'Project Summary',
            child: Column(
              children: [
                _summaryRow(LucideIcons.calendar, 'Production Date', DateFormat('MMMM d, yyyy').format(widget.job.shootDate)),
                _summaryRow(LucideIcons.mapPin, 'Location', widget.job.location),
                _summaryRow(LucideIcons.users, 'Team Size', '${widget.bookings.length} Models Confirmed'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'Confirmed Models',
            style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.w400, color: AppTheme.black),
          ),
          const SizedBox(height: 16),
          ...widget.bookings.map((booking) => _modelListItem(booking)),
        ],
      ),
    );
  }

  Widget _buildSharedChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE0DCD5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(LucideIcons.messagesSquare, color: AppTheme.gold, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'Group Production Chat',
            style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.w400, color: AppTheme.black),
          ),
          const SizedBox(height: 8),
          Text(
            'Unified communication for all team members.\nActivated for this project.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(color: AppTheme.grey, height: 1.5),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.black,
              foregroundColor: AppTheme.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Open Group Chat', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildContracts() {
    final docTypes = ['Model Release', 'Usage Rights', 'NDA', 'Booking Agreement'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Uploaded Documents Section
          _infoCard(
            title: 'Project Documents',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...docTypes.map((type) {
                  final isUploaded = widget.job.documents.containsKey(type);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Icon(
                          isUploaded ? LucideIcons.fileCheck : LucideIcons.filePlus,
                          color: isUploaded ? Colors.green : AppTheme.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(type, style: GoogleFonts.montserrat(color: isUploaded ? AppTheme.black : AppTheme.grey, fontWeight: isUploaded ? FontWeight.bold : FontWeight.w500)),
                              if (isUploaded)
                                Text('Uploaded ${DateFormat('MMM d').format(widget.job.createdAt)}', style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                        if (!isUploaded)
                          TextButton(
                            onPressed: () {
                              // Simulate Upload
                              _simulateUpload(type);
                            },
                            child: const Text('Upload', style: TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.bold)),
                          )
                        else
                          const Icon(LucideIcons.download, size: 16, color: AppTheme.grey),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 2. Signature Status Matrix
          Text(
            'Signature Tracking',
            style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.w400, color: AppTheme.black),
          ),
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE0DCD5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 60,
                dataRowHeight: 70,
                horizontalMargin: 24,
                columnSpacing: 40,
                columns: [
                  DataColumn(label: Text('Model', style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 11, fontWeight: FontWeight.bold))),
                  ...docTypes.map((type) => DataColumn(
                    label: Text(type.split(' ').first, style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 11, fontWeight: FontWeight.bold))
                  )),
                ],
                rows: widget.bookings.map((booking) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            const CircleAvatar(radius: 12, backgroundColor: AppTheme.cream, child: Icon(LucideIcons.user, size: 12, color: AppTheme.grey)),
                            const SizedBox(width: 12),
                            Text('Model #${booking.modelId.substring(0, 4)}', style: GoogleFonts.montserrat(color: AppTheme.black, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      ...docTypes.map((type) {
                        final isSigned = booking.signedDocuments.containsKey(type);
                        return DataCell(
                          Icon(
                            isSigned ? LucideIcons.checkCircle2 : LucideIcons.clock,
                            color: isSigned ? Colors.green : AppTheme.grey.withOpacity(0.3),
                            size: 18,
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _simulateUpload(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.black,
        content: Text('Uploading $type... (Simulated)', style: const TextStyle(color: AppTheme.white)),
      ),
    );
  }

  Widget _buildPayments() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: widget.bookings.length,
      itemBuilder: (context, index) {
        final booking = widget.bookings[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0DCD5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.cream,
                child: Icon(LucideIcons.user, color: AppTheme.grey, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Model #${booking.modelId.substring(0, 5)}', style: GoogleFonts.montserrat(color: AppTheme.black, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('\$${booking.rate?.toInt() ?? 0}', style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0DCD5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.w400, color: AppTheme.black)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.grey),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.montserrat(color: AppTheme.black, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modelListItem(BookingModel booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0DCD5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: AppTheme.cream),
          const SizedBox(width: 16),
          Expanded(
            child: Text('Model ID: ${booking.modelId.substring(0, 8)}...', style: GoogleFonts.montserrat(color: AppTheme.black)),
          ),
          const Icon(LucideIcons.chevronRight, color: AppTheme.grey, size: 16),
        ],
      ),
    );
  }

  Widget _fileItem(String name, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(LucideIcons.fileText, color: AppTheme.gold, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.montserrat(color: AppTheme.black, fontSize: 14)),
                const SizedBox(height: 2),
                Text(date, style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 11)),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(LucideIcons.download, size: 16, color: AppTheme.grey)),
        ],
      ),
    );
  }
}
