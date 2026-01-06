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
import 'package:firebase_storage/firebase_storage.dart';

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
                booking: booking,
                onStatusUpdate: _updateStatus,
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
          if (booking.jobId == 'direct_offer') ...[
            _buildOfferDetails(booking),
            const SizedBox(height: 24),
          ],
          if (booking.status == 'completed' || booking.status == 'paid')
            _buildJobSummaryFlashcard(booking)
          else
            _buildInfoCard(
              title: booking.jobTitle ?? 'Job Application',
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

  Widget _buildOfferDetails(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Offer Details',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(LucideIcons.calendar, 'Date', 
              booking.date != null ? DateFormat('MMM d, yyyy').format(booking.date!) : 'Not set'),
          _buildDetailRow(LucideIcons.mapPin, 'Location', booking.location ?? 'Not set'),
          _buildDetailRow(LucideIcons.clock, 'Hours', '${booking.hours ?? 0} hours'),
          _buildDetailRow(LucideIcons.dollarSign, 'Pay', '\$${booking.rate ?? 0}'),
          const Divider(height: 24, color: Colors.white10),
          Text(
            'Description',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            booking.description ?? 'No description provided.',
            style: GoogleFonts.inter(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 8),
          Text('$label: ', style: GoogleFonts.inter(color: Colors.white54)),
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
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

    if (widget.userType == 'model' && booking.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateStatus('declined'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Decline'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus('confirmed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Accept'),
            ),
          ),
        ],
      );
    }

    if (widget.userType == 'brand' && booking.status == 'pending') {
      return Center(
        child: Text(
          'Waiting for model to accept...',
          style: GoogleFonts.inter(color: Colors.white54, fontStyle: FontStyle.italic),
        ),
      );
    }

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
      } else if (booking.status == 'confirmed' && booking.brandSignature == null) {
        return _buildStatusMessage('Waiting for you to sign the contract');
      } else if (booking.status == 'confirmed' && booking.modelSignature == null) {
        return _buildStatusMessage('Waiting for model to sign the contract');
      } else if (booking.status == 'signed') {
        return Column(
          children: [
            _buildStatusMessage('Show this QR code to the model to check-in'),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: booking.id,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
            ),
          ],
        );
      } else if (booking.status == 'in_progress') {
        return _buildStatusMessage('Job is currently in progress');
      } else if (booking.status == 'awaiting_confirmation') {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _disputeJob(booking.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Dispute'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _confirmJob(booking.id),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Confirm Completion'),
              ),
            ),
          ],
        );
      }
    } else {
      // Model actions
      if (booking.status == 'pending') {
        return _buildStatusMessage('Waiting for you to accept the offer');
      } else if (booking.status == 'confirmed' && booking.brandSignature == null) {
        return _buildStatusMessage('Waiting for brand to sign the contract');
      } else if (booking.status == 'confirmed' && booking.modelSignature == null) {
        return _buildStatusMessage('Waiting for you to sign the contract');
      } else if (booking.status == 'signed') {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _startScanning(booking.id),
            child: const Text('Start Job (Scan QR)'),
          ),
        );
      } else if (booking.status == 'in_progress') {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _completeJob(booking.id),
            child: const Text('Complete Job (Take Selfie)'),
          ),
        );
      } else if (booking.status == 'awaiting_confirmation') {
        return _buildStatusMessage('Waiting for brand to confirm completion');
      }
    }

    return const SizedBox.shrink();
  }

  Future<void> _startScanning(String bookingId) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue == bookingId) {
                Navigator.pop(context, barcode.rawValue);
              }
            }
          },
        ),
      ),
    );

    if (result == bookingId) {
      await _bookingService.updateCheckInOut(bookingId, checkIn: DateTime.now());
      await _updateStatus('in_progress');
    } else if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR code for this booking')),
      );
    }
  }

  Future<void> _completeJob(String bookingId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('completion_selfies')
            .child('$bookingId.jpg');
        
        final uploadTask = await storageRef.putData(await image.readAsBytes());
        final downloadUrl = await uploadTask.ref.getDownloadURL();

        await _bookingService.updateCheckInOut(bookingId, 
            checkOut: DateTime.now(), 
            selfieUrl: downloadUrl);
        await _updateStatus('awaiting_confirmation');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading selfie: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmJob(String bookingId) async {
    setState(() => _isLoading = true);
    try {
      await _bookingService.confirmCompletion(bookingId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job completion confirmed!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming job: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disputeJob(String bookingId) async {
    setState(() => _isLoading = true);
    try {
      await _bookingService.disputeJob(bookingId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dispute raised. Support will contact you.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error raising dispute: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStatusMessage(String message, {bool isSuccess = false}) {
    return Center(
      child: Text(
        message,
        style: GoogleFonts.inter(
          color: isSuccess ? Colors.green : Colors.white54,
          fontStyle: FontStyle.italic,
          fontWeight: isSuccess ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
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
    bool isConfirmed = ['confirmed', 'signed', 'in_progress', 'awaiting_confirmation', 'completed', 'paid'].contains(currentStatus);
    bool isSigned = ['signed', 'in_progress', 'awaiting_confirmation', 'completed', 'paid'].contains(currentStatus);
    bool isInProgress = ['in_progress', 'awaiting_confirmation', 'completed', 'paid'].contains(currentStatus);
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

class _BookingContract extends StatefulWidget {
  final String userType;
  final BookingModel booking;
  final Function(String) onStatusUpdate;

  const _BookingContract({
    required this.userType,
    required this.booking,
    required this.onStatusUpdate,
  });

  @override
  State<_BookingContract> createState() => _BookingContractState();
}

class _BookingContractState extends State<_BookingContract> {
  final BookingService _bookingService = BookingService();
  bool _isSigning = false;

  Future<void> _sign() async {
    setState(() => _isSigning = true);
    try {
      final signature = 'Digital Signature: ${widget.userType.toUpperCase()}';
      await _bookingService.signContract(widget.booking.id, widget.userType, signature);
      
      // If both have signed, update status to 'signed'
      if (widget.userType == 'brand' && widget.booking.modelSignature != null) {
        await widget.onStatusUpdate('signed');
      } else if (widget.userType == 'model' && widget.booking.brandSignature != null) {
        await widget.onStatusUpdate('signed');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contract signed successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error signing contract: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBrandSigned = widget.booking.brandSignature != null;
    final hasModelSigned = widget.booking.modelSignature != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service Agreement',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),
                _buildContractSection('Job Title', widget.booking.jobTitle ?? 'Model Booking'),
                _buildContractSection('Date', 
                    widget.booking.date != null ? DateFormat('MMMM d, yyyy').format(widget.booking.date!) : 'Not set'),
                _buildContractSection('Location', widget.booking.location ?? 'Not set'),
                _buildContractSection('Rate', '\$${widget.booking.rate ?? 0} total'),
                const Divider(height: 32, color: Colors.white10),
                _buildContractSection('Cancellation Terms', 
                    widget.booking.cancellationTerms ?? 'Standard terms apply.'),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _buildSignatureBox(
                        'Brand Owner',
                        hasBrandSigned,
                        widget.booking.brandSignedAt,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSignatureBox(
                        'Model',
                        hasModelSigned,
                        widget.booking.modelSignedAt,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (widget.userType == 'brand' && !hasBrandSigned && widget.booking.status == 'confirmed')
            _buildSignButton()
          else if (widget.userType == 'model' && !hasModelSigned && hasBrandSigned)
            _buildSignButton()
          else if (!hasBrandSigned)
            _buildStatusMessage('Awaiting Brand Signature')
          else if (!hasModelSigned)
            _buildStatusMessage('Awaiting Model Signature')
          else
            _buildStatusMessage('Contract Fully Signed', isSuccess: true),
        ],
      ),
    );
  }

  Widget _buildContractSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white54,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureBox(String role, bool isSigned, DateTime? signedAt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSigned ? Colors.green.withOpacity(0.5) : Colors.white10),
          ),
          child: Center(
            child: isSigned
                ? const Icon(LucideIcons.check, color: Colors.green)
                : const Icon(LucideIcons.penTool, color: Colors.white10),
          ),
        ),
        if (isSigned && signedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              DateFormat('MMM d, HH:mm').format(signedAt),
              style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
            ),
          ),
      ],
    );
  }

  Widget _buildSignButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSigning ? null : _sign,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSigning
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Sign Contract Digitally'),
      ),
    );
  }

  Widget _buildStatusMessage(String message, {bool isSuccess = false}) {
    return Center(
      child: Text(
        message,
        style: GoogleFonts.inter(
          color: isSuccess ? Colors.green : Colors.white54,
          fontStyle: FontStyle.italic,
          fontWeight: isSuccess ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
