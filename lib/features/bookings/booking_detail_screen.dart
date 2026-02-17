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
import 'package:flutter_application_1/core/theme/app_theme.dart';

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
    _tabController = TabController(length: 5, vsync: this);
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
          return const Scaffold(backgroundColor: AppTheme.cream, body: Center(child: CircularProgressIndicator(color: AppTheme.gold)));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(backgroundColor: AppTheme.cream, body: Center(child: Text('Booking not found', style: TextStyle(color: AppTheme.black))));
        }

        final booking = BookingModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);

        return Scaffold(
          backgroundColor: AppTheme.cream,
          appBar: AppBar(
            backgroundColor: AppTheme.cream,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Booking Detail',
              style: GoogleFonts.cormorantGaramond(
                fontWeight: FontWeight.w400,
                fontSize: 24,
                color: AppTheme.black,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.share, color: AppTheme.black),
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
              indicatorColor: AppTheme.gold,
              labelColor: AppTheme.black,
              unselectedLabelColor: AppTheme.grey,
              indicatorWeight: 3,
              labelPadding: const EdgeInsets.symmetric(horizontal: 20),
              labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Overview'),
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
              _buildRequirementsTab(booking),
              _buildPaymentTab(booking),
              _buildContractsTab(booking),
              _buildChatTab(booking),
            ],
          ),
          bottomNavigationBar: _buildBottomActions(booking),
        );
      },
    );
  }

  Widget _buildChatTab(BookingModel booking) {
    if (booking.status == 'pending' || booking.status == 'offer_sent') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.lock, size: 48, color: AppTheme.grey),
            const SizedBox(height: 16),
            Text(
              'Chat is locked',
              style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Chat will be enabled once the offer is accepted.',
              style: GoogleFonts.montserrat(color: AppTheme.grey),
            ),
          ],
        ),
      );
    }

    final currentUserId = AuthService().currentUser?.uid;
    if (currentUserId == null) return const SizedBox.shrink();

    final otherUserId = widget.userType == 'brand' ? booking.modelId : booking.brandId;

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchChatAndUser(booking, otherUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data;
        final chatDoc = data?['chat'] as DocumentSnapshot?;
        final userDoc = data?['user'] as DocumentSnapshot?;
        
        final otherUserName = userDoc?.get('name') ?? 'User';
        final otherUserImage = userDoc?.data().toString().contains('profileImageUrl') == true ? userDoc?.get('profileImageUrl') : null;

        if (chatDoc != null && chatDoc.exists) {
          return ChatDetailScreen(
            chatId: chatDoc.id,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            otherUserImage: otherUserImage,
          );
        } else {
          // Chat doesn't exist, show "Start Chat" button
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.messageSquare, size: 64, color: AppTheme.gold.withOpacity(0.5)),
                const SizedBox(height: 24),
                Text(
                  'Start a Conversation',
                  style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Discuss details with ${otherUserName}',
                  style: GoogleFonts.montserrat(color: AppTheme.grey),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => _createChat(booking, otherUserId, otherUserName, otherUserImage),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.black,
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Start Chat'),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Future<Map<String, dynamic>> _fetchChatAndUser(BookingModel booking, String otherUserId) async {
    // 1. Fetch Other User
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();

    // 2. Fetch Chat (Query by participants and jobId)
    final chatQuery = await FirebaseFirestore.instance
        .collection('chats')
        .where('jobId', isEqualTo: booking.jobId)
        .where('participants', arrayContains: booking.modelId) // We know modelId is one participant
        .get();

    // Filter locally for the exact match if needed, or rely on compound query if we had one
    // But simple query: participants arrayContains modelId. Then check if brandId matches.
    DocumentSnapshot? chatDoc;
    for (var doc in chatQuery.docs) {
      final data = doc.data();
      if (data['brandId'] == booking.brandId && data['modelId'] == booking.modelId) {
        chatDoc = doc;
        break;
      }
    }

    return {
      'user': userDoc,
      'chat': chatDoc,
    };
  }

  Future<void> _createChat(BookingModel booking, String otherUserId, String otherUserName, String? otherUserImage) async {
    setState(() => _isLoading = true);
    try {
      // Need self details
      final currentUser = AuthService().currentUser;
      final selfDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
      final selfName = selfDoc.data()?['name'] ?? 'User';
      final selfImage = selfDoc.data().toString().contains('profileImageUrl') == true ? selfDoc.get('profileImageUrl') : null;

      // Determine who is who
      final isBrand = widget.userType == 'brand';
      final modelId = isBrand ? otherUserId : currentUser.uid;
      final modelName = isBrand ? otherUserName : selfName;
      final modelImage = isBrand ? otherUserImage : selfImage;
      
      final brandId = isBrand ? currentUser.uid : otherUserId;
      final brandName = isBrand ? selfName : otherUserName;
      final brandImage = isBrand ? selfImage : otherUserImage;

      // Call ChatService to create (it handles checks)
      // But ChatService.createChat in dart isn't updated to match backend fully or vice versa? 
      // The current ChatService.dart createChat uses direct Firestore.
      final chatService = kIsWeb ? BookingService() : BookingService(); // Just using Firestore direct here for simplicity or import ChatService

      // Actually, let's use the startChat logic
       final chatRef = await FirebaseFirestore.instance.collection('chats').add({
        'modelId': modelId,
        'modelName': modelName,
        'modelImage': modelImage,
        'brandId': brandId,
        'brandName': brandName,
        'brandImage': brandImage,
        'jobId': booking.jobId,
        'jobTitle': booking.jobTitle,
        'participants': [modelId, brandId],
        'lastMessage': 'Chat started',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.uid,
        'unreadCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'chatEnabled': true,
      });
      
      setState(() {}); // specific chat created, rebuild to show it
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating chat: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
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
            style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.w400, color: AppTheme.black),
          ),
          const SizedBox(height: 16),
          _buildStatusTimeline(booking.status),
          const SizedBox(height: 32),
          _infoCard(
            title: 'About the Project',
            child: Text(
              booking.description ?? 'No project description available.',
              style: GoogleFonts.montserrat(color: AppTheme.black.withOpacity(0.8), height: 1.6, fontSize: 14),
            ),
          ),
          const SizedBox(height: 32),
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
                const Divider(color: Color(0xFFE0DCD5), height: 32),
                _paymentRow('Total Amount', '\$${total.toStringAsFixed(2)}', isTotal: true),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0DCD5)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shieldCheck, color: Colors.green, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Escrow Protection Active',
                        style: GoogleFonts.montserrat(color: AppTheme.black, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Payments are protected until jobs are completed.',
                        style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 12),
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
      if (booking.status == 'fully_signed' || booking.status == 'offer_accepted' || booking.status == 'confirmed') {
        return _bottomBar(
          ElevatedButton.icon(
            onPressed: () => _startScanning(booking.id),
            icon: const Icon(LucideIcons.camera, size: 20),
            label: const Text('Scan Model QR to Check-in', style: TextStyle(fontWeight: FontWeight.bold)),
            style: _btnStyle(AppTheme.black, AppTheme.white),
          ),
        );
      } else if (booking.status == 'job_in_progress' || booking.status == 'in_progress' || booking.status == 'awaiting_confirmation') {
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
                    side: const BorderSide(color: Color(0xFFE0DCD5)),
                  ),
                  child: Text('View Photo Proof', style: GoogleFonts.montserrat(color: AppTheme.black, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateStatus('completed'),
                  style: _btnStyle(AppTheme.black, AppTheme.white),
                  child: const Text('Release Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      // Model actions
      if (booking.status == 'offer_sent' || booking.status == 'pending') {
         return _bottomBar(
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () { 
                    // Reject logic 
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateStatus('offer_accepted'),
                  style: _btnStyle(Colors.green, Colors.white),
                  child: const Text('Accept Offer', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      } else if (booking.status == 'fully_signed' || booking.status == 'offer_accepted' || booking.status == 'confirmed') {
        return _bottomBar(
          ElevatedButton.icon(
            onPressed: () => _showPersonalQR(booking),
            icon: const Icon(LucideIcons.qrCode, size: 20),
            label: const Text('Show My QR to Brand', style: TextStyle(fontWeight: FontWeight.bold)),
            style: _btnStyle(AppTheme.black, AppTheme.white),
          ),
        );
      } else if (booking.status == 'job_in_progress' || booking.status == 'in_progress') {
        return _bottomBar(
          ElevatedButton.icon(
            onPressed: () => _completeJobWithPhoto(booking.id),
            icon: const Icon(LucideIcons.camera, size: 20),
            label: const Text('Upload Photo Proof to End', style: TextStyle(fontWeight: FontWeight.bold)),
            style: _btnStyle(AppTheme.black, AppTheme.white),
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
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 12)),
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

  Widget _paymentRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.montserrat(color: isTotal ? AppTheme.black : AppTheme.grey, fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.w500)),
          Text(value, style: GoogleFonts.montserrat(color: AppTheme.black, fontSize: isTotal ? 20 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.w600)),
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
            child: Icon(Icons.circle, size: 4, color: AppTheme.gold),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.montserrat(color: AppTheme.black.withOpacity(0.8), fontSize: 14, height: 1.5))),
        ],
      ),
    );
  }

  Widget _bottomBar(Widget child) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border(top: BorderSide(color: const Color(0xFFE0DCD5))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
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
      case 'offer_sent':
      case 'pending': currentIdx = 0; break;
      case 'offer_accepted':
      case 'fully_signed':
      case 'confirmed': 
      case 'signed': currentIdx = 1; break;
      case 'job_in_progress':
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
                      color: isActive ? AppTheme.gold : AppTheme.cream,
                      shape: BoxShape.circle,
                      border: Border.all(color: isActive ? AppTheme.gold : AppTheme.grey.withOpacity(0.3)),
                      boxShadow: isActive ? [BoxShadow(color: AppTheme.gold.withOpacity(0.3), blurRadius: 10)] : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(steps[index], style: GoogleFonts.montserrat(fontSize: 8, color: isActive ? AppTheme.black : AppTheme.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
              if (index < steps.length - 1)
                Expanded(child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(height: 1, color: index < currentIdx ? AppTheme.gold : AppTheme.cream),
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
      backgroundColor: AppTheme.white,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Scan Model QR', style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.w400, color: AppTheme.black)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, color: AppTheme.black)),
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
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('My Check-in QR', style: GoogleFonts.cormorantGaramond(fontSize: 28, fontWeight: FontWeight.w400, color: AppTheme.black)),
            const SizedBox(height: 12),
            Text('Show this to the brand to start the job', style: GoogleFonts.montserrat(color: AppTheme.grey)),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE0DCD5))),
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
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Check-out Photo Proof', style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.w400, color: AppTheme.black)),
            ),
            Container(
              height: 400,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=1000&auto=format&fit=crop'), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: _btnStyle(AppTheme.black, AppTheme.white),
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
        
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
                            color: isSigned ? Colors.green : (isUploaded ? AppTheme.black : AppTheme.grey),
                            size: 20,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(type, style: GoogleFonts.montserrat(color: isUploaded ? AppTheme.black : AppTheme.grey, fontWeight: isSigned ? FontWeight.bold : FontWeight.normal)),
                                if (isSigned)
                                  const Text('Signed Digitally', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold))
                                else if (isUploaded)
                                  Text('Pending Signature', style: TextStyle(color: AppTheme.grey, fontSize: 11))
                                else
                                  Text('Not Uploaded by Brand', style: TextStyle(color: AppTheme.grey.withOpacity(0.5), fontSize: 11)),
                              ],
                            ),
                          ),
                          if (widget.userType == 'model' && isUploaded && !isSigned)
                            TextButton(
                              onPressed: () => _showSignaturePad(booking, type),
                              child: const Text('Sign Now', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                            )
                          else if (isUploaded)
                            const Icon(LucideIcons.eye, size: 16, color: AppTheme.grey),
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
                    color: AppTheme.cream,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0DCD5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.info, color: AppTheme.gold, size: 20),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Upload documents in the Job Management dashboard to make them available for signature.',
                          style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 12, height: 1.5),
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
    final TextEditingController _nameController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(32, 32, 32, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Digital Signature', style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.w400, color: AppTheme.black)),
            const SizedBox(height: 8),
            Text('Signing: $docType', style: GoogleFonts.montserrat(color: AppTheme.grey)),
            const SizedBox(height: 32),
            Text(
              'To sign this document, please type your full legal name below. This counts as a legal signature.',
              style: GoogleFonts.montserrat(color: AppTheme.black, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Legal Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppTheme.cream,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'By signing, you agree to the terms and conditions outlined in the document and the platform service agreement.',
              style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your full name to sign.')));
                    return;
                  }
                  
                  Navigator.pop(context); // Close modal first
                  setState(() => _isLoading = true);
                  
                  try {
                    final signature = 'Signed by ${_nameController.text.trim()} on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}';
                    
                    // Update Booking
                    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(booking.id);
                    await bookingRef.update({
                      'signedDocuments.$docType': signature,
                      widget.userType == 'brand' ? 'brandSignedAt' : 'modelSignedAt': FieldValue.serverTimestamp(),
                    });
                    
                    // Check if all needed docs are signed by both? 
                    // Simplified: If this was the last pending signature for this user, check if other user also signed everything?
                    // For now, let's just check if both brandSignedAt and modelSignedAt are present in the updated doc.
                    
                    final updatedDoc = await bookingRef.get();
                    final data = updatedDoc.data() as Map<String, dynamic>;
                    
                    if (data['brandSignedAt'] != null && data['modelSignedAt'] != null) {
                       await _bookingService.updateBookingStatus(booking.id, 'fully_signed');
                    }
                    
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$docType signed successfully.')));
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error signing: $e')));
                  } finally {
                     if (mounted) setState(() => _isLoading = false);
                  }
                },
                style: _btnStyle(AppTheme.black, AppTheme.white),
                child: const Text('Sign Document', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  }
}



