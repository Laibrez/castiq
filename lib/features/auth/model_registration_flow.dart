import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter_application_1/features/auth/registration_success_screen.dart';

class ModelRegistrationFlow extends StatefulWidget {
  const ModelRegistrationFlow({super.key});

  @override
  State<ModelRegistrationFlow> createState() => _ModelRegistrationFlowState();
}

class _ModelRegistrationFlowState extends State<ModelRegistrationFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 9;

  // Controllers and state for registration data
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  // Measurements
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _bustController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _hipsController = TextEditingController();
  final TextEditingController _shoeController = TextEditingController();
  // Location
  final TextEditingController _locationController = TextEditingController();
  bool _willingToTravel = true;
  
  final List<String> _selectedInterests = [];
  List<Map<String, String>> _socialMediaLinks = [];
  
  // Image Upload State
  File? _selectedImageFile; // For Mobile
  Uint8List? _selectedImageBytes; // For Web/Mobile view
  
  // New Upload State
  final List<Uint8List> _portfolioImages = [];
  Uint8List? _zCardImage;
  
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageFile = File(image.path); // Keep for mobile file upload if needed, but bytes work for both in putData
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickPortfolioImages() async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        for (var i in images) {
          final bytes = await i.readAsBytes();
          setState(() {
            _portfolioImages.add(bytes);
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking portfolio images: $e');
    }
  }

  Future<void> _pickZCardImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _zCardImage = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking z-card: $e');
    }
  }

  Future<void> _submitRegistration() async {
    if (_selectedImageFile == null && _selectedImageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a profile photo')),
        );
        return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Create Auth User (if needed) or get current
      User? user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
         try {
            final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
            user = userCredential.user;
         } catch (e) {
            // Check if it's already in use or handle error
            throw Exception('Auth Error: $e');
         }
      }
      
      if (user == null) throw Exception('Failed to create or get user');

      // 2. Upload Image to Firebase Storage
      final String path = 'profile_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child(path);
      
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      TaskSnapshot snapshot;
      
      if (kIsWeb) {
         snapshot = await ref.putData(_selectedImageBytes!, metadata);
      } else {
         snapshot = await ref.putFile(File(_selectedImageFile!.path), metadata);
      }
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // 3. Upload Portfolio Images
      List<String> portfolioUrls = [];
      for (int i = 0; i < _portfolioImages.length; i++) {
        final path = 'portfolio/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = FirebaseStorage.instance.ref().child(path);
        await ref.putData(_portfolioImages[i], metadata);
        final url = await ref.getDownloadURL();
        portfolioUrls.add(url);
      }

      // 4. Upload Z-Card
      String? zCardUrl;
      if (_zCardImage != null) {
          final path = 'z_cards/${user.uid}/zcard_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final ref = FirebaseStorage.instance.ref().child(path);
          await ref.putData(_zCardImage!, metadata);
          zCardUrl = await ref.getDownloadURL();
      }

      // 5. Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'role': 'model',
        'profileImageUrl': downloadUrl,
        'portfolio': portfolioUrls,
        'zCardUrl': zCardUrl,
        'interests': _selectedInterests,
        'measurements': {
          'height': _heightController.text,
          'bust': _bustController.text,
          'waist': _waistController.text,
          'hips': _hipsController.text,
          'shoe': _shoeController.text,
        },
        'location': _locationController.text,
        'willingToTravel': _willingToTravel,
        'socialMedia': _socialMediaLinks,
        'approved': false,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        // Add other fields from controllers here
      }, SetOptions(merge: true)); // Merge to avoid overwriting if doc exists

       if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RegistrationSuccessScreen(
                message: 'Thanks for applying.\nWe’re verifying your profile.\nYou’ll receive an email once your account is approved.',
              ),
            ),
          );
       }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }


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
          _Step1Account(
            nextStep: _nextStep,
            emailController: _emailController,
            passwordController: _passwordController,
            confirmPasswordController: _confirmPasswordController,
          ),
          _Step2Interests(
            nextStep: _nextStep,
            selectedInterests: _selectedInterests,
          ),
          _Step3ProfilePhoto(
            nextStep: _nextStep, 
            pickImage: _pickImage,
            imageBytes: _selectedImageBytes,
          ),
          _Step4Portfolio(
             nextStep: _nextStep,
             pickImages: _pickPortfolioImages,
             images: _portfolioImages,
          ),
          _Step5Measurements(
            nextStep: _nextStep,
            heightController: _heightController,
            bustController: _bustController,
            waistController: _waistController,
            hipsController: _hipsController,
            shoeController: _shoeController,
          ),
          _Step6Location(
            nextStep: _nextStep,
            locationController: _locationController,
            onTravelChanged: (val) => setState(() => _willingToTravel = val),
            willingToTravel: _willingToTravel,
          ),
          _StepSocialMedia(
            nextStep: _nextStep, 
            socialLinks: _socialMediaLinks, 
            onLinksChanged: (links) => setState(() => _socialMediaLinks = links),
          ),
          _Step8ZCard(
            nextStep: _nextStep,
            pickImage: _pickZCardImage,
            zCardBytes: _zCardImage,
          ),
          _Step9Summary(
            onSubmit: _submitRegistration,
            isLoading: _isSubmitting,
            email: _emailController.text,
            name: 'Model Applicant', 
            location: _locationController.text,
            interests: _selectedInterests,
            profileImage: _selectedImageBytes,
            zCardImage: _zCardImage,
            socialLinks: _socialMediaLinks,
            stats: {
                'Height': _heightController.text,
                'Bust': _bustController.text,
                'Waist': _waistController.text,
                'Hips': _hipsController.text,
                'Shoe': _shoeController.text,
            }
          ),
        ],
      ),
    );
  }
}

// Step Widgets (Placeholders for now, will implement details next)

class _Step1Account extends StatefulWidget {
  final VoidCallback nextStep;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const _Step1Account({
    required this.nextStep,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  State<_Step1Account> createState() => _Step1AccountState();
}

class _Step1AccountState extends State<_Step1Account> {
  final _formKey = GlobalKey<FormState>();

  void _validateAndContinue() {
    if (_formKey.currentState!.validate()) {
      widget.nextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
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
            _buildTextField(
              'Email', 
              Icons.email_outlined, 
              widget.emailController,
              validator: (v) => v == null || v.isEmpty ? 'Email is required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Password', 
              Icons.lock_outline, 
              widget.passwordController, 
              obscureText: true,
              validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Confirm Password', 
              Icons.lock_outline, 
              widget.confirmPasswordController, 
              obscureText: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirm password';
                if (v != widget.passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _validateAndContinue,
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    IconData icon, 
    TextEditingController controller, 
    {bool obscureText = false, String? Function(String?)? validator}
  ) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
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
  final List<String> selectedInterests;

  const _Step2Interests({
    required this.nextStep,
    required this.selectedInterests,
  });

  @override
  State<_Step2Interests> createState() => _Step2InterestsState();
}

class _Step2InterestsState extends State<_Step2Interests> {
  final List<String> categories = [
    'Fashion', 'Commercial', 'Fitness', 'Runway', 
    'Swimwear', 'Editorial', 'Parts', 'Promotional',
    'Acting', 'Voiceover', 'Influencer'
  ];

  void _validateAndContinue() {
    if (widget.selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one interest')),
      );
      return;
    }
    widget.nextStep();
  }

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
              final isSelected = widget.selectedInterests.contains(cat);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      widget.selectedInterests.remove(cat);
                    } else {
                      widget.selectedInterests.add(cat);
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
            child: ElevatedButton(
              onPressed: _validateAndContinue,
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step3ProfilePhoto extends StatelessWidget {
  final VoidCallback nextStep;
  final VoidCallback pickImage;
  final Uint8List? imageBytes;

  const _Step3ProfilePhoto({
    required this.nextStep,
    required this.pickImage,
    this.imageBytes,
  });


  void _validateAndContinue(BuildContext context) {
    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a profile photo')),
      );
      return;
    }
    nextStep();
  }

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
              child: GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.white10, style: BorderStyle.solid),
                    image: imageBytes != null 
                        ? DecorationImage(
                            image: MemoryImage(imageBytes!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageBytes == null 
                      ? const Icon(LucideIcons.camera, size: 48, color: Colors.white24)
                      : null,
                ),
              ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _validateAndContinue(context), 
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step4Portfolio extends StatelessWidget {
  final VoidCallback nextStep;
  final VoidCallback pickImages;
  final List<Uint8List> images;

  const _Step4Portfolio({
    required this.nextStep,
    required this.pickImages,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Build your Portfolio', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('Upload your best photos (Max 10)', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
               ...images.map((bytes) => Container(
                 width: 100,
                 height: 100,
                 decoration: BoxDecoration(
                   borderRadius: BorderRadius.circular(12),
                   image: DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover),
                 ),
               )),
               GestureDetector(
                onTap: pickImages,
                child: Container(
                  width: 100,
                  height: 100,
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

class _Step5Measurements extends StatefulWidget {
  final VoidCallback nextStep;
  final TextEditingController heightController;
  final TextEditingController bustController;
  final TextEditingController waistController;
  final TextEditingController hipsController;
  final TextEditingController shoeController;

  const _Step5Measurements({
    required this.nextStep,
    required this.heightController,
    required this.bustController,
    required this.waistController,
    required this.hipsController,
    required this.shoeController,
  });

  @override
  State<_Step5Measurements> createState() => _Step5MeasurementsState();
}

class _Step5MeasurementsState extends State<_Step5Measurements> {
  final _formKey = GlobalKey<FormState>();

  void _validateAndContinue() {
    if (_formKey.currentState!.validate()) {
      widget.nextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your measurements', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            _buildMeasureField('Height (cm)', widget.heightController),
            const SizedBox(height: 16),
            _buildMeasureField('Chest / Bust (cm)', widget.bustController),
            const SizedBox(height: 16),
            _buildMeasureField('Waist (cm)', widget.waistController),
            const SizedBox(height: 16),
            _buildMeasureField('Hips (cm)', widget.hipsController),
            const SizedBox(height: 16),
            _buildMeasureField('Shoe size', widget.shoeController),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _validateAndContinue, 
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasureField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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


class _Step6Location extends StatefulWidget {
  final VoidCallback nextStep;
  final TextEditingController locationController;
  final bool willingToTravel;
  final ValueChanged<bool> onTravelChanged;

  const _Step6Location({
    required this.nextStep,
    required this.locationController,
    required this.willingToTravel,
    required this.onTravelChanged,
  });

  @override
  State<_Step6Location> createState() => _Step6LocationState();
}

class _Step6LocationState extends State<_Step6Location> {
  final _formKey = GlobalKey<FormState>();

  void _validateAndContinue() {
    if (_formKey.currentState!.validate()) {
      widget.nextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Where are you based?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            _buildCountryField(),
            const SizedBox(height: 16),
            const Text('Willing to travel?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: () => widget.onTravelChanged(true),
                  child: _buildChoiceChip('Yes', widget.willingToTravel),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => widget.onTravelChanged(false),
                  child: _buildChoiceChip('No', !widget.willingToTravel),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _validateAndContinue, 
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryField() {
    return TextFormField(
      controller: widget.locationController,
      readOnly: true,
      onTap: () {
        showCountryPicker(
          context: context,
          countryListTheme: CountryListThemeData(
            flagSize: 25,
            backgroundColor: const Color(0xFF1A1A1A),
            textStyle: const TextStyle(fontSize: 16, color: Colors.white),
            bottomSheetHeight: 500,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            inputDecoration: InputDecoration(
              labelText: 'Search',
              hintText: 'Start typing to search',
              prefixIcon: const Icon(LucideIcons.search, color: Colors.white54),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              labelStyle: const TextStyle(color: Colors.white54),
              hintStyle: const TextStyle(color: Colors.white54),
            ),
          ),
          onSelect: (Country country) {
            setState(() {
              widget.locationController.text = country.name; // Simplified for now, just country
            });
          },
        );
      },
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Select Country',
        prefixIcon: const Icon(LucideIcons.globe, color: Colors.white54),
        suffixIcon: const Icon(LucideIcons.chevronDown, color: Colors.white54),
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
  final VoidCallback pickImage;
  final Uint8List? zCardBytes;

  const _Step8ZCard({
    required this.nextStep,
    required this.pickImage,
    this.zCardBytes,
  });

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
              child: zCardBytes != null 
                  ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(zCardBytes!, fit: BoxFit.cover))
                  : const Center(child: Text('Z-CARD PREVIEW', style: TextStyle(color: Colors.white24, letterSpacing: 4))),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: nextStep,
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step9Summary extends StatelessWidget {
  final VoidCallback onSubmit;
  final bool isLoading;
  final String? email;
  final String name;
  final String location;
  final List<String> interests;
  final Uint8List? profileImage;
  final Uint8List? zCardImage;
  final Map<String, String> stats;
  final List<Map<String, String>> socialLinks;

  const _Step9Summary({
    required this.onSubmit,
    required this.isLoading,
    this.email,
    required this.name,
    required this.location,
    required this.interests,
    this.profileImage,
    this.zCardImage,
    required this.stats,
    required this.socialLinks,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Review Information', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('Please verify your details before submitting.', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 32),
          
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[800],
              backgroundImage: profileImage != null ? MemoryImage(profileImage!) : null,
              child: profileImage == null ? const Icon(LucideIcons.user, size: 40, color: Colors.white54) : null,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildSummarySection('Account', [
            'Email: $email',
            'Location: $location',
          ]),
          
          _buildSummarySection('Measurements', stats.entries.map((e) => '${e.key}: ${e.value}').toList()),
          
          if (socialLinks.isNotEmpty)
             _buildSummarySection('Social Media', socialLinks.map((e) => '${e['platform']}: ${e['url']}').toList()),
          
          _buildSummarySection('Interests', [interests.join(', ')]),

          if (zCardImage != null) ...[
             const SizedBox(height: 24),
             const Text('Z-Card', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
             const SizedBox(height: 8),
             Container(
               height: 150,
               decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(12),
                 image: DecorationImage(image: MemoryImage(zCardImage!), fit: BoxFit.cover),
               ),
             ),
          ],

          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
                  : const Text('Confirm & Submit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(title.toUpperCase(), style: const TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(item, style: const TextStyle(color: Colors.white)),
            )).toList(),
          ),
        ),
      ],
    );
  }
}

class _StepSocialMedia extends StatefulWidget {
  final VoidCallback nextStep;
  final List<Map<String, String>> socialLinks;
  final ValueChanged<List<Map<String, String>>> onLinksChanged;

  const _StepSocialMedia({
    required this.nextStep,
    required this.socialLinks,
    required this.onLinksChanged,
  });

  @override
  State<_StepSocialMedia> createState() => _StepSocialMediaState();
}

class _StepSocialMediaState extends State<_StepSocialMedia> {
  final TextEditingController _usernameController = TextEditingController();
  
  String _selectedPlatform = 'Instagram';
  final List<String> _platforms = ['Instagram', 'Facebook', 'TikTok', 'LinkedIn', 'YouTube', 'Twitter', 'Other'];

  void _addLink() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;
    
    // Construct URL if just username (optional, or just store username)
    // For now, let's assume input could be full link or username.
    String url = username;
    
    final newLinks = List<Map<String, String>>.from(widget.socialLinks);
    newLinks.add({'platform': _selectedPlatform, 'url': url});
    widget.onLinksChanged(newLinks);
    _usernameController.clear();
  }

  void _removeLink(int index) {
    final newLinks = List<Map<String, String>>.from(widget.socialLinks);
    newLinks.removeAt(index);
    widget.onLinksChanged(newLinks);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Online Influence', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('Share your social media profiles', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 32),
          
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPlatform,
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    items: _platforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setState(() => _selectedPlatform = val!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Username / Link',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addLink,
                icon: const Icon(LucideIcons.plusCircle, color: Color(0xFF6366F1)),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          if (widget.socialLinks.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: widget.socialLinks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return ListTile(
                    dense: true,
                    title: Text(item['platform']!, style: const TextStyle(color: Colors.white70)),
                    subtitle: Text(item['url']!, style: const TextStyle(color: Colors.white30), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.trash2, color: Colors.white24, size: 18),
                      onPressed: () => _removeLink(index),
                    ),
                  );
                }).toList(),
              ),
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
