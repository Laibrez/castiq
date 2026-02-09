import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/features/jobs/job_detail_screen.dart';
import 'package:flutter_application_1/core/widgets/application_confirmation_modal.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';

class JobOffersScreen extends StatefulWidget {
  const JobOffersScreen({super.key});

  @override
  State<JobOffersScreen> createState() => _JobOffersScreenState();
}

class _JobOffersScreenState extends State<JobOffersScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Runway', 'Commercial', 'Editorial'];

  final List<Map<String, dynamic>> _jobOffers = [
    {
      'id': '1',
      'brandName': 'Vogue Miami',
      'brandLogo':
          'https://ui-avatars.com/api/?name=Vogue&background=1A1A1A&color=D4AF37',
      'coverImage':
          'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?q=80&w=800&auto=format&fit=crop',
      'jobName': 'Miami Swim Week 2024',
      'category': 'Runway',
      'location': 'Miami, Florida',
      'date': 'March 15–18, 2024',
      'description':
          'Main stage runway for our 2024 swim collection. Seeking models with strong walks.',
      'payment': '\$2,500',
    },
    {
      'id': '2',
      'brandName': 'Zara',
      'brandLogo':
          'https://ui-avatars.com/api/?name=Zara&background=1A1A1A&color=D4AF37',
      'coverImage':
          'https://images.unsplash.com/photo-1445205170230-053b83016050?q=80&w=800&auto=format&fit=crop',
      'jobName': 'Spring Editorial Shoot',
      'category': 'Editorial',
      'location': 'New York, NY',
      'date': 'April 20, 2024',
      'description':
          'Studio shoot for spring-summer collection. Casual and high-fashion looks.',
      'payment': '\$1,800',
    },
  ];

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
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search brands or jobs',
                            prefixIcon: Icon(LucideIcons.search,
                                size: 20, color: AppTheme.grey),
                            filled: true,
                            fillColor: AppTheme.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE8E4DE)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE8E4DE)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: const Color(0xFFE8E4DE)),
                        ),
                        child: const Icon(LucideIcons.sliders,
                            color: AppTheme.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips
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
                            },
                            backgroundColor: AppTheme.white,
                            selectedColor: AppTheme.gold,
                            labelStyle: GoogleFonts.montserrat(
                              color: isSelected
                                  ? AppTheme.black
                                  : AppTheme.grey,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : const Color(0xFFE8E4DE),
                              ),
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
              child: _buildJobListings(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobListings() {
    final filteredJobs = _jobOffers.where((job) {
      final matchesSearch = job['jobName']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          job['brandName']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || job['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    if (filteredJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.frown,
                size: 64, color: AppTheme.black.withOpacity(0.15)),
            const SizedBox(height: 16),
            Text(
              'No job offers found',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                color: AppTheme.grey,
              ),
            ),
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

  Widget _buildJobFlashcard(Map<String, dynamic> job) {
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(
                  job['coverImage'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.white, width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CircleAvatar(
                    backgroundColor: AppTheme.black,
                    radius: 20,
                    backgroundImage: NetworkImage(job['brandLogo']),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    job['payment'],
                    style: GoogleFonts.montserrat(
                      color: AppTheme.lightGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
                  job['jobName'],
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
                      job['category'],
                      style: GoogleFonts.montserrat(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      job['location'],
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
                    Icon(LucideIcons.calendar,
                        size: 14, color: AppTheme.grey),
                    const SizedBox(width: 8),
                    Text(
                      job['date'],
                      style: GoogleFonts.montserrat(
                        color: AppTheme.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  job['description'],
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
                              builder: (context) =>
                                  JobDetailScreen(job: job),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                              color: Color(0xFFE8E4DE)),
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
                        onPressed: () =>
                            _showApplyConfirmation(job['jobName']),
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
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

  void _showApplyConfirmation(String jobName) {
    ApplicationConfirmationModal.show(context, jobName: jobName);
  }
}
