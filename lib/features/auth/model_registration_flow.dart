import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_application_1/features/auth/registration_success_screen.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';

class ModelRegistrationFlow extends StatefulWidget {
  const ModelRegistrationFlow({super.key});

  @override
  State<ModelRegistrationFlow> createState() => _ModelRegistrationFlowState();
}

class _ModelRegistrationFlowState extends State<ModelRegistrationFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 8; // Updated to 8 to include Identity Verification step

  // Controllers and state for registration data
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final List<String> _selectedInterests = [];
  
  // Identity Verification state
  String? _idDocumentUrl;
  String? _selfieUrl;
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  
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
          _Step2IdentityVerification(
            nextStep: _nextStep,
            onIdUploaded: (url) => setState(() => _idDocumentUrl = url),
            onSelfieUploaded: (url) => setState(() => _selfieUrl = url),
            idDocumentUrl: _idDocumentUrl,
            selfieUrl: _selfieUrl,
            userId: _authService.currentUser?.uid,
            picker: _picker,
          ),
          _Step3Interests(nextStep: _nextStep),
          _Step4ProfilePhoto(nextStep: _nextStep),
          _Step5Portfolio(nextStep: _nextStep),
          _Step6Measurements(nextStep: _nextStep),
          _Step7Location(nextStep: _nextStep),
          _Step8ZCard(nextStep: _nextStep),
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

// Step 2: Identity Verification (Model users only)
class _Step2IdentityVerification extends StatefulWidget {
  final VoidCallback nextStep;
  final Function(String?) onIdUploaded;
  final Function(String?) onSelfieUploaded;
  final String? idDocumentUrl;
  final String? selfieUrl;
  final String? userId;
  final ImagePicker picker;

  const _Step2IdentityVerification({
    required this.nextStep,
    required this.onIdUploaded,
    required this.onSelfieUploaded,
    required this.idDocumentUrl,
    required this.selfieUrl,
    required this.userId,
    required this.picker,
  });

  @override
  State<_Step2IdentityVerification> createState() => _Step2IdentityVerificationState();
}

class _Step2IdentityVerificationState extends State<_Step2IdentityVerification> {
  bool _isUploadingId = false;
  bool _isUploadingSelfie = false;

  Future<void> _uploadId(ImageSource source) async {
    try {
      final XFile? image = await widget.picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingId = true);

      final String fileName = path.basename(image.path);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String userId = widget.userId ?? 'temp_user_id';
      final String storagePath = 'model_verification/$userId/id_$timestamp$fileName';

      final Reference ref = FirebaseStorage.instance.ref().child(storagePath);
      final UploadTask uploadTask = ref.putFile(File(image.path));
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      widget.onIdUploaded(downloadUrl);
      setState(() => _isUploadingId = false);
    } catch (e) {
      setState(() => _isUploadingId = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading ID: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _takeSelfie() async {
    try {
      final XFile? image = await widget.picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingSelfie = true);

      final String fileName = path.basename(image.path);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String userId = widget.userId ?? 'temp_user_id';
      final String storagePath = 'model_verification/$userId/selfie_$timestamp$fileName';

      final Reference ref = FirebaseStorage.instance.ref().child(storagePath);
      final UploadTask uploadTask = ref.putFile(File(image.path));
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      widget.onSelfieUploaded(downloadUrl);
      setState(() => _isUploadingSelfie = false);
    } catch (e) {
      setState(() => _isUploadingSelfie = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading selfie: ${e.toString()}')),
        );
      }
    }
  }

  void _showIdSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _uploadId(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text('Take a Photo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _uploadId(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canProceed = widget.idDocumentUrl != null && widget.selfieUrl != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Step 2', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 8),
          const Text(
            'Verify Your Identity',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            'Upload your ID and a selfie to verify you are who you say you are',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 32),
          // Two side-by-side upload sections
          Row(
            children: [
              Expanded(
                child: _IdentityUploadSection(
                  title: 'Government ID',
                  icon: Icons.credit_card,
                  buttonText: 'Upload ID',
                  description: 'Passport, Driver\'s License, or National ID',
                  isUploaded: widget.idDocumentUrl != null,
                  isUploading: _isUploadingId,
                  onTap: _showIdSourceDialog,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _IdentityUploadSection(
                  title: 'Selfie with ID',
                  icon: Icons.camera_alt,
                  buttonText: 'Take Selfie',
                  description: 'Hold your ID next to your face',
                  isUploaded: widget.selfieUrl != null,
                  isUploading: _isUploadingSelfie,
                  onTap: _takeSelfie,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Informational box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why do we need this?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Identity verification helps keep our community safe and ensures brands can trust the models they work with.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canProceed ? widget.nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                disabledBackgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityUploadSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String buttonText;
  final String description;
  final bool isUploaded;
  final bool isUploading;
  final VoidCallback onTap;

  const _IdentityUploadSection({
    required this.title,
    required this.icon,
    required this.buttonText,
    required this.description,
    required this.isUploaded,
    required this.isUploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isUploaded ? Colors.green : Colors.white24,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: isUploading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      icon,
                      size: 40,
                      color: Colors.white70,
                    ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isUploaded ? Colors.green : Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isUploaded ? 'Uploaded' : buttonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step3Interests extends StatefulWidget {
  final VoidCallback nextStep;
  const _Step3Interests({required this.nextStep});

  @override
  State<_Step3Interests> createState() => _Step3InterestsState();
}

class _Step3InterestsState extends State<_Step3Interests> {
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

class _Step4ProfilePhoto extends StatelessWidget {
  final VoidCallback nextStep;
  const _Step4ProfilePhoto({required this.nextStep});

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

class _Step5Portfolio extends StatelessWidget {
  final VoidCallback nextStep;
  const _Step5Portfolio({required this.nextStep});

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

class _Step6Measurements extends StatelessWidget {
  final VoidCallback nextStep;
  const _Step6Measurements({required this.nextStep});

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

class _Step7Location extends StatelessWidget {
  final VoidCallback nextStep;
  const _Step7Location({required this.nextStep});

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

class _Step8ZCard extends StatelessWidget {
  final VoidCallback nextStep;
  const _Step8ZCard({required this.nextStep});

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
