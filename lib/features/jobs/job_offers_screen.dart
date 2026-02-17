import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/features/jobs/job_detail_screen.dart';
import 'package:flutter_application_1/core/widgets/application_confirmation_modal.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/core/services/job_service.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/models/job_model.dart';
import 'package:intl/intl.dart';

class JobOffersScreen extends StatefulWidget {
  const JobOffersScreen({super.key});

  @override
  State<JobOffersScreen> createState() => _JobOffersScreenState();
}

class _JobOffersScreenState extends State<JobOffersScreen> {
  final JobService _jobService = JobService();
  bool _isLoading = true;
  List<JobModel> _jobs = [];
  String _searchQuery = ''; // Note: Firestore search is limited, this will be client-side filtered for now or just name match if we add simple search.

  // Filters
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Runway', 'Editorial', 'Swimsuit', 'Commercial', 'Fitness', 'Luxury Campaign'];
  
  RangeValues _payRange = const RangeValues(0, 10000);
  DateTime? _startDate;
  DateTime? _endDate;
  double _maxExperience = 10; // Years
  double _myHeight = 175; // cm
  bool _filterByHeight = false;
  String _contractType = 'All'; // 'One-day', 'Multi-day', 'Long-term'
  bool _isUrgent = false;
  bool _isInstantPayout = false;
  final String _locationQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);
    try {
      final jobs = await _jobService.getJobs(
        category: _selectedCategory,
        minPay: _payRange.start > 0 ? _payRange.start : null,
        maxPay: _payRange.end < 10000 ? _payRange.end : null,
        startDate: _startDate,
        endDate: _endDate,
        maxExperienceRequired: _maxExperience.toInt(), 
        modelHeight: _filterByHeight ? _myHeight.toInt() : null,
        isUrgent: _isUrgent ? true : null,
        isInstantPayoutAvailable: _isInstantPayout ? true : null,
        contractType: _contractType != 'All' ? _contractType : null,
      );
      
      setState(() {
        _jobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching jobs: $e");
      setState(() => _isLoading = false);
    }
  }

  void _openFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filters', style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                Expanded(
                  child: ListView(
                    children: [
                      // Category
                      Text('Category', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (val) {
                              setModalState(() => _selectedCategory = cat);
                              setState(() => _selectedCategory = cat);
                            },
                            selectedColor: AppTheme.gold,
                            backgroundColor: AppTheme.white,
                            labelStyle: GoogleFonts.montserrat(color: isSelected ? AppTheme.black : AppTheme.grey),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Pay Range
                      Text('Pay Range (\$${_payRange.start.toInt()} - \$${_payRange.end.toInt()})', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                      RangeSlider(
                        values: _payRange,
                        min: 0,
                        max: 10000,
                        divisions: 100,
                        activeColor: AppTheme.gold,
                        inactiveColor: AppTheme.grey.withOpacity(0.3),
                        labels: RangeLabels('\$${_payRange.start.toInt()}', '\$${_payRange.end.toInt()}'),
                        onChanged: (val) {
                          setModalState(() => _payRange = val);
                          setState(() => _payRange = val);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Date Range
                      Text('Shoot Dates', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(LucideIcons.calendar),
                              label: Text(_startDate != null ? DateFormat('MMM dd').format(_startDate!) : 'Start Date'),
                              onPressed: () async {
                                final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                                if (d != null) {
                                  setModalState(() => _startDate = d);
                                  setState(() => _startDate = d);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(LucideIcons.calendar),
                              label: Text(_endDate != null ? DateFormat('MMM dd').format(_endDate!) : 'End Date'),
                              onPressed: () async {
                                final d = await showDatePicker(context: context, initialDate: _startDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                                if (d != null) {
                                  setModalState(() => _endDate = d);
                                  setState(() => _endDate = d);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Experience
                      Text('Max Experience Required: ${_maxExperience.toInt()} Years', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                      Slider(
                        value: _maxExperience,
                        min: 0,
                        max: 20,
                        divisions: 20,
                        activeColor: AppTheme.gold,
                        onChanged: (val) {
                          setModalState(() => _maxExperience = val);
                          setState(() => _maxExperience = val);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Height Match
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Filter by My Height (${_myHeight.toInt()} cm)', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                          Switch(
                            value: _filterByHeight,
                            activeThumbColor: AppTheme.gold,
                            onChanged: (val) {
                              setModalState(() => _filterByHeight = val);
                              setState(() => _filterByHeight = val);
                            },
                          ),
                        ],
                      ),
                      if (_filterByHeight)
                        Slider(
                          value: _myHeight,
                          min: 150,
                          max: 200,
                          divisions: 50,
                          activeColor: AppTheme.gold,
                          onChanged: (val) {
                            setModalState(() => _myHeight = val);
                            setState(() => _myHeight = val);
                          },
                        ),
                      const SizedBox(height: 24),

                      // Contract Type
                      Text('Contract Type', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'One-day', 'Multi-day', 'Long-term'].map((type) {
                          final isSelected = _contractType == type;
                          return ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (val) {
                              setModalState(() => _contractType = type);
                              setState(() => _contractType = type);
                            },
                            selectedColor: AppTheme.gold,
                            backgroundColor: AppTheme.white,
                            labelStyle: GoogleFonts.montserrat(color: isSelected ? AppTheme.black : AppTheme.grey),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Toggles
                      SwitchListTile(
                        title: Text('Urgent Jobs Only', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                        value: _isUrgent,
                        activeThumbColor: AppTheme.gold,
                        onChanged: (val) {
                          setModalState(() => _isUrgent = val);
                          setState(() => _isUrgent = val);
                        },
                      ),
                      SwitchListTile(
                        title: Text('Instant Payout Only', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                        value: _isInstantPayout,
                        activeThumbColor: AppTheme.gold,
                        onChanged: (val) {
                          setModalState(() => _isInstantPayout = val);
                          setState(() => _isInstantPayout = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _fetchJobs();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: AppTheme.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Search & Filter
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search brands or jobs',
                            prefixIcon: const Icon(LucideIcons.search, size: 20, color: AppTheme.grey),
                            filled: true,
                            fillColor: AppTheme.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8E4DE))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8E4DE))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _openFilterModal,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE8E4DE)),
                          ),
                          child: const Icon(LucideIcons.sliders, color: AppTheme.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Quick Filter Chips (Category)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedCategory = category);
                              _fetchJobs();
                            },
                            backgroundColor: AppTheme.white,
                            selectedColor: AppTheme.gold,
                            labelStyle: GoogleFonts.montserrat(
                              color: isSelected ? AppTheme.black : AppTheme.grey,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE8E4DE)),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Job Listings
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                : _buildJobListings(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobListings() {
    // Client-side search filtering (since Firestore search is limited)
    final filteredJobs = _jobs.where((job) {
      final matchesSearch = job.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.brandName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    if (filteredJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.frown, size: 64, color: AppTheme.black.withOpacity(0.15)),
            const SizedBox(height: 16),
            Text('No job offers found', style: GoogleFonts.montserrat(fontSize: 18, color: AppTheme.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: filteredJobs.length,
      itemBuilder: (context, index) {
        final job = filteredJobs[index];
        return _buildJobFlashcard(job);
      },
    );
  }

  Widget _buildJobFlashcard(JobModel job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E4DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image & Brand Logo
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: job.images.isNotEmpty 
                  ? Image.network(
                      job.images.first,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(height: 200, color: Colors.grey[200]),
                    )
                  : Container(
                      height: 200, 
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Icon(LucideIcons.image, size: 50, color: Colors.grey),
                    ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '\$${job.payRate.toInt()}',
                    style: GoogleFonts.montserrat(
                      color: AppTheme.lightGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (job.isUrgent)
                 Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'URGENT',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      job.category,
                      style: GoogleFonts.montserrat(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      job.location,
                      style: GoogleFonts.montserrat(
                        color: AppTheme.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 14, color: AppTheme.grey),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM dd, yyyy').format(job.shootDate),
                      style: GoogleFonts.montserrat(
                        color: AppTheme.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  job.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: AppTheme.grey,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JobDetailScreen(job: job), 
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFFE8E4DE)),
                        ),
                        child: Text(
                          'View Details',
                          style: GoogleFonts.montserrat(
                            color: AppTheme.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleApply(job),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.gold,
                          foregroundColor: AppTheme.black,
                        ),
                        child: const Text('Apply Now'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  // ... (rest of initState or other methods)

  void _handleApply(JobModel job) async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to apply')));
      return;
    }

    try {
      await _jobService.applyToJob(job.id, user.uid, job.brandId);
      if (!mounted) return;
      _showApplyConfirmation(job);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to apply: $e')));
    }
  }

  void _showApplyConfirmation(JobModel job) {
    ApplicationConfirmationModal.show(context, jobName: job.title);
  }
}
