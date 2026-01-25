import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/admin/models/model_profile.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminModelDetailScreen extends StatefulWidget {
  final String modelId;

  const AdminModelDetailScreen({super.key, required this.modelId});

  @override
  State<AdminModelDetailScreen> createState() => _AdminModelDetailScreenState();
}

class _AdminModelDetailScreenState extends State<AdminModelDetailScreen> {
  ModelProfile? _model;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isMockData = false;
  bool _isEditing = false;

  // Editable fields
  final TextEditingController _adminNotesController = TextEditingController();
  bool _idVerified = false;
  bool _portfolioApproved = false;

  // Profile editing
  final Map<String, String?> _editedProfile = {};

  // Mock data
  final Map<String, ModelProfile> _mockModelDetails = {
    "mock-model-1": ModelProfile(
      id: "mock-model-1",
      userId: "mock-user-1",
      firstName: "Sophia",
      lastName: "Martinez",
      bio: "Experienced runway and editorial model with a passion for high fashion and sustainable brands. Featured in Vogue Latinoamérica and worked with top designers in Milan and Paris.",
      profilePhotoUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400",
      city: "Los Angeles",
      country: "United States",
      height: "5'10\"",
      bust: "33\"",
      waist: "24\"",
      hips: "35\"",
      shoeSize: "8.5",
      eyeColor: "Brown",
      hairColor: "Black",
      skinTone: "Olive",
      experience: "5 years",
      categories: ["Runway", "Editorial", "Commercial", "Swimwear"],
      portfolioUrls: [
        "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800",
        "https://images.unsplash.com/photo-1509631179647-0177331693ae?w=800",
        "https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=800",
        "https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=800",
      ],
      portfolioVideoUrl: null,
      willingToTravel: true,
      idVerified: false,
      portfolioApproved: false,
      portfolioReviewDate: null,
      stripeOnboardingComplete: false,
      stripeChargesEnabled: false,
      stripePayoutsEnabled: false,
      adminNotes: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    "mock-model-2": ModelProfile(
      id: "mock-model-2",
      userId: "mock-user-2",
      firstName: "Emma",
      lastName: "Chen",
      bio: "Commercial and fitness model specializing in athletic wear and lifestyle campaigns. Certified yoga instructor with a background in dance.",
      profilePhotoUrl: "https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400",
      city: "New York",
      country: "United States",
      height: "5'8\"",
      bust: "34\"",
      waist: "25\"",
      hips: "36\"",
      shoeSize: "7.5",
      eyeColor: "Brown",
      hairColor: "Black",
      skinTone: "Light",
      experience: "3 years",
      categories: ["Commercial", "Fitness", "Lifestyle"],
      portfolioUrls: [
        "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800",
        "https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=800",
      ],
      portfolioVideoUrl: null,
      willingToTravel: true,
      idVerified: true,
      portfolioApproved: false,
      portfolioReviewDate: null,
      stripeOnboardingComplete: true,
      stripeChargesEnabled: true,
      stripePayoutsEnabled: true,
      adminNotes: "Excellent ID verification documents. Portfolio pending review.",
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    "mock-model-3": ModelProfile(
      id: "mock-model-3",
      userId: "mock-user-3",
      firstName: "Isabella",
      lastName: "Romano",
      bio: "High fashion and runway model based in Milan. Walked for major fashion houses including Prada, Versace, and Dolce & Gabbana.",
      profilePhotoUrl: "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400",
      city: "Milan",
      country: "Italy",
      height: "5'11\"",
      bust: "32\"",
      waist: "23\"",
      hips: "34\"",
      shoeSize: "9",
      eyeColor: "Green",
      hairColor: "Brown",
      skinTone: "Fair",
      experience: "7 years",
      categories: ["High Fashion", "Runway", "Editorial"],
      portfolioUrls: [
        "https://images.unsplash.com/photo-1496440543089-3e5f6c4d1a6e?w=800",
        "https://images.unsplash.com/photo-1509631179647-0177331693ae?w=800",
        "https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=800",
      ],
      portfolioVideoUrl: "https://example.com/walk-video.mp4",
      willingToTravel: true,
      idVerified: true,
      portfolioApproved: true,
      portfolioReviewDate: DateTime.now().subtract(const Duration(days: 1)),
      stripeOnboardingComplete: true,
      stripeChargesEnabled: true,
      stripePayoutsEnabled: true,
      adminNotes: "Top tier model. Fully verified and approved.",
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  };

  @override
  void initState() {
    super.initState();
    _fetchModel();
  }

  @override
  void dispose() {
    _adminNotesController.dispose();
    super.dispose();
  }

  Future<void> _fetchModel() async {
    if (widget.modelId.startsWith("mock-")) {
      final mockModel = _mockModelDetails[widget.modelId];
      if (mockModel != null) {
        setState(() {
          _model = mockModel;
          _adminNotesController.text = mockModel.adminNotes ?? "";
          _idVerified = mockModel.idVerified ?? false;
          _portfolioApproved = mockModel.portfolioApproved ?? false;
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
          .collection('model_profiles')
          .doc(widget.modelId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _model = ModelProfile.fromFirestore(data, doc.id);
          _adminNotesController.text = _model!.adminNotes ?? "";
          _idVerified = _model!.idVerified ?? false;
          _portfolioApproved = _model!.portfolioApproved ?? false;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading model: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveVerificationStatus() async {
    if (_model == null) return;

    setState(() => _isSubmitting = true);

    if (_isMockData) {
      setState(() {
        _model = ModelProfile(
          id: _model!.id,
          userId: _model!.userId,
          firstName: _model!.firstName,
          lastName: _model!.lastName,
          bio: _model!.bio,
          profilePhotoUrl: _model!.profilePhotoUrl,
          city: _model!.city,
          country: _model!.country,
          height: _model!.height,
          bust: _model!.bust,
          waist: _model!.waist,
          hips: _model!.hips,
          shoeSize: _model!.shoeSize,
          eyeColor: _model!.eyeColor,
          hairColor: _model!.hairColor,
          skinTone: _model!.skinTone,
          experience: _model!.experience,
          categories: _model!.categories,
          portfolioUrls: _model!.portfolioUrls,
          portfolioVideoUrl: _model!.portfolioVideoUrl,
          willingToTravel: _model!.willingToTravel,
          idVerified: _idVerified,
          portfolioApproved: _portfolioApproved,
          portfolioReviewDate: _portfolioApproved && !(_model!.portfolioApproved ?? false)
              ? DateTime.now()
              : _model!.portfolioReviewDate,
          stripeOnboardingComplete: _model!.stripeOnboardingComplete,
          stripeChargesEnabled: _model!.stripeChargesEnabled,
          stripePayoutsEnabled: _model!.stripePayoutsEnabled,
          adminNotes: _adminNotesController.text,
          createdAt: _model!.createdAt,
          updatedAt: _model!.updatedAt,
        );
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification status updated (Demo - changes are temporary)')),
        );
      }
      return;
    }

    try {
      final updates = <String, dynamic>{
        'id_verified': _idVerified,
        'portfolio_approved': _portfolioApproved,
        'admin_notes': _adminNotesController.text,
      };

      if (_portfolioApproved && !(_model!.portfolioApproved ?? false)) {
        updates['portfolio_review_date'] = Timestamp.fromDate(DateTime.now());
      }

      await FirebaseFirestore.instance
          .collection('model_profiles')
          .doc(widget.modelId)
          .update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification status updated successfully')),
        );
      }

      _fetchModel();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating verification: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _saveProfileEdits() async {
    if (_model == null) return;

    setState(() => _isSubmitting = true);
    try {
      await FirebaseFirestore.instance
          .collection('model_profiles')
          .doc(widget.modelId)
          .update({
        'first_name': _editedProfile['first_name'] ?? _model!.firstName,
        'last_name': _editedProfile['last_name'] ?? _model!.lastName,
        'bio': _editedProfile['bio'] ?? _model!.bio,
        'city': _editedProfile['city'] ?? _model!.city,
        'country': _editedProfile['country'] ?? _model!.country,
        'height': _editedProfile['height'] ?? _model!.height,
        'bust': _editedProfile['bust'] ?? _model!.bust,
        'waist': _editedProfile['waist'] ?? _model!.waist,
        'hips': _editedProfile['hips'] ?? _model!.hips,
        'shoe_size': _editedProfile['shoe_size'] ?? _model!.shoeSize,
        'eye_color': _editedProfile['eye_color'] ?? _model!.eyeColor,
        'hair_color': _editedProfile['hair_color'] ?? _model!.hairColor,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }

      setState(() => _isEditing = false);
      _fetchModel();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_model == null) {
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
              const Text('Model not found', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Models'),
              ),
            ],
          ),
        ),
      );
    }

    final model = _model!;
    final dateFormat = DateFormat('MMMM d, yyyy');

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
            onPressed: _isSubmitting
                ? null
                : (_isEditing ? _saveProfileEdits : () => setState(() => _isEditing = true)),
            icon: Icon(_isEditing ? LucideIcons.save : LucideIcons.edit, size: 18),
            label: Text(_isEditing ? 'Save Changes' : 'Edit Profile'),
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
                CircleAvatar(
                  radius: 32,
                  backgroundImage: model.profilePhotoUrl != null
                      ? NetworkImage(model.profilePhotoUrl!)
                      : null,
                  child: model.profilePhotoUrl == null
                      ? Text(
                          '${model.firstName?[0] ?? ""}${model.lastName?[0] ?? ""}'.toUpperCase(),
                          style: const TextStyle(fontSize: 20),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${model.firstName ?? ""} ${model.lastName ?? ""}'.trim(),
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (model.idVerified == true)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.checkCircle, size: 14, color: Colors.green),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Verified',
                                    style: TextStyle(color: Colors.green, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        model.city != null && model.country != null
                            ? '${model.city}, ${model.country} • Registered on ${dateFormat.format(model.createdAt)}'
                            : 'Location not set • Registered on ${dateFormat.format(model.createdAt)}',
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
                      // Personal Information
                      _buildInfoCard(
                        icon: LucideIcons.user,
                        title: 'Personal Information',
                        content: _isEditing
                            ? Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(
                                            text: _editedProfile['first_name'] ?? model.firstName ?? '',
                                          ),
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            labelText: 'First Name',
                                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                            ),
                                          ),
                                          onChanged: (value) => _editedProfile['first_name'] = value,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(
                                            text: _editedProfile['last_name'] ?? model.lastName ?? '',
                                          ),
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            labelText: 'Last Name',
                                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                            ),
                                          ),
                                          onChanged: (value) => _editedProfile['last_name'] = value,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: TextEditingController(
                                      text: _editedProfile['bio'] ?? model.bio ?? '',
                                    ),
                                    maxLines: 3,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Bio',
                                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                      ),
                                    ),
                                    onChanged: (value) => _editedProfile['bio'] = value,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(
                                            text: _editedProfile['city'] ?? model.city ?? '',
                                          ),
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            labelText: 'City',
                                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                            ),
                                          ),
                                          onChanged: (value) => _editedProfile['city'] = value,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(
                                            text: _editedProfile['country'] ?? model.country ?? '',
                                          ),
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            labelText: 'Country',
                                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                            ),
                                          ),
                                          onChanged: (value) => _editedProfile['country'] = value,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: _buildInfoRow('First Name', model.firstName ?? 'N/A')),
                                      Expanded(child: _buildInfoRow('Last Name', model.lastName ?? 'N/A')),
                                    ],
                                  ),
                                  if (model.bio != null) _buildInfoRow('Bio', model.bio!),
                                  if (model.experience != null)
                                    _buildInfoRow('Experience', model.experience!.toUpperCase()),
                                  if (model.categories != null && model.categories!.isNotEmpty) ...[
                                    Text(
                                      'Categories',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: model.categories!.map((cat) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            cat,
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Measurements
                      _buildInfoCard(
                        icon: LucideIcons.ruler,
                        title: 'Measurements',
                        content: _isEditing
                            ? Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(
                                            text: _editedProfile['height'] ?? model.height ?? '',
                                          ),
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            labelText: 'Height',
                                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                            ),
                                          ),
                                          onChanged: (value) => _editedProfile['height'] = value,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(
                                            text: _editedProfile['bust'] ?? model.bust ?? '',
                                          ),
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            labelText: 'Bust',
                                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                            ),
                                          ),
                                          onChanged: (value) => _editedProfile['bust'] = value,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(
                                            text: _editedProfile['waist'] ?? model.waist ?? '',
                                          ),
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            labelText: 'Waist',
                                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                            ),
                                          ),
                                          onChanged: (value) => _editedProfile['waist'] = value,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(
                                            text: _editedProfile['hips'] ?? model.hips ?? '',
                                          ),
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            labelText: 'Hips',
                                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                            ),
                                          ),
                                          onChanged: (value) => _editedProfile['hips'] = value,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(
                                            text: _editedProfile['shoe_size'] ?? model.shoeSize ?? '',
                                          ),
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            labelText: 'Shoe Size',
                                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                            ),
                                          ),
                                          onChanged: (value) => _editedProfile['shoe_size'] = value,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(
                                            text: _editedProfile['eye_color'] ?? model.eyeColor ?? '',
                                          ),
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            labelText: 'Eye Color',
                                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                            ),
                                          ),
                                          onChanged: (value) => _editedProfile['eye_color'] = value,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(
                                            text: _editedProfile['hair_color'] ?? model.hairColor ?? '',
                                          ),
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            labelText: 'Hair Color',
                                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                            ),
                                          ),
                                          onChanged: (value) => _editedProfile['hair_color'] = value,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: _buildInfoRow('Height', model.height ?? 'N/A')),
                                      Expanded(child: _buildInfoRow('Bust', model.bust ?? 'N/A')),
                                      Expanded(child: _buildInfoRow('Waist', model.waist ?? 'N/A')),
                                      Expanded(child: _buildInfoRow('Hips', model.hips ?? 'N/A')),
                                      Expanded(child: _buildInfoRow('Shoe', model.shoeSize ?? 'N/A')),
                                    ],
                                  ),
                                  Divider(color: Colors.white.withOpacity(0.1)),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(child: _buildInfoRow('Eye Color', (model.eyeColor ?? 'N/A').toUpperCase())),
                                      Expanded(child: _buildInfoRow('Hair Color', (model.hairColor ?? 'N/A').toUpperCase())),
                                      Expanded(child: _buildInfoRow('Skin Tone', (model.skinTone ?? 'N/A').toUpperCase())),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Portfolio
                      _buildInfoCard(
                        icon: LucideIcons.camera,
                        title: 'Portfolio',
                        content: model.portfolioUrls != null && model.portfolioUrls!.isNotEmpty
                            ? GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1,
                                ),
                                itemCount: model.portfolioUrls!.length,
                                itemBuilder: (context, index) {
                                  return InkWell(
                                    onTap: () => _launchUrl(model.portfolioUrls![index]),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: NetworkImage(model.portfolioUrls![index]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: Colors.black.withOpacity(0.3),
                                        ),
                                        child: const Center(
                                          child: Icon(LucideIcons.externalLink, color: Colors.white, size: 24),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text(
                                    'No portfolio images uploaded',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ),
                      ),
                      if (model.portfolioVideoUrl != null) ...[
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () => _launchUrl(model.portfolioVideoUrl!),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.externalLink, color: Color(0xFF6366F1), size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'View Portfolio Video',
                                style: TextStyle(
                                  color: Color(0xFF6366F1),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // Right Column - Sidebar
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // Verification Status
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
                              'Verification',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manage identity and portfolio verification',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ID Verified',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Text(
                                        'Identity has been verified',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _idVerified,
                                  onChanged: (value) => setState(() => _idVerified = value),
                                ),
                              ],
                            ),
                            Divider(color: Colors.white.withOpacity(0.1)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Portfolio Approved',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Text(
                                        'Portfolio meets quality standards',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _portfolioApproved,
                                  onChanged: (value) => setState(() => _portfolioApproved = value),
                                ),
                              ],
                            ),
                            if (model.portfolioReviewDate != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Last reviewed: ${dateFormat.format(model.portfolioReviewDate!)}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isSubmitting ? null : _saveVerificationStatus,
                                icon: const Icon(LucideIcons.save, size: 18),
                                label: const Text('Save Verification Status'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Payment Status
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
                              'Payment Status',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Stripe Onboarding', style: TextStyle(color: Colors.white, fontSize: 14)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (model.stripeOnboardingComplete ?? false)
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (model.stripeOnboardingComplete ?? false) ? 'Complete' : 'Incomplete',
                                    style: TextStyle(
                                      color: (model.stripeOnboardingComplete ?? false) ? Colors.green : Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Charges Enabled', style: TextStyle(color: Colors.white, fontSize: 14)),
                                Icon(
                                  (model.stripeChargesEnabled ?? false) ? LucideIcons.checkCircle : LucideIcons.xCircle,
                                  color: (model.stripeChargesEnabled ?? false) ? Colors.green : Colors.grey,
                                  size: 18,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Payouts Enabled', style: TextStyle(color: Colors.white, fontSize: 14)),
                                Icon(
                                  (model.stripePayoutsEnabled ?? false) ? LucideIcons.checkCircle : LucideIcons.xCircle,
                                  color: (model.stripePayoutsEnabled ?? false) ? Colors.green : Colors.grey,
                                  size: 18,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Admin Notes
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
                              'Admin Notes',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Internal notes about this model',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _adminNotesController,
                              maxLines: 4,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Add notes...',
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
