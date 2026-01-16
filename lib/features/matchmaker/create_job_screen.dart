import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/services/job_service.dart';
import 'package:flutter_application_1/core/models/job_model.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  int _currentStep = 0;
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
      lastDate: DateTime(2030),
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

  Future<void> _handlePublish() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw 'User not logged in';

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final brandName = userDoc.data()?['companyName'] ?? userDoc.data()?['name'] ?? 'Brand Owner';

      final job = JobModel(
        id: '', 
        brandId: user.uid,
        brandName: brandName, 
        title: _titleController.text.trim(),
        description: _expectationsController.text.trim(),
        location: _locationController.text.trim(),
        date: _selectedDate!,
        rate: double.tryParse(_paymentController.text) ?? 0.0,
        requirements: _requirementsController.text.split('\n'),
        createdAt: DateTime.now(),
        images: _imageUploaded ? ['https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=1000&auto=format&fit=crop'] : [],
      );

      await _jobService.createJob(job);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentStep = 2; // Move to Invite step
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildProgressIndicator(),
        centerTitle: true,
      ),
      body: _buildStepContent(),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _progressDot(0),
        _progressLine(),
        _progressDot(1),
        _progressLine(),
        _progressDot(2),
      ],
    );
  }

  Widget _progressDot(int step) {
    bool isCompleted = _currentStep > step;
    bool isActive = _currentStep == step;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green : (isActive ? const Color(0xFF6366F1) : Colors.white12),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _progressLine() {
    return Container(
      width: 30,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white12,
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _buildCreateStep();
      case 1: return _buildPublishStep();
      case 2: return _buildInviteStep();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildCreateStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create New Project',
            style: GoogleFonts.tinos(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Fill in the essential details for your project.',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15),
          ),
          const SizedBox(height: 48),
          _textField('Project Title', _titleController, icon: LucideIcons.briefcase),
          const SizedBox(height: 24),
          _textField('Location', _locationController, icon: LucideIcons.mapPin),
          const SizedBox(height: 24),
          _textField('Daily Rate (\$)', _paymentController, icon: LucideIcons.dollarSign, keyboardType: TextInputType.number),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161618),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.calendar, size: 20, color: Colors.white38),
                  const SizedBox(width: 16),
                  Text(
                    _selectedDate == null ? 'Select Date' : DateFormat('MMMM d, yyyy').format(_selectedDate!),
                    style: TextStyle(color: _selectedDate == null ? Colors.white38 : Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _textField('Expectations', _expectationsController, maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildPublishStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Publish',
            style: GoogleFonts.tinos(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Review your project details before posting.',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15),
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161618),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                _reviewItem('Project', _titleController.text),
                _reviewItem('Location', _locationController.text),
                _reviewItem('Date', _selectedDate != null ? DateFormat('MMMM d, yyyy').format(_selectedDate!) : '-'),
                _reviewItem('Rate', '\$${_paymentController.text}/day'),
                const Divider(color: Colors.white10, height: 32),
                _reviewItem('Expectations', _expectationsController.text, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.info, color: Color(0xFF818CF8), size: 18),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Once published, your project will be visible to all eligible models.',
                    style: TextStyle(color: const Color(0xFF818CF8).withOpacity(0.8), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteStep() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.check, color: Colors.green, size: 64),
          ),
          const SizedBox(height: 32),
          Text(
            'Project Published!',
            style: GoogleFonts.tinos(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Your project is live. Now, find the perfect talent and send invitations.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Return to dashboard and go to models tab
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Browse Talent to Invite', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Go to My Jobs',
              style: TextStyle(color: Colors.white.withOpacity(0.4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewItem(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller, {IconData? icon, TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF161618),
            prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.white38) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1)),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    if (_currentStep == 2) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Row(
        children: [
          if (_currentStep == 1)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                onPressed: () => setState(() => _currentStep = 0),
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white12,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : () {
                if (_currentStep == 0) {
                  if (_titleController.text.isEmpty || _selectedDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill required fields')));
                    return;
                  }
                  setState(() => _currentStep = 1);
                } else {
                  _handlePublish();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text(_currentStep == 0 ? 'Review Project' : 'Publish Project', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
