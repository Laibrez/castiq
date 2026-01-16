import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/dashboard/dashboard_screen.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IdVerificationScreen extends StatefulWidget {
  final String userType;

  const IdVerificationScreen({super.key, required this.userType});

  @override
  State<IdVerificationScreen> createState() => _IdVerificationScreenState();
}

class _IdVerificationScreenState extends State<IdVerificationScreen> {
  bool _frontUploaded = false;
  bool _backUploaded = false;
  bool _selfieUploaded = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user == null) throw 'User not found';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'isVerified': true});

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(userType: widget.userType),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit verification: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ID Verification',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verify your identity.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'To ensure the safety of our community, we need to verify your identity. Please upload a valid government-issued ID.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 32),
              _UploadCard(
                title: 'Front of ID',
                isUploaded: _frontUploaded,
                onTap: () {
                  setState(() => _frontUploaded = !_frontUploaded);
                },
              ),
              const SizedBox(height: 16),
              _UploadCard(
                title: 'Back of ID',
                isUploaded: _backUploaded,
                onTap: () {
                  setState(() => _backUploaded = !_backUploaded);
                },
              ),
              const SizedBox(height: 16),
              _UploadCard(
                title: 'Selfie with ID',
                isUploaded: _selfieUploaded,
                onTap: () {
                  setState(() => _selfieUploaded = !_selfieUploaded);
                },
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_frontUploaded && _backUploaded && _selfieUploaded && !_isLoading)
                      ? _handleSubmit
                      : null,
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit & Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  final String title;
  final bool isUploaded;
  final VoidCallback onTap;

  const _UploadCard({
    required this.title,
    required this.isUploaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isUploaded ? Colors.white : Colors.grey,
            width: isUploaded ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isUploaded ? Colors.white.withOpacity(0.1) : Colors.black,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUploaded ? Colors.white : Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isUploaded ? LucideIcons.check : LucideIcons.camera,
                color: isUploaded ? Colors.black : Colors.white70,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isUploaded ? Colors.white : Colors.white70,
              ),
            ),
            const Spacer(),
            if (isUploaded)
              const Text(
                'Uploaded',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
