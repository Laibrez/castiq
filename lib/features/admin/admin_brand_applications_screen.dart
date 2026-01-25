import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/features/admin/models/brand_application.dart';
import 'package:flutter_application_1/features/admin/admin_brand_detail_screen.dart';

class AdminBrandApplicationsScreen extends StatefulWidget {
  const AdminBrandApplicationsScreen({super.key});

  @override
  State<AdminBrandApplicationsScreen> createState() => _AdminBrandApplicationsScreenState();
}

class _AdminBrandApplicationsScreenState extends State<AdminBrandApplicationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';
  List<BrandApplication> _applications = [];
  List<BrandApplication> _filteredApplications = [];
  bool _isLoading = true;

  // Mock data for testing
  final List<BrandApplication> _mockApplications = [
    BrandApplication(
      id: 'mock-brand-1',
      userId: 'mock-user-1',
      businessName: 'Aqua Swim Co',
      status: 'pending',
      submittedAt: DateTime.now(),
      representativeName: 'Sarah Johnson',
      representativeEmail: 'sarah@aquaswimco.com',
      website: 'https://aquaswimco.com',
      additionalInfoRequested: false,
    ),
    BrandApplication(
      id: 'mock-brand-2',
      userId: 'mock-user-2',
      businessName: 'Urban Threads',
      status: 'pending',
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
      representativeName: 'Michael Chen',
      representativeEmail: 'michael@urbanthreads.com',
      website: 'https://urbanthreads.co',
      additionalInfoRequested: true,
    ),
    BrandApplication(
      id: 'mock-brand-3',
      userId: 'mock-user-3',
      businessName: 'Luxe Beauty',
      status: 'approved',
      submittedAt: DateTime.now().subtract(const Duration(days: 2)),
      representativeName: 'Emma Williams',
      representativeEmail: 'emma@luxebeauty.com',
      website: 'https://luxebeauty.com',
      additionalInfoRequested: false,
    ),
    BrandApplication(
      id: 'mock-brand-4',
      userId: 'mock-user-4',
      businessName: 'Fast Fashion Ltd',
      status: 'rejected',
      submittedAt: DateTime.now().subtract(const Duration(days: 3)),
      representativeName: 'John Doe',
      representativeEmail: 'john@fastfashion.com',
      website: 'https://fastfashion.com',
      additionalInfoRequested: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterApplications);
    _fetchApplications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchApplications() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('brand_applications')
          .orderBy('submitted_at', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        // Use mock data if no real applications exist
        setState(() {
          _applications = _mockApplications;
          _filteredApplications = _applications;
        });
      } else {
        setState(() {
          _applications = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return BrandApplication.fromFirestore(data, doc.id);
          }).toList();
          _filteredApplications = _applications;
        });
      }
    } catch (e) {
      // On error, use mock data
      setState(() {
        _applications = _mockApplications;
        _filteredApplications = _applications;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterApplications() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredApplications = _applications.where((app) {
        final matchesSearch = 
            app.businessName.toLowerCase().contains(query) ||
            (app.representativeName != null && app.representativeName!.toLowerCase().contains(query)) ||
            (app.representativeEmail != null && app.representativeEmail!.toLowerCase().contains(query));
        
        final matchesStatus = _statusFilter == 'all' || app.status == _statusFilter;
        
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Map<String, int> get _statusCounts {
    return {
      'all': _applications.length,
      'pending': _applications.where((a) => a.status == 'pending').length,
      'approved': _applications.where((a) => a.status == 'approved').length,
      'rejected': _applications.where((a) => a.status == 'rejected').length,
    };
  }

  Map<String, dynamic> _getStatusConfig(String status, bool? infoRequested) {
    if (infoRequested == true) {
      return {
        'label': 'Info requested',
        'color': Colors.amber,
        'dotColor': Colors.amber,
      };
    }
    switch (status) {
      case 'approved':
        return {
          'label': 'Approved',
          'color': Colors.green,
          'dotColor': Colors.green,
        };
      case 'rejected':
        return {
          'label': 'Rejected',
          'color': Colors.red,
          'dotColor': Colors.red,
        };
      default:
        return {
          'label': 'Pending',
          'color': Colors.grey,
          'dotColor': Colors.amber,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Brands',
          style: GoogleFonts.tinos(
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Review and manage brand applications',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              
              // Search and Filters
              Row(
                children: [
                  // Search
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by business name...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        prefixIcon: const Icon(LucideIcons.search, size: 20, color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF1A1A1A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Status Filter Buttons
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterButton('all', 'All'),
                    _buildFilterButton('pending', 'Pending'),
                    _buildFilterButton('approved', 'Approved'),
                    _buildFilterButton('rejected', 'Rejected'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Application List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_filteredApplications.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'No applications found',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ),
                )
              else
                ..._filteredApplications.map((app) {
                  final statusConfig = _getStatusConfig(app.status, app.additionalInfoRequested);
                  return _buildApplicationCard(app, statusConfig);
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String value, String label) {
    final isSelected = _statusFilter == value;
    final count = _statusCounts[value] ?? 0;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _statusFilter = value;
            _filterApplications();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1A1A1A) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(BrandApplication app, Map<String, dynamic> statusConfig) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminBrandDetailScreen(applicationId: app.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    app.businessName.isNotEmpty ? app.businessName[0].toUpperCase() : 'B',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Business Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.businessName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${app.representativeName ?? "No representative"} • ${app.representativeEmail ?? "No email"}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Website Link (if available)
              if (app.website != null && app.website!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      // Note: For web, you can use html.window.open or similar
                      // For now, just show the URL
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Website: ${app.website}')),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.externalLink,
                          size: 14,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Website',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Status Badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusConfig['dotColor'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusConfig['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusConfig['color'] as Color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: Colors.white54,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
