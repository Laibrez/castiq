import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/auth/registration_success_screen.dart';

class BrandRegistrationFlow extends StatefulWidget {
  const BrandRegistrationFlow({super.key});

  @override
  State<BrandRegistrationFlow> createState() => _BrandRegistrationFlowState();
}

class _BrandRegistrationFlowState extends State<BrandRegistrationFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 6;

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: _previousStep,
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            minHeight: 6,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (int page) {
          setState(() {
            _currentStep = page;
          });
        },
        children: [
          _Step1BusinessAccount(nextStep: _nextStep),
          _Step2BusinessInfo(nextStep: _nextStep),
          _Step3BusinessAddress(nextStep: _nextStep),
          _Step4TaxInfo(nextStep: _nextStep),
          _Step5OnlinePresence(nextStep: _nextStep),
          _Step6AuthorizedRep(nextStep: _nextStep),
        ],
      ),
    );
  }
}

class _Step1BusinessAccount extends StatelessWidget {
  final VoidCallback nextStep;
  const _Step1BusinessAccount({required this.nextStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Step 1', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 8),
          const Text('Create Business Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 32),
          _buildTextField('Business Email', LucideIcons.mail),
          const SizedBox(height: 16),
          _buildTextField('Password', LucideIcons.lock, obscureText: true),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: nextStep, child: const Text('Next')),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, {bool obscureText = false}) {
    return TextField(
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class _Step2BusinessInfo extends StatelessWidget {
  final VoidCallback nextStep;
  const _Step2BusinessInfo({required this.nextStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Business Information', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 32),
          _buildTextField('Business Name', LucideIcons.building),
          const SizedBox(height: 16),
          _buildTextField('Country', LucideIcons.globe),
          const SizedBox(height: 16),
          _buildTextField('Business Registration Number', LucideIcons.fileText),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: nextStep, child: const Text('Next')),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class _Step3BusinessAddress extends StatelessWidget {
  final VoidCallback nextStep;
  const _Step3BusinessAddress({required this.nextStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Business Address', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 32),
          _buildTextField('Address', LucideIcons.mapPin),
          const SizedBox(height: 16),
          _buildTextField('Country', LucideIcons.globe),
          const SizedBox(height: 32),
          const Text('Upload proof of address', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Utility bill or lease agreement', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.upload, color: Colors.white24, size: 32),
                const SizedBox(height: 12),
                const Text('Tap to upload document', style: TextStyle(color: Colors.white24)),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: nextStep, child: const Text('Next')),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class _Step4TaxInfo extends StatelessWidget {
  final VoidCallback nextStep;
  const _Step4TaxInfo({required this.nextStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.shieldCheck, color: Color(0xFF6366F1), size: 28),
              const SizedBox(width: 12),
              const Text('Secure Verification', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Tax Information', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('Your information is encrypted and securely stored.', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 32),
          _buildTextField('Tax ID / Business tax info', LucideIcons.hash),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: nextStep, child: const Text('Next')),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class _Step5OnlinePresence extends StatelessWidget {
  final VoidCallback nextStep;
  const _Step5OnlinePresence({required this.nextStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Online Presence', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('Optional, but helps with verification.', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 32),
          _buildTextField('Website', LucideIcons.globe),
          const SizedBox(height: 16),
          _buildTextField('Social Media Links', LucideIcons.share2),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: nextStep, child: const Text('Next')),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class _Step6AuthorizedRep extends StatelessWidget {
  final VoidCallback nextStep;
  const _Step6AuthorizedRep({required this.nextStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Authorized Representative', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 32),
          _buildTextField('Full Name', LucideIcons.user),
          const SizedBox(height: 16),
          _buildTextField('Role', LucideIcons.briefcase),
          const SizedBox(height: 16),
          _buildTextField('Contact Email', LucideIcons.mail),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegistrationSuccessScreen(
                      message: 'Thanks for applying.\nWe’re verifying your business information and identity.\nYou’ll receive an email once your account is approved and ready to start booking talent.',
                    ),
                  ),
                );
              },
              child: const Text('Submit Application'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
