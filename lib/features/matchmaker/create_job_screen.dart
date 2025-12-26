import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/services/job_service.dart';
import 'package:flutter_application_1/core/models/job_model.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _paymentController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _expectationsController = TextEditingController();
  DateTime? _selectedDate;
  bool _imageUploaded = false;
  bool _isLoading = false;

  final AuthService _authService = AuthService();
  final JobService _jobService = JobService();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Color(0xFF141419),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handlePostJob() async {
    if (_titleController.text.isEmpty || 
        _locationController.text.isEmpty || 
        _paymentController.text.isEmpty || 
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw 'User not logged in';

      // Fetch brand name from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final brandName = userDoc.data()?['companyName'] ?? userDoc.data()?['name'] ?? 'Brand Owner';

      final job = JobModel(
        id: '', // Firestore will generate this
        brandId: user.uid,
        brandName: brandName, 
        title: _titleController.text.trim(),
        description: _expectationsController.text.trim(),
        location: _locationController.text.trim(),
        date: _selectedDate!,
        rate: double.tryParse(_paymentController.text) ?? 0.0,
        requirements: _requirementsController.text.split('\n'),
        createdAt: DateTime.now(),
        images: _imageUploaded ? ['https://source.unsplash.com/random/800x400/?fashion,studio'] : [],
      );

      await _jobService.createJob(job);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job Posted Successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post job: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Post a Job',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Job Details'),
            const SizedBox(height: 16),
            _buildTextField('Job Title', _titleController, icon: LucideIcons.briefcase),
            const SizedBox(height: 16),
            _buildTextField('Job Location', _locationController, icon: LucideIcons.mapPin),
            const SizedBox(height: 16),
            _buildTextField('Payment Amount', _paymentController, icon: LucideIcons.dollarSign, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141419),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 20, color: Colors.white70),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null
                          ? 'Select Date of Job'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: GoogleFonts.inter(
                        color: _selectedDate == null ? Colors.white54 : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Requirements & Expectations'),
            const SizedBox(height: 16),
            _buildTextField('Requirements', _requirementsController, maxLines: 3),
            const SizedBox(height: 16),
            _buildTextField('Expectations', _expectationsController, maxLines: 3),
            const SizedBox(height: 24),
            _buildSectionTitle('Job Pictures'),
            const SizedBox(height: 8),
            Text(
              'Upload reference pictures for the job.',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                setState(() {
                  _imageUploaded = !_imageUploaded;
                });
              },
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF141419),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _imageUploaded ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.1),
                    style: BorderStyle.solid,
                  ),
                ),
                child: _imageUploaded
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          'https://source.unsplash.com/random/800x400/?fashion,studio',
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.imagePlus, size: 32, color: Colors.white54),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to Upload Image',
                            style: GoogleFonts.inter(color: Colors.white54),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handlePostJob,
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Post Job'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}
