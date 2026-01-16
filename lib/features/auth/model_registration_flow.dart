import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/auth/registration_success_screen.dart';

class ModelRegistrationFlow extends StatefulWidget {
  const ModelRegistrationFlow({super.key});

  @override
  State<ModelRegistrationFlow> createState() => _ModelRegistrationFlowState();
}

class _ModelRegistrationFlowState extends State<ModelRegistrationFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 7;

  // Controllers and state for registration data
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final List<String> _selectedInterests = [];
  // Add other state variables as needed

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
          _Step1Account(nextStep: _nextStep),
          _Step2Interests(nextStep: _nextStep),
          _Step3ProfilePhoto(nextStep: _nextStep),
          _Step4Portfolio(nextStep: _nextStep),
          _Step5Measurements(nextStep: _nextStep),
          _Step6Location(nextStep: _nextStep),
          _Step7ZCard(nextStep: _nextStep),
        ],
      ),
    );
  }
}

// Step Widgets (Placeholders for now, will implement details next)

class _Step1Account extends StatelessWidget {
  final VoidCallback nextStep;
  const _Step1Account({required this.nextStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Step 1', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 8),
          const Text(
            'Create Account',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 32),
          _buildTextField('Email', Icons.email_outlined),
          const SizedBox(height: 16),
          _buildTextField('Password', Icons.lock_outline, obscureText: true),
          const SizedBox(height: 16),
          _buildTextField('Confirm Password', Icons.lock_outline, obscureText: true),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: nextStep,
              child: const Text('Next'),
            ),
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
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class _Step2Interests extends StatefulWidget {
  final VoidCallback nextStep;
  const _Step2Interests({required this.nextStep});

  @override
  State<_Step2Interests> createState() => _Step2InterestsState();
}

class _Step2InterestsState extends State<_Step2Interests> {
  final List<String> categories = ['Fashion', 'Commercial', 'Beauty', 'Editorial', 'Runway', 'Lifestyle', 'Fitness', 'Parts'];
  final Set<String> selected = {};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What are your interests?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: categories.map((cat) {
              final isSelected = selected.contains(cat);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selected.remove(cat);
                    } else {
                      selected.add(cat);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: isSelected ? const Color(0xFF6366F1) : Colors.white10),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: widget.nextStep, child: const Text('Next')),
          ),
        ],
      ),
    );
  }
}

class _Step3ProfilePhoto extends StatelessWidget {
  final VoidCallback nextStep;
  const _Step3ProfilePhoto({required this.nextStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upload your profile picture', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('1 required photo', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 48),
          Center(
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white10, style: BorderStyle.solid),
              ),
              child: const Icon(LucideIcons.camera, size: 48, color: Colors.white24),
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
}

class _Step4Portfolio extends StatelessWidget {
  final VoidCallback nextStep;
  const _Step4Portfolio({required this.nextStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Build your portfolio', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('Upload 4 photos (required) and 1 video (optional)', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: List.generate(5, (index) {
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Icon(index == 4 ? LucideIcons.video : LucideIcons.image, color: Colors.white24),
                );
              }),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: nextStep, child: const Text('Next')),
          ),
        ],
      ),
    );
  }
}

class _Step5Measurements extends StatelessWidget {
  final VoidCallback nextStep;
  const _Step5Measurements({required this.nextStep});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your measurements', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 32),
          _buildMeasureField('Height (cm)'),
          const SizedBox(height: 16),
          _buildMeasureField('Chest / Bust (cm)'),
          const SizedBox(height: 16),
          _buildMeasureField('Waist (cm)'),
          const SizedBox(height: 16),
          _buildMeasureField('Hips (cm)'),
          const SizedBox(height: 16),
          _buildMeasureField('Shoe size'),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: nextStep, child: const Text('Next')),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasureField(String label) {
    return TextField(
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class _Step6Location extends StatelessWidget {
  final VoidCallback nextStep;
  const _Step6Location({required this.nextStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Where are you based?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 32),
          _buildLocationField('Base city / country', LucideIcons.mapPin),
          const SizedBox(height: 32),
          const Text('Willing to travel?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildChoiceChip('Yes', true),
              const SizedBox(width: 12),
              _buildChoiceChip('No', false),
            ],
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

  Widget _buildLocationField(String label, IconData icon) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}

class _Step7ZCard extends StatelessWidget {
  final VoidCallback nextStep;
  const _Step7ZCard({required this.nextStep});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(LucideIcons.checkCircle2, size: 80, color: Color(0xFF10B981)),
            const SizedBox(height: 24),
            const Text('Z-Card Created', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            const Text(
              'Your professional Z-Card has been created automatically using your photos and measurements.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 48),
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: const Center(child: Text('Z-CARD PREVIEW', style: TextStyle(color: Colors.white24, letterSpacing: 4))),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistrationSuccessScreen(
                        message: 'Finish Application',
                      ),
                    ),
                  );
                },
                child: const Text('Finish Application'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
