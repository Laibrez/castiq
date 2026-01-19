import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/core/services/media_upload_service.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';

class MediaUploadWidget extends StatefulWidget {
  final VoidCallback? onUploadComplete;

  const MediaUploadWidget({super.key, this.onUploadComplete});

  @override
  State<MediaUploadWidget> createState() => _MediaUploadWidgetState();
}

class _MediaUploadWidgetState extends State<MediaUploadWidget> {
  final MediaUploadService _uploadService = MediaUploadService();
  final AuthService _authService = AuthService();

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  int _completedImages = 0;
  int _totalImages = 0;

  Future<void> _uploadVideo() async {
    final video = await _uploadService.pickVideo();
    if (video == null) return;

    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Uploading video...';
    });

    final result = await _uploadService.uploadVideo(
      userId: userId,
      videoFile: File(video.path),
      onProgress: (progress) {
        setState(() {
          _uploadProgress = progress;
          _uploadStatus = 'Uploading video... ${(progress * 100).toInt()}%';
        });
      },
    );

    setState(() {
      _isUploading = false;
      _uploadStatus = result != null ? 'Video uploaded successfully!' : 'Failed to upload video';
    });

    if (result != null) {
      _showSuccessSnackbar('Video uploaded successfully!');
      widget.onUploadComplete?.call();
    } else {
      _showErrorSnackbar('Failed to upload video');
    }

    // Clear status after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _uploadStatus = '');
    });
  }

  Future<void> _uploadImages() async {
    final images = await _uploadService.pickMultipleImages();
    if (images.isEmpty) return;

    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _isUploading = true;
      _completedImages = 0;
      _totalImages = images.length;
      _uploadStatus = 'Uploading images...';
    });

    final files = images.map((xfile) => File(xfile.path)).toList();

    final results = await _uploadService.uploadMultipleImages(
      userId: userId,
      imageFiles: files,
      onProgress: (completed, total) {
        setState(() {
          _completedImages = completed;
          _totalImages = total;
          _uploadProgress = completed / total;
          _uploadStatus = 'Uploading image $completed of $total...';
        });
      },
    );

    setState(() {
      _isUploading = false;
      _uploadStatus = results.isNotEmpty 
          ? '${results.length} images uploaded!' 
          : 'Failed to upload images';
    });

    if (results.isNotEmpty) {
      _showSuccessSnackbar('${results.length} images uploaded successfully!');
      widget.onUploadComplete?.call();
    } else {
      _showErrorSnackbar('Failed to upload images');
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _uploadStatus = '');
    });
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Media',
            style: GoogleFonts.tinos(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add photos and videos to your portfolio',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Upload Buttons
          Row(
            children: [
              Expanded(
                child: _UploadButton(
                  icon: LucideIcons.image,
                  label: 'Upload Photos',
                  subtitle: 'Multiple images',
                  onTap: _isUploading ? null : _uploadImages,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _UploadButton(
                  icon: LucideIcons.video,
                  label: 'Upload Video',
                  subtitle: 'Max 2 minutes',
                  onTap: _isUploading ? null : _uploadVideo,
                ),
              ),
            ],
          ),

          // Progress Indicator
          if (_isUploading) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF818CF8),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _uploadStatus,
                  style: const TextStyle(color: Color(0xFF818CF8), fontSize: 13),
                ),
              ],
            ),
          ],

          // Status Message
          if (!_isUploading && _uploadStatus.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _uploadStatus.contains('success') 
                    ? Colors.green.withOpacity(0.1) 
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _uploadStatus.contains('success') 
                        ? LucideIcons.checkCircle2 
                        : LucideIcons.alertCircle,
                    color: _uploadStatus.contains('success') ? Colors.green : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _uploadStatus,
                    style: TextStyle(
                      color: _uploadStatus.contains('success') ? Colors.green : Colors.red,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  const _UploadButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: onTap == null 
              ? Colors.white.withOpacity(0.02) 
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: onTap == null 
                ? Colors.white.withOpacity(0.02) 
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: onTap == null 
                    ? Colors.white.withOpacity(0.3) 
                    : const Color(0xFF818CF8),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: onTap == null 
                    ? Colors.white.withOpacity(0.3) 
                    : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
