import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/chat/chat_detail_screen.dart';
import 'package:flutter_application_1/core/services/booking_service.dart';
import 'package:flutter_application_1/core/models/booking_model.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_application_1/core/widgets/share_modal.dart';

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
    _tabController = TabController(length: 6, vsync: this);
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
          return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.white)));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text('Booking not found', style: TextStyle(color: Colors.white))));
        }

        final booking = BookingModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Booking Detail',
              style: GoogleFonts.tinos(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.share, color: Colors.white),
                onPressed: () {
                  ShareModal.show(
                    context,
                    shareUrl: 'https://castiq-d85d4.web.app/booking/${booking.id}',
                    title: 'Booking #${booking.id.substring(0, 8)}',
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFF6366F1),
              indicatorWeight: 3,
              labelPadding: const EdgeInsets.symmetric(horizontal: 20),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Call Sheet'),
                Tab(text: 'Requirements'),
                Tab(text: 'Payment'),
                Tab(text: 'Contracts'),
                Tab(text: 'Chat'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(booking),
              _buildCallSheetTab(booking),
              _buildRequirementsTab(booking),
              _buildPaymentTab(booking),
              _buildContractsTab(booking),
              ChatDetailScreen(
                isRequested: false,
                isLocked: booking.status == 'pending',
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomActions(booking),
        );
      },
    );
  }

  Widget _buildOverviewTab(BookingModel booking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoCard(
            title: booking.jobTitle ?? 'Model Booking',
            subtitle: 'Confirmed Production',
            child: Column(
              children: [
                _detailRow(LucideIcons.calendar, 'Date', DateFormat('MMMM d, yyyy').format(booking.date ?? DateTime.now())),
                _detailRow(LucideIcons.mapPin, 'Location', booking.location ?? 'Miami, FL'),
                _detailRow(LucideIcons.clock, 'Total Time', '${booking.hours ?? 0} hours'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Production Status',
            style: GoogleFonts.tinos(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildStatusTimeline(booking.status),
          const SizedBox(height: 32),
          _infoCard(
            title: 'About the Project',
            child: Text(
              booking.description ?? 'No project description available.',
              style: TextStyle(color: Colors.white.withOpacity(0.5), height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallSheetTab(BookingModel booking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoCard(
            title: 'Call Times',
            child: Column(
              children: [
                _detailRow(LucideIcons.clock, 'Call Time', '08:00 AM'),
                _detailRow(LucideIcons.camera, 'Shoot Starts', '09:00 AM'),
                _detailRow(LucideIcons.coffee, 'Lunch Break', '01:00 PM'),
                _detailRow(LucideIcons.logOut, 'Wrap', '05:00 PM'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _infoCard(
            title: 'Key Contacts',
            child: Column(
              children: [
                _detailRow(LucideIcons.user, 'Production Manager', 'Sarah Jennings'),
                _detailRow(LucideIcons.phone, 'Emergency Contact', '+1 (305) 555-0123'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsTab(BookingModel booking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoCard(
            title: 'Wardrobe & Style',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bulletItem('Nude seamless undergarments'),
                _bulletItem('Simple black heels (no brands)'),
                _bulletItem('No heavy perfumes or makeup'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _infoCard(
            title: 'Special Instructions',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bulletItem('Arrive with clean, dry hair'),
                _bulletItem('Bring valid identification for building access'),
                _bulletItem('No phone use during shoot hours'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTab(BookingModel booking) {
    final rate = booking.rate ?? 0.0;
    final platformFee = rate * 0.1;
    final total = rate + platformFee;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoCard(
            title: 'Payment Summary',
            child: Column(
              children: [
                _paymentRow('Model Payment', '\$${rate.toStringAsFixed(2)}'),
                _paymentRow('Platform Fee (10%)', '\$${platformFee.toStringAsFixed(2)}'),
                const Divider(color: Colors.white10, height: 32),
                _paymentRow('Total Amount', '\$${total.toStringAsFixed(2)}', isTotal: true),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shieldCheck, color: Colors.green, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Escrow Protection Active',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Payments are protected until jobs are completed.',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BookingModel booking) {
    if (widget.userType == 'brand') {
      if (booking.status == 'signed' || booking.status == 'confirmed') {
        return _bottomBar(
          ElevatedButton.icon(
            onPressed: () => _startScanning(booking.id),
            icon: const Icon(LucideIcons.camera, size: 20),
            label: const Text('Scan Model QR to Check-in', style: TextStyle(fontWeight: FontWeight.bold)),
            style: _btnStyle(const Color(0xFF6366F1), Colors.white),
          ),
        );
      } else if (booking.status == 'in_progress' || booking.status == 'awaiting_confirmation') {
        return _bottomBar(
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Show photo proof modal
                    _showPhotoProof(booking);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  child: const Text('View Photo Proof', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateStatus('completed'),
                  style: _btnStyle(Colors.white, Colors.black),
                  child: const Text('Release Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      // Model actions
      if (booking.status == 'signed' || booking.status == 'confirmed') {
        return _bottomBar(
          ElevatedButton.icon(
            onPressed: () => _showPersonalQR(booking),
            icon: const Icon(LucideIcons.qrCode, size: 20),
            label: const Text('Show My QR to Brand', style: TextStyle(fontWeight: FontWeight.bold)),
            style: _btnStyle(const Color(0xFF6366F1), Colors.white),
          ),
        );
      } else if (booking.status == 'in_progress') {
        return _bottomBar(
          ElevatedButton.icon(
            onPressed: () => _completeJobWithPhoto(booking.id),
            icon: const Icon(LucideIcons.camera, size: 20),
            label: const Text('Upload Photo Proof to End', style: TextStyle(fontWeight: FontWeight.bold)),
            style: _btnStyle(Colors.white, Colors.black),
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  // Helper Widgets
  Widget _infoCard({required String title, String? subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.tinos(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
          ],
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withOpacity(0.2)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isTotal ? Colors.white : Colors.white38, fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: Colors.white, fontSize: isTotal ? 20 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Icon(Icons.circle, size: 4, color: Color(0xFF6366F1)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.5))),
        ],
      ),
    );
  }

  Widget _bottomBar(Widget child) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: child,
    );
  }

  ButtonStyle _btnStyle(Color bg, Color fg) {
    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      padding: const EdgeInsets.symmetric(vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    );
  }

  Widget _buildStatusTimeline(String currentStatus) {
    final steps = ['Pending', 'Confirmed', 'Active', 'Validation', 'Paid'];
    int currentIdx;
    switch (currentStatus) {
      case 'pending': currentIdx = 0; break;
      case 'confirmed': 
      case 'signed': currentIdx = 1; break;
      case 'in_progress': currentIdx = 2; break;
      case 'awaiting_confirmation': currentIdx = 3; break;
      case 'completed':
      case 'paid': currentIdx = 4; break;
      default: currentIdx = 0;
    }

    return Row(
      children: List.generate(steps.length, (index) {
        bool isActive = index <= currentIdx;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF6366F1) : Colors.white12,
                      shape: BoxShape.circle,
                      boxShadow: isActive ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 10)] : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(steps[index], style: TextStyle(fontSize: 8, color: isActive ? Colors.white : Colors.white24, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
              if (index < steps.length - 1)
                Expanded(child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(height: 1, color: index < currentIdx ? const Color(0xFF6366F1) : Colors.white12),
                )),
            ],
          ),
        );
      }),
    );
  }

  // Operations
  Future<void> _startScanning(String bookingId) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Scan Model QR', style: GoogleFonts.tinos(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue == bookingId) {
                      Navigator.pop(context, barcode.rawValue);
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (result == bookingId) {
      await _bookingService.updateCheckInOut(bookingId, checkIn: DateTime.now());
      await _updateStatus('in_progress');
    }
  }

  void _showPersonalQR(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161618),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('My Check-in QR', style: GoogleFonts.tinos(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Text('Show this to the brand to start the job', style: TextStyle(color: Colors.white.withOpacity(0.4))),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: QrImageView(data: booking.id, version: QrVersions.auto, size: 200),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Future<void> _completeJobWithPhoto(String bookingId) async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _isLoading = true);
      // Mock upload and status update
      await _bookingService.updateCheckInOut(bookingId, checkOut: DateTime.now(), selfieUrl: 'mock_url');
      await _updateStatus('awaiting_confirmation');
    }
  }

  void _showPhotoProof(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Check-out Photo Proof', style: GoogleFonts.tinos(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Container(
              height: 400,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=1000&auto=format&fit=crop'), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: _btnStyle(Colors.white, Colors.black),
                child: const Center(child: Text('Close Proof')),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildContractsTab(BookingModel booking) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('jobs').doc(booking.jobId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
        
        final jobData = snapshot.data!.data() as Map<String, dynamic>?;
        final documents = jobData?['documents'] != null ? Map<String, String>.from(jobData!['documents']) : <String, String>{};
        final docTypes = ['Model Release', 'Usage Rights', 'NDA', 'Booking Agreement'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoCard(
                title: 'Legal Documents',
                subtitle: 'Job-specific agreements for this project',
                child: Column(
                  children: docTypes.map((type) {
                    final isUploaded = documents.containsKey(type);
                    final isSigned = booking.signedDocuments.containsKey(type);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          Icon(
                            isSigned ? LucideIcons.checkCircle2 : (isUploaded ? LucideIcons.fileText : LucideIcons.fileX),
                            color: isSigned ? Colors.green : (isUploaded ? Colors.white70 : Colors.white10),
                            size: 20,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(type, style: TextStyle(color: isUploaded ? Colors.white : Colors.white24, fontWeight: isSigned ? FontWeight.bold : FontWeight.normal)),
                                if (isSigned)
                                  const Text('Signed Digitally', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold))
                                else if (isUploaded)
                                  Text('Pending Signature', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11))
                                else
                                  Text('Not Uploaded by Brand', style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 11)),
                              ],
                            ),
                          ),
                          if (widget.userType == 'model' && isUploaded && !isSigned)
                            TextButton(
                              onPressed: () => _showSignaturePad(booking, type),
                              child: const Text('Sign Now', style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold)),
                            )
                          else if (isUploaded)
                            const Icon(LucideIcons.eye, size: 16, color: Colors.white24),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              if (widget.userType == 'brand')
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.info, color: Color(0xFF818CF8), size: 20),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Upload documents in the Job Management dashboard to make them available for signature.',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showSignaturePad(BookingModel booking, String docType) {
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
            Text('Digital Signature', style: GoogleFonts.tinos(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Signing: $docType', style: TextStyle(color: Colors.white.withOpacity(0.4))),
            const SizedBox(height: 32),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF161618),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Center(
                child: Text(
                  'Signature Pad Placeholder',
                  style: TextStyle(color: Colors.white.withOpacity(0.1)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'By signing, you agree to the terms and conditions outlined in the document and the platform service agreement.',
              style: TextStyle(color: Colors.white24, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Simulate digital signature saving
                  final signatureInfo = 'Forensic Hash: ${DateTime.now().millisecondsSinceEpoch}';
                  await FirebaseFirestore.instance.collection('bookings').doc(booking.id).update({
                    'signedDocuments.$docType': signatureInfo,
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$docType signed successfully!')));
                },
                style: _btnStyle(const Color(0xFF6366F1), Colors.white),
                child: const Text('Confirm & Sign', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
