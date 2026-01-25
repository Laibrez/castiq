import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/admin/models/brand_application.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminBrandDetailScreen extends StatefulWidget {
  final String applicationId;

  const AdminBrandDetailScreen({super.key, required this.applicationId});

  @override
  State<AdminBrandDetailScreen> createState() => _AdminBrandDetailScreenState();
}

class _AdminBrandDetailScreenState extends State<AdminBrandDetailScreen> {
  BrandApplication? _application;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isMockData = false;
  final TextEditingController _reviewNotesController = TextEditingController();
  final TextEditingController _infoRequestController = TextEditingController();

  // Mock data for testing
  final Map<String, BrandApplication> _mockBrandDetails = {
    "mock-brand-1": BrandApplication(
      id: "mock-brand-1",
      userId: "mock-user-1",
      businessName: "Aqua Swim Co",
      legalEntityType: "LLC",
      registrationCountry: "United States",
      registrationNumber: "LLC-2023-12345",
      streetAddress: "1234 Ocean Drive",
      city: "Miami",
      state: "FL",
      postalCode: "33139",
      country: "United States",
      taxId: "XX-XXXXXXX",
      vatNumber: null,
      website: "https://aquaswimco.com",
      linkedin: "https://linkedin.com/company/aquaswimco",
      instagram: "@aquaswimco",
      representativeName: "Sarah Johnson",
      representativeTitle: "CEO & Founder",
      representativePhone: "+1 (305) 555-0123",
      representativeEmail: "sarah@aquaswimco.com",
      status: "pending",
      submittedAt: DateTime.now(),
      reviewedAt: null,
      reviewNotes: null,
      additionalInfoRequested: false,
      additionalInfoMessage: null,
    ),
    "mock-brand-2": BrandApplication(
      id: "mock-brand-2",
      userId: "mock-user-2",
      businessName: "Urban Threads",
      legalEntityType: "Corporation",
      registrationCountry: "United States",
      registrationNumber: "CORP-2022-67890",
      streetAddress: "567 Fashion Ave",
      city: "New York",
      state: "NY",
      postalCode: "10018",
      country: "United States",
      taxId: "XX-XXXXXXX",
      vatNumber: null,
      website: "https://urbanthreads.co",
      linkedin: null,
      instagram: "@urbanthreads",
      representativeName: "Michael Chen",
      representativeTitle: "Marketing Director",
      representativePhone: "+1 (212) 555-0456",
      representativeEmail: "michael@urbanthreads.com",
      status: "pending",
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
      reviewedAt: null,
      reviewNotes: "Requested additional proof of business registration.",
      additionalInfoRequested: true,
      additionalInfoMessage: "Please provide a copy of your business registration certificate and a recent utility bill as proof of address.",
    ),
    "mock-brand-3": BrandApplication(
      id: "mock-brand-3",
      userId: "mock-user-3",
      businessName: "Luxe Beauty",
      legalEntityType: "LLC",
      registrationCountry: "United States",
      registrationNumber: "LLC-2021-11111",
      streetAddress: "890 Sunset Blvd",
      city: "Los Angeles",
      state: "CA",
      postalCode: "90028",
      country: "United States",
      taxId: "XX-XXXXXXX",
      vatNumber: null,
      website: "https://luxebeauty.com",
      linkedin: "https://linkedin.com/company/luxebeauty",
      instagram: "@luxebeauty",
      representativeName: "Emma Williams",
      representativeTitle: "Brand Manager",
      representativePhone: "+1 (323) 555-0789",
      representativeEmail: "emma@luxebeauty.com",
      status: "approved",
      submittedAt: DateTime.now().subtract(const Duration(days: 2)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 1)),
      reviewNotes: "All documents verified. Approved.",
      additionalInfoRequested: false,
      additionalInfoMessage: null,
    ),
    "mock-brand-4": BrandApplication(
      id: "mock-brand-4",
      userId: "mock-user-4",
      businessName: "Fast Fashion Ltd",
      legalEntityType: "Ltd",
      registrationCountry: "United Kingdom",
      registrationNumber: "UK-2020-99999",
      streetAddress: "10 Oxford Street",
      city: "London",
      state: null,
      postalCode: "W1D 1BS",
      country: "United Kingdom",
      taxId: null,
      vatNumber: "GB123456789",
      website: "https://fastfashion.com",
      linkedin: null,
      instagram: "@fastfashionltd",
      representativeName: "John Doe",
      representativeTitle: "Director",
      representativePhone: "+44 20 7946 0958",
      representativeEmail: "john@fastfashion.com",
      status: "rejected",
      submittedAt: DateTime.now().subtract(const Duration(days: 3)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 2)),
      reviewNotes: "Unable to verify business registration. Multiple inconsistencies in provided documents.",
      additionalInfoRequested: false,
      additionalInfoMessage: null,
    ),
  };

  @override
  void initState() {
    super.initState();
    _fetchApplication();
  }

  @override
  void dispose() {
    _reviewNotesController.dispose();
    _infoRequestController.dispose();
    super.dispose();
  }

  Future<void> _fetchApplication() async {
    if (widget.applicationId.startsWith("mock-")) {
      final mockApp = _mockBrandDetails[widget.applicationId];
      if (mockApp != null) {
        setState(() {
          _application = mockApp;
          _reviewNotesController.text = mockApp.reviewNotes ?? "";
          _infoRequestController.text = mockApp.additionalInfoMessage ?? "";
          _isMockData = true;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('brand_applications')
          .doc(widget.applicationId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _application = BrandApplication.fromFirestore(data, doc.id);
          _reviewNotesController.text = _application!.reviewNotes ?? "";
          _infoRequestController.text = _application!.additionalInfoMessage ?? "";
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading application: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateApplicationStatus(String status) async {
    if (_application == null) return;

    setState(() => _isSubmitting = true);

    if (_isMockData) {
      setState(() {
        _application = BrandApplication(
          id: _application!.id,
          userId: _application!.userId,
          businessName: _application!.businessName,
          legalEntityType: _application!.legalEntityType,
          registrationCountry: _application!.registrationCountry,
          registrationNumber: _application!.registrationNumber,
          streetAddress: _application!.streetAddress,
          city: _application!.city,
          state: _application!.state,
          postalCode: _application!.postalCode,
          country: _application!.country,
          taxId: _application!.taxId,
          vatNumber: _application!.vatNumber,
          website: _application!.website,
          linkedin: _application!.linkedin,
          instagram: _application!.instagram,
          representativeName: _application!.representativeName,
          representativeTitle: _application!.representativeTitle,
          representativePhone: _application!.representativePhone,
          representativeEmail: _application!.representativeEmail,
          status: status,
          submittedAt: _application!.submittedAt,
          reviewedAt: DateTime.now(),
          reviewNotes: _reviewNotesController.text,
          additionalInfoRequested: false,
          additionalInfoMessage: null,
        );
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application ${status == "approved" ? "approved" : "rejected"} (Demo - changes are temporary)'),
          ),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('brand_applications')
          .doc(widget.applicationId)
          .update({
        'status': status,
        'reviewed_at': Timestamp.fromDate(DateTime.now()),
        'review_notes': _reviewNotesController.text,
        'additional_info_requested': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application ${status == "approved" ? "approved" : "rejected"} successfully'),
          ),
        );
      }

      _fetchApplication();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _requestMoreInfo() async {
    if (_application == null || _infoRequestController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    if (_isMockData) {
      setState(() {
        _application = BrandApplication(
          id: _application!.id,
          userId: _application!.userId,
          businessName: _application!.businessName,
          legalEntityType: _application!.legalEntityType,
          registrationCountry: _application!.registrationCountry,
          registrationNumber: _application!.registrationNumber,
          streetAddress: _application!.streetAddress,
          city: _application!.city,
          state: _application!.state,
          postalCode: _application!.postalCode,
          country: _application!.country,
          taxId: _application!.taxId,
          vatNumber: _application!.vatNumber,
          website: _application!.website,
          linkedin: _application!.linkedin,
          instagram: _application!.instagram,
          representativeName: _application!.representativeName,
          representativeTitle: _application!.representativeTitle,
          representativePhone: _application!.representativePhone,
          representativeEmail: _application!.representativeEmail,
          status: _application!.status,
          submittedAt: _application!.submittedAt,
          reviewedAt: _application!.reviewedAt,
          reviewNotes: _reviewNotesController.text,
          additionalInfoRequested: true,
          additionalInfoMessage: _infoRequestController.text,
        );
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Additional information requested (Demo - changes are temporary)')),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('brand_applications')
          .doc(widget.applicationId)
          .update({
        'additional_info_requested': true,
        'additional_info_message': _infoRequestController.text,
        'review_notes': _reviewNotesController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Additional information requested successfully')),
        );
      }

      _fetchApplication();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error requesting info: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteApplication() async {
    if (_application == null) return;

    if (_isMockData) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application deleted (Demo)')),
        );
        Navigator.pop(context);
      }
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await FirebaseFirestore.instance
          .collection('brand_applications')
          .doc(widget.applicationId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application deleted successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting application: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showDeleteDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Delete Application',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this application? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteApplication();
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  Widget _buildStatusBadge() {
    if (_application == null) return const SizedBox.shrink();

    final infoRequested = _application!.additionalInfoRequested ?? false;
    Color color;
    String label;

    if (infoRequested) {
      color = Colors.amber;
      label = 'Info Requested';
    } else {
      switch (_application!.status) {
        case 'pending':
          color = Colors.grey;
          label = 'Pending Review';
          break;
        case 'approved':
          color = Colors.green;
          label = 'Approved';
          break;
        case 'rejected':
          color = Colors.red;
          label = 'Rejected';
          break;
        default:
          color = Colors.grey;
          label = _application!.status;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: infoRequested
            ? Colors.amber.withOpacity(0.2)
            : color == Colors.green
                ? Colors.green.withOpacity(0.2)
                : color == Colors.red
                    ? Colors.red.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_application == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Application not found',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Applications'),
              ),
            ],
          ),
        ),
      );
    }

    final app = _application!;
    final dateFormat = DateFormat('MMMM d, yyyy \'at\' h:mm a');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSubmitting ? null : _showDeleteDialog,
            icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 18),
            label: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              app.businessName,
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildStatusBadge(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Submitted on ${dateFormat.format(app.submittedAt)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Main Content Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column - Main Content
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Business Information
                      _buildInfoCard(
                        icon: LucideIcons.building2,
                        title: 'Business Information',
                        content: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoRow(
                                    'Business Name',
                                    app.businessName,
                                  ),
                                ),
                                Expanded(
                                  child: _buildInfoRow(
                                    'Legal Entity Type',
                                    app.legalEntityType ?? 'N/A',
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoRow(
                                    'Registration Country',
                                    app.registrationCountry ?? 'N/A',
                                  ),
                                ),
                                Expanded(
                                  child: _buildInfoRow(
                                    'Registration Number',
                                    app.registrationNumber ?? 'N/A',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Business Address
                      _buildInfoCard(
                        icon: LucideIcons.mapPin,
                        title: 'Business Address',
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.streetAddress ?? 'No address provided',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            if (app.city != null || app.state != null || app.postalCode != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                [
                                  app.city,
                                  app.state,
                                  app.postalCode,
                                ].where((e) => e != null).join(', '),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                            if (app.country != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                app.country!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tax Information
                      _buildInfoCard(
                        icon: LucideIcons.fileText,
                        title: 'Tax Information',
                        content: Row(
                          children: [
                            Expanded(
                              child: _buildInfoRow(
                                'Tax ID',
                                app.taxId ?? 'N/A',
                              ),
                            ),
                            Expanded(
                              child: _buildInfoRow(
                                'VAT Number',
                                app.vatNumber ?? 'N/A',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Online Presence
                      _buildInfoCard(
                        icon: LucideIcons.globe,
                        title: 'Online Presence',
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (app.website != null && app.website!.isNotEmpty)
                              InkWell(
                                onTap: () => _launchUrl(app.website!),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.externalLink,
                                        size: 16,
                                        color: Color(0xFF6366F1),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          app.website!,
                                          style: const TextStyle(
                                            color: Color(0xFF6366F1),
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (app.linkedin != null && app.linkedin!.isNotEmpty)
                              InkWell(
                                onTap: () => _launchUrl(app.linkedin!),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.externalLink,
                                        size: 16,
                                        color: Color(0xFF6366F1),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'LinkedIn',
                                        style: TextStyle(
                                          color: Color(0xFF6366F1),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (app.instagram != null && app.instagram!.isNotEmpty)
                              InkWell(
                                onTap: () {
                                  final instagramHandle = app.instagram!.replaceAll('@', '');
                                  _launchUrl('https://instagram.com/$instagramHandle');
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.externalLink,
                                        size: 16,
                                        color: Color(0xFF6366F1),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '@${app.instagram!.replaceAll('@', '')}',
                                        style: const TextStyle(
                                          color: Color(0xFF6366F1),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if ((app.website == null || app.website!.isEmpty) &&
                                (app.linkedin == null || app.linkedin!.isEmpty) &&
                                (app.instagram == null || app.instagram!.isEmpty))
                              Text(
                                'No online presence provided',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Representative Contact
                      _buildInfoCard(
                        icon: LucideIcons.user,
                        title: 'Representative Contact',
                        content: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoRow(
                                    'Name',
                                    app.representativeName ?? 'N/A',
                                  ),
                                ),
                                Expanded(
                                  child: _buildInfoRow(
                                    'Title',
                                    app.representativeTitle ?? 'N/A',
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoRow(
                                    'Email',
                                    app.representativeEmail ?? 'N/A',
                                  ),
                                ),
                                Expanded(
                                  child: _buildInfoRow(
                                    'Phone',
                                    app.representativePhone ?? 'N/A',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // Right Column - Review Actions
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // Review Notes
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Review Notes',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Internal notes about this application',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _reviewNotesController,
                              maxLines: 4,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Add notes about this application...',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                filled: true,
                                fillColor: Colors.black,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Request More Info (only for pending)
                      if (app.status == 'pending')
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    LucideIcons.messageSquare,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Request More Info',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _infoRequestController,
                                maxLines: 3,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'What additional information do you need?',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                  filled: true,
                                  fillColor: Colors.black,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF6366F1)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _isSubmitting || _infoRequestController.text.trim().isEmpty
                                      ? null
                                      : _requestMoreInfo,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text('Send Request'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (app.status == 'pending') const SizedBox(height: 16),

                      // Decision Actions (only for pending)
                      if (app.status == 'pending')
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Decision',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Approve or reject this application',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isSubmitting ? null : () => _updateApplicationStatus('approved'),
                                  icon: const Icon(LucideIcons.checkCircle, size: 18),
                                  label: const Text('Approve Application'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isSubmitting ? null : () => _updateApplicationStatus('rejected'),
                                  icon: const Icon(LucideIcons.xCircle, size: 18),
                                  label: const Text('Reject Application'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Review History
                      if (app.reviewedAt != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Review History',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Reviewed on',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(app.reviewedAt!),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
