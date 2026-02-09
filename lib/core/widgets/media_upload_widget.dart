import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/core/services/media_upload_service.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';

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
      videoFile: video,
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

    final results = await _uploadService.uploadMultipleImages(
      userId: userId,
      imageFiles: images,
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
        content: Text(message, style: GoogleFonts.montserrat(color: AppTheme.white)),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.montserrat(color: AppTheme.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0DCD5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Media',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add photos and videos to your portfolio',
            style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 13),
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
                backgroundColor: AppTheme.cream,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
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
                    color: AppTheme.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _uploadStatus,
                  style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 13),
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
                    ? AppTheme.success.withOpacity(0.1) 
                    : AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _uploadStatus.contains('success') 
                        ? LucideIcons.checkCircle2 
                        : LucideIcons.alertCircle,
                    color: _uploadStatus.contains('success') ? AppTheme.success : AppTheme.error,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _uploadStatus,
                    style: GoogleFonts.montserrat(
                      color: _uploadStatus.contains('success') ? AppTheme.success : AppTheme.error,
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
              ? AppTheme.cream 
              : AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: onTap == null 
                ? Colors.transparent 
                : const Color(0xFFE0DCD5),
          ),
          boxShadow: onTap != null ? [
            BoxShadow(
              color: AppTheme.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: onTap == null ? AppTheme.grey.withOpacity(0.1) : AppTheme.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: onTap == null 
                    ? AppTheme.grey.withOpacity(0.5) 
                    : AppTheme.gold,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: onTap == null 
                    ? AppTheme.grey.withOpacity(0.5) 
                    : AppTheme.black,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                color: AppTheme.grey.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
